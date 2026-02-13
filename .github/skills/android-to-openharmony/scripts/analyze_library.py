#!/usr/bin/env python3
"""
Android Library Portability Analyzer

Analyzes an Android library's source code to assess portability to OpenHarmony.
Scans Java/Kotlin files for Android API usage, categorizes dependencies,
and generates a migration complexity report.

Usage:
    python analyze_library.py <library-source-path> [--output report.json]

Output: JSON report with:
    - summary: overall stats and complexity score
    - android_apis: detected Android API usage with categories
    - dependencies: third-party dependency list from build.gradle
    - native_code: JNI/NDK usage if detected
    - recommendations: migration suggestions
"""

import sys
import os
import re
import json
import argparse
from pathlib import Path
from collections import defaultdict

# Android API categories and their OpenHarmony mapping difficulty
API_CATEGORIES = {
    "ui_view": {
        "patterns": [
            r"import\s+android\.widget\.",
            r"import\s+android\.view\.",
            r"import\s+androidx\.appcompat\.",
            r"import\s+androidx\.recyclerview\.",
            r"import\s+androidx\.viewpager",
            r"import\s+androidx\.cardview\.",
            r"import\s+androidx\.constraintlayout\.",
            r"import\s+com\.google\.android\.material\.",
        ],
        "difficulty": "high",
        "oh_alternative": "ArkUI declarative components",
    },
    "ui_compose": {
        "patterns": [
            r"import\s+androidx\.compose\.",
            r"@Composable",
        ],
        "difficulty": "high",
        "oh_alternative": "ArkUI declarative UI (@Component + build())",
    },
    "network": {
        "patterns": [
            r"import\s+java\.net\.(HttpURLConnection|URL|Socket)",
            r"import\s+android\.net\.",
            r"import\s+okhttp3?\.",
            r"import\s+retrofit2?\.",
            r"import\s+com\.android\.volley\.",
        ],
        "difficulty": "medium",
        "oh_alternative": "@ohos.net.http / @ohos.net.socket",
    },
    "storage": {
        "patterns": [
            r"import\s+android\.content\.SharedPreferences",
            r"import\s+android\.database\.sqlite\.",
            r"import\s+androidx\.room\.",
            r"import\s+androidx\.datastore\.",
            r"import\s+android\.os\.Environment",
        ],
        "difficulty": "medium",
        "oh_alternative": "@ohos.data.preferences / @ohos.data.relationalStore",
    },
    "multimedia": {
        "patterns": [
            r"import\s+android\.media\.",
            r"import\s+android\.graphics\.(Bitmap|Canvas|Paint|ImageDecoder)",
            r"import\s+androidx\.camera\.",
            r"import\s+android\.hardware\.camera2?\.",
        ],
        "difficulty": "medium",
        "oh_alternative": "@ohos.multimedia.image / @ohos.multimedia.media",
    },
    "lifecycle": {
        "patterns": [
            r"import\s+android\.app\.Activity",
            r"import\s+android\.app\.Fragment",
            r"import\s+androidx\.fragment\.",
            r"import\s+androidx\.lifecycle\.",
            r"import\s+android\.app\.Service",
            r"import\s+android\.content\.BroadcastReceiver",
            r"import\s+android\.content\.ContentProvider",
        ],
        "difficulty": "high",
        "oh_alternative": "Ability framework (UIAbility / ExtensionAbility)",
    },
    "threading": {
        "patterns": [
            r"import\s+android\.os\.(Handler|Looper|AsyncTask)",
            r"import\s+kotlinx\.coroutines\.",
            r"import\s+io\.reactivex\.",
            r"import\s+rx\.",
        ],
        "difficulty": "medium",
        "oh_alternative": "TaskPool / Worker (@ohos.taskpool / @ohos.worker)",
    },
    "permission": {
        "patterns": [
            r"import\s+android\.Manifest",
            r"import\s+android\.content\.pm\.PackageManager",
            r"import\s+androidx\.core\.app\.ActivityCompat",
            r"requestPermissions",
        ],
        "difficulty": "medium",
        "oh_alternative": "@ohos.abilityAccessCtrl",
    },
    "ipc_intent": {
        "patterns": [
            r"import\s+android\.content\.Intent",
            r"import\s+android\.content\.Context",
            r"import\s+android\.os\.Bundle",
        ],
        "difficulty": "high",
        "oh_alternative": "Want mechanism (@ohos.app.ability.Want)",
    },
    "notification": {
        "patterns": [
            r"import\s+android\.app\.Notification",
            r"import\s+androidx\.core\.app\.NotificationCompat",
        ],
        "difficulty": "medium",
        "oh_alternative": "@ohos.notificationManager",
    },
    "jni_ndk": {
        "patterns": [
            r"System\.loadLibrary",
            r"native\s+\w+\s+\w+\(",
            r"extern\s+\"C\"",
            r"#include\s+<jni\.h>",
            r"JNIEnv\s*\*",
            r"JNIEXPORT",
        ],
        "difficulty": "high",
        "oh_alternative": "NAPI (Node-API for native modules)",
    },
    "pure_java": {
        "patterns": [
            r"import\s+java\.(util|io|lang|math|text|time|security)\.",
            r"import\s+javax\.(crypto|net\.ssl)\.",
        ],
        "difficulty": "low",
        "oh_alternative": "Direct reuse or ArkTS equivalent",
    },
    "json_serialization": {
        "patterns": [
            r"import\s+com\.google\.gson\.",
            r"import\s+org\.json\.",
            r"import\s+com\.fasterxml\.jackson\.",
            r"import\s+kotlinx\.serialization\.",
            r"import\s+com\.squareup\.moshi\.",
        ],
        "difficulty": "low",
        "oh_alternative": "JSON.parse/stringify or @ohos.util.json",
    },
    "logging": {
        "patterns": [
            r"import\s+android\.util\.Log",
            r"Log\.(d|i|w|e|v)\(",
        ],
        "difficulty": "low",
        "oh_alternative": "hilog (@ohos.hilog)",
    },
}


def scan_file(filepath: Path) -> dict:
    """Scan a single source file for Android API usage."""
    try:
        content = filepath.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return {}

    findings = defaultdict(list)
    lines = content.split("\n")

    for line_num, line in enumerate(lines, 1):
        for category, info in API_CATEGORIES.items():
            for pattern in info["patterns"]:
                if re.search(pattern, line):
                    findings[category].append({
                        "file": str(filepath),
                        "line": line_num,
                        "content": line.strip(),
                    })
    return dict(findings)


def scan_build_gradle(filepath: Path) -> list:
    """Extract dependencies from build.gradle."""
    deps = []
    try:
        content = filepath.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return deps

    # Match implementation/api/compile dependency declarations
    patterns = [
        r"(?:implementation|api|compile|compileOnly)\s*[\(]?\s*['\"]([^'\"]+)['\"]",
        r"(?:implementation|api|compile|compileOnly)\s*[\(]?\s*project\s*\(['\"]([^'\"]+)['\"]\)",
    ]
    for pat in patterns:
        for match in re.finditer(pat, content):
            deps.append(match.group(1))
    return deps


def scan_cmake(filepath: Path) -> dict:
    """Scan CMakeLists.txt for native library information."""
    info = {"libraries": [], "source_files": [], "link_libraries": []}
    try:
        content = filepath.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return info

    for match in re.finditer(r"add_library\s*\(\s*(\w+)", content):
        info["libraries"].append(match.group(1))
    for match in re.finditer(r"target_link_libraries\s*\([^)]*\)", content):
        info["link_libraries"].append(match.group(0))
    return info


def calculate_complexity(api_findings: dict, dep_count: int, has_native: bool) -> dict:
    """Calculate overall migration complexity score."""
    total_hits = sum(len(v) for v in api_findings.values())
    high_hits = sum(len(api_findings.get(cat, []))
                    for cat, info in API_CATEGORIES.items()
                    if info["difficulty"] == "high")
    medium_hits = sum(len(api_findings.get(cat, []))
                      for cat, info in API_CATEGORIES.items()
                      if info["difficulty"] == "medium")

    # Score: 0-100, higher = more complex
    score = min(100, high_hits * 5 + medium_hits * 2 + dep_count * 3)
    if has_native:
        score = min(100, score + 20)

    if score < 20:
        level = "LOW"
    elif score < 50:
        level = "MEDIUM"
    elif score < 80:
        level = "HIGH"
    else:
        level = "VERY_HIGH"

    return {
        "score": score,
        "level": level,
        "total_api_hits": total_hits,
        "high_difficulty_hits": high_hits,
        "medium_difficulty_hits": medium_hits,
        "has_native_code": has_native,
    }


def generate_recommendations(api_findings: dict, has_native: bool) -> list:
    """Generate migration recommendations based on findings."""
    recs = []
    for category, hits in api_findings.items():
        if not hits:
            continue
        info = API_CATEGORIES.get(category, {})
        recs.append({
            "category": category,
            "hit_count": len(hits),
            "difficulty": info.get("difficulty", "unknown"),
            "oh_alternative": info.get("oh_alternative", "N/A"),
            "action": f"Replace {len(hits)} {category} API calls with {info.get('oh_alternative', 'OpenHarmony equivalent')}",
        })

    # Sort by difficulty (high first)
    order = {"high": 0, "medium": 1, "low": 2, "unknown": 3}
    recs.sort(key=lambda x: order.get(x["difficulty"], 3))
    return recs


def analyze_library(source_path: str) -> dict:
    """Main analysis function."""
    root = Path(source_path).resolve()
    if not root.exists():
        print(f"Error: Path does not exist: {root}")
        sys.exit(1)

    print(f"Analyzing: {root}")

    # Collect source files
    java_files = list(root.rglob("*.java"))
    kotlin_files = list(root.rglob("*.kt"))
    c_files = list(root.rglob("*.c")) + list(root.rglob("*.cpp")) + list(root.rglob("*.h"))
    gradle_files = list(root.rglob("build.gradle")) + list(root.rglob("build.gradle.kts"))
    cmake_files = list(root.rglob("CMakeLists.txt"))

    print(f"  Found {len(java_files)} Java, {len(kotlin_files)} Kotlin, {len(c_files)} C/C++ files")

    # Scan all source files
    all_findings = defaultdict(list)
    for f in java_files + kotlin_files:
        findings = scan_file(f)
        for cat, hits in findings.items():
            all_findings[cat].extend(hits)

    # Scan native code
    for f in c_files:
        findings = scan_file(f)
        for cat, hits in findings.items():
            all_findings[cat].extend(hits)

    # Scan build files
    all_deps = []
    for f in gradle_files:
        all_deps.extend(scan_build_gradle(f))

    # Scan CMake
    native_info = {}
    for f in cmake_files:
        native_info = scan_cmake(f)

    has_native = bool(c_files) or bool(all_findings.get("jni_ndk"))

    # Calculate complexity
    complexity = calculate_complexity(all_findings, len(all_deps), has_native)

    # Generate recommendations
    recommendations = generate_recommendations(all_findings, has_native)

    # Build report
    report = {
        "library_path": str(root),
        "summary": {
            "java_files": len(java_files),
            "kotlin_files": len(kotlin_files),
            "native_files": len(c_files),
            "gradle_files": len(gradle_files),
            "complexity": complexity,
        },
        "android_apis": {
            cat: {
                "count": len(hits),
                "difficulty": API_CATEGORIES.get(cat, {}).get("difficulty", "unknown"),
                "oh_alternative": API_CATEGORIES.get(cat, {}).get("oh_alternative", "N/A"),
                "samples": hits[:5],  # first 5 samples
            }
            for cat, hits in all_findings.items()
            if hits
        },
        "dependencies": sorted(set(all_deps)),
        "native_code": native_info if has_native else None,
        "recommendations": recommendations,
    }

    return report


def main():
    parser = argparse.ArgumentParser(description="Android Library Portability Analyzer")
    parser.add_argument("source_path", help="Path to Android library source code")
    parser.add_argument("--output", "-o", help="Output JSON report file (default: stdout)")
    args = parser.parse_args()

    report = analyze_library(args.source_path)

    output = json.dumps(report, indent=2, ensure_ascii=False)
    if args.output:
        Path(args.output).write_text(output, encoding="utf-8")
        print(f"\nReport saved to: {args.output}")
    else:
        print("\n" + output)

    # Print summary
    c = report["summary"]["complexity"]
    print(f"\n{'='*50}")
    print(f"Migration Complexity: {c['level']} (score: {c['score']}/100)")
    print(f"Total API hits: {c['total_api_hits']}")
    print(f"High difficulty: {c['high_difficulty_hits']}")
    print(f"Native code: {'Yes' if c['has_native_code'] else 'No'}")
    print(f"Dependencies: {len(report['dependencies'])}")
    print(f"{'='*50}")


if __name__ == "__main__":
    main()
