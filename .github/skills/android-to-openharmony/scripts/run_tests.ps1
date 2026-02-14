<#
.SYNOPSIS
    运行 HarmonyOS 测试用例

.DESCRIPTION
    通过 hdc 在手机上远程执行测试用例：
    hdc shell "aa test -b com.example.template -m entry_test -s unittest OpenHarmonyTestRunner"

.PARAMETER BundleName
    应用包名。默认为 com.example.template。

.PARAMETER ModuleName
    测试模块名。默认为 entry_test。

.PARAMETER ShowLog
    执行测试后是否自动获取 hilog 日志。

.EXAMPLE
    .\run_tests.ps1
    .\run_tests.ps1 -ShowLog
    .\run_tests.ps1 -BundleName "com.example.myapp"
#>

param(
    [string]$BundleName = "com.example.template",
    [string]$ModuleName = "entry_test",
    [switch]$ShowLog
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HarmonyOS 测试用例执行" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: 检查 hdc
Write-Host "[Step 1] 检查 hdc 工具..." -NoNewline
$hdc = Get-Command hdc -ErrorAction SilentlyContinue
if (-not $hdc) {
    Write-Host " ❌ hdc 未找到，请配置环境变量" -ForegroundColor Red
    exit 1
}
Write-Host " ✅" -ForegroundColor Green

# Step 2: 检查设备连接
Write-Host "[Step 2] 检查设备连接..." -NoNewline
$targets = & hdc list targets 2>&1
$targetList = ($targets | Where-Object { $_ -and $_ -ne "[Empty]" })
if (-not $targetList) {
    Write-Host " ❌ 未检测到设备" -ForegroundColor Red
    Write-Host "         请连接手机并确保应用已安装" -ForegroundColor Yellow
    exit 1
}
Write-Host " ✅ 设备: $($targetList[0])" -ForegroundColor Green

# Step 3: 执行测试
Write-Host "[Step 3] 执行测试用例..." -ForegroundColor Cyan
Write-Host "  包名: $BundleName" -ForegroundColor Gray
Write-Host "  模块: $ModuleName" -ForegroundColor Gray
Write-Host ""

$testCommand = "aa test -b $BundleName -m $ModuleName -s unittest OpenHarmonyTestRunner"
Write-Host "  命令: hdc shell `"$testCommand`"" -ForegroundColor Gray
Write-Host ""
Write-Host "--- 测试输出 ---" -ForegroundColor Yellow

$testOutput = & hdc shell $testCommand 2>&1
$testStr = $testOutput -join "`n"

Write-Host $testStr
Write-Host "--- 测试输出结束 ---" -ForegroundColor Yellow
Write-Host ""

# Step 4: 分析测试结果
Write-Host "[Step 4] 分析测试结果..."

$passCount = 0
$failCount = 0
$errorCount = 0

# 解析测试结果
if ($testStr -match "Tests run:\s*(\d+)") {
    $totalTests = [int]$Matches[1]
}
if ($testStr -match "Passed:\s*(\d+)") {
    $passCount = [int]$Matches[1]
}
if ($testStr -match "Failed:\s*(\d+)") {
    $failCount = [int]$Matches[1]
}
if ($testStr -match "Error:\s*(\d+)") {
    $errorCount = [int]$Matches[1]
}

# 也尝试匹配其他格式（使用词边界避免误匹配 "Failed: 0"）
if ($testStr -match "\bPASS\b") { $hasPass = $true }
if ($testStr -match "\bFAIL\b" -and $testStr -notmatch "Failed:\s*0") { $hasFail = $true }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($failCount -gt 0 -or $errorCount -gt 0 -or $hasFail) {
    Write-Host "  ❌ 测试未通过" -ForegroundColor Red
    if ($passCount -or $failCount -or $errorCount) {
        Write-Host "  通过: $passCount | 失败: $failCount | 错误: $errorCount" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  请根据错误信息修复库代码后重新测试" -ForegroundColor Yellow
    Write-Host "  查看详细日志: hdc hilog | Select-String 'test|FAIL|Error'" -ForegroundColor Gray

    # 获取 hilog 中的错误详情
    if ($ShowLog) {
        Write-Host ""
        Write-Host "--- hilog 错误日志 ---" -ForegroundColor Yellow
        & hdc shell "hilog -t test 2>&1" | Select-Object -Last 50
        Write-Host "--- hilog 日志结束 ---" -ForegroundColor Yellow
    }

    exit 1
} elseif ($passCount -gt 0 -or $hasPass) {
    Write-Host "  ✅ 测试全部通过" -ForegroundColor Green
    if ($passCount) {
        Write-Host "  通过: $passCount 个测试用例" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️  无法确定测试结果，请检查输出" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Cyan
