#Requires -Version 5.1
<#
.SYNOPSIS
    Check HarmonyOS development environment

.DESCRIPTION
    Verify required tools before migration:
    - hvigorw: Build tool (like Gradle)
    - hdc: Device connection tool (like adb)
    - node: Node.js runtime

.EXAMPLE
    .\check_env.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$script:ErrorCount = 0

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Start
Write-Host ""
Write-ColorText "========================================" "Cyan"
Write-ColorText "  HarmonyOS Environment Check" "Cyan"
Write-ColorText "========================================" "Cyan"
Write-Host ""

# 1. Check hvigorw
Write-ColorText "[1/4] Checking hvigorw (build tool)..." "White" -NoNewline
if (Test-CommandExists "hvigorw") {
    $hvigorw = Get-Command hvigorw
    Write-ColorText " OK" "Green"
    Write-ColorText "      Path: $($hvigorw.Source)" "Gray"
} else {
    Write-ColorText " NOT FOUND" "Red"
    Write-ColorText "      Add DevEco Studio command-line-tools to PATH" "Yellow"
    Write-ColorText "      Example: DevEco-Studio\tools\hvigor\bin" "Yellow"
    $script:ErrorCount++
}

# 2. Check hdc
Write-ColorText "[2/4] Checking hdc (device tool)..." "White" -NoNewline
if (Test-CommandExists "hdc") {
    $hdc = Get-Command hdc
    Write-ColorText " OK" "Green"
    Write-ColorText "      Path: $($hdc.Source)" "Gray"
    
    # Check connected devices
    Write-ColorText "      Checking devices..." "White" -NoNewline
    try {
        $targets = & hdc list targets 2>&1 | Where-Object { 
            $_ -and $_ -ne "[Empty]" -and $_ -notmatch "^\s*$" 
        }
        if ($targets -and $targets.Count -gt 0) {
            Write-ColorText " Connected" "Green"
            foreach ($t in $targets) {
                Write-ColorText "        - $t" "Gray"
            }
        } else {
            Write-ColorText " No device" "Yellow"
            Write-ColorText "        Connect device for HAP installation" "Yellow"
        }
    } catch {
        Write-ColorText " Cannot detect" "Yellow"
    }
} else {
    Write-ColorText " NOT FOUND" "Red"
    Write-ColorText "      Add HarmonyOS SDK toolchains to PATH" "Yellow"
    Write-ColorText "      Example: HarmonyOS-SDK\openharmony\toolchains" "Yellow"
    $script:ErrorCount++
}

# 3. Check node
Write-ColorText "[3/4] Checking node (Node.js)..." "White" -NoNewline
if (Test-CommandExists "node") {
    try {
        $nodeVersion = & node --version 2>&1
        Write-ColorText " OK ($nodeVersion)" "Green"
    } catch {
        Write-ColorText " ERROR" "Red"
        $script:ErrorCount++
    }
} else {
    Write-ColorText " NOT FOUND" "Red"
    Write-ColorText "      hvigorw requires Node.js 16+" "Yellow"
    $script:ErrorCount++
}

# 4. Check python
Write-ColorText "[4/4] Checking python (analysis scripts)..." "White" -NoNewline
$pythonCmd = $null
if (Test-CommandExists "python") {
    $pythonCmd = "python"
} elseif (Test-CommandExists "python3") {
    $pythonCmd = "python3"
}

if ($pythonCmd) {
    try {
        $pyVersion = & $pythonCmd --version 2>&1
        Write-ColorText " OK ($pyVersion)" "Green"
    } catch {
        Write-ColorText " ERROR" "Yellow"
    }
} else {
    Write-ColorText " NOT FOUND (optional)" "Yellow"
    Write-ColorText "      analyze_library.py requires Python 3.6+" "Yellow"
}

# Summary
Write-Host ""
Write-ColorText "========================================" "Cyan"
if ($script:ErrorCount -eq 0) {
    Write-ColorText "  ENVIRONMENT CHECK PASSED" "Green"
    Write-ColorText "  Ready to start migration!" "Green"
} else {
    Write-ColorText "  FOUND $script:ErrorCount ISSUE(S)" "Red"
    Write-ColorText "  Please fix the issues above" "Red"
}
Write-ColorText "========================================" "Cyan"
Write-Host ""

exit $script:ErrorCount
