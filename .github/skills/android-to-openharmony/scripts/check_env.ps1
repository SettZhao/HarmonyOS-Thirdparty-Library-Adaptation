<#
.SYNOPSIS
    检查 HarmonyOS 开发环境变量

.DESCRIPTION
    在执行移植工作流之前，检查必要的工具是否已配置：
    - hvigorw: 构建工具（类似 Gradle）
    - hdc: 设备连接工具（类似 adb）
    - node: Node.js 运行时

.EXAMPLE
    .\check_env.ps1
#>

$ErrorCount = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HarmonyOS 开发环境检查" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 hvigorw
Write-Host "[1/4] 检查 hvigorw (构建工具)..." -NoNewline
$hvigorw = Get-Command hvigorw -ErrorAction SilentlyContinue
if ($hvigorw) {
    Write-Host " ✅ 已配置" -ForegroundColor Green
    Write-Host "      路径: $($hvigorw.Source)" -ForegroundColor Gray
} else {
    Write-Host " ❌ 未找到" -ForegroundColor Red
    Write-Host "      请确保 DevEco Studio 的 command-line-tools 已添加到 PATH" -ForegroundColor Yellow
    Write-Host "      通常路径: <DevEco-Studio>\tools\hvigor\bin" -ForegroundColor Yellow
    $ErrorCount++
}

# 检查 hdc
Write-Host "[2/4] 检查 hdc (设备连接工具)..." -NoNewline
$hdc = Get-Command hdc -ErrorAction SilentlyContinue
if ($hdc) {
    Write-Host " ✅ 已配置" -ForegroundColor Green
    Write-Host "      路径: $($hdc.Source)" -ForegroundColor Gray

    # 检查设备连接
    Write-Host "      检查设备连接..." -NoNewline
    try {
        $targets = & hdc list targets 2>&1
        $targetList = ($targets | Where-Object { $_ -and $_ -ne "[Empty]" })
        if ($targetList) {
            Write-Host " ✅ 已连接设备" -ForegroundColor Green
            foreach ($t in $targetList) {
                Write-Host "        - $t" -ForegroundColor Gray
            }
        } else {
            Write-Host " ⚠️  未检测到设备" -ForegroundColor Yellow
            Write-Host "        安装 HAP 时需要连接设备或模拟器" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " ⚠️  无法检测设备" -ForegroundColor Yellow
    }
} else {
    Write-Host " ❌ 未找到" -ForegroundColor Red
    Write-Host "      请确保 HarmonyOS SDK 的 toolchains 已添加到 PATH" -ForegroundColor Yellow
    Write-Host "      通常路径: <HarmonyOS-SDK>\openharmony\toolchains" -ForegroundColor Yellow
    $ErrorCount++
}

# 检查 node
Write-Host "[3/4] 检查 node (Node.js)..." -NoNewline
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $nodeVersion = & node --version 2>&1
    Write-Host " ✅ 已配置 ($nodeVersion)" -ForegroundColor Green
} else {
    Write-Host " ❌ 未找到" -ForegroundColor Red
    Write-Host "      hvigorw 依赖 Node.js，请安装 Node.js 16+" -ForegroundColor Yellow
    $ErrorCount++
}

# 检查 python (用于分析脚本)
Write-Host "[4/4] 检查 python (分析脚本)..." -NoNewline
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command python3 -ErrorAction SilentlyContinue
}
if ($python) {
    $pyVersion = & $python.Source --version 2>&1
    Write-Host " ✅ 已配置 ($pyVersion)" -ForegroundColor Green
} else {
    Write-Host " ⚠️  未找到 (可选)" -ForegroundColor Yellow
    Write-Host "      analyze_library.py 分析脚本需要 Python 3.6+" -ForegroundColor Yellow
}

# 结果汇总
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($ErrorCount -eq 0) {
    Write-Host "  ✅ 环境检查通过，可以开始移植工作" -ForegroundColor Green
} else {
    Write-Host "  ❌ 发现 $ErrorCount 个问题，请先修复" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

exit $ErrorCount
