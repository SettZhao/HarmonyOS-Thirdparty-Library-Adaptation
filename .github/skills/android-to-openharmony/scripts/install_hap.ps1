<#
.SYNOPSIS
    安装 HAP 应用到 HarmonyOS 设备

.DESCRIPTION
    编译生成 HAP 包并安装到连接的手机上。
    HAP 文件路径: entry/build/default/outputs/default/entry-default-signed.hap

.PARAMETER ProjectPath
    项目根目录路径。默认为当前目录。

.PARAMETER SkipBuild
    跳过编译步骤，直接安装已有的 HAP。

.PARAMETER Uninstall
    安装前先卸载旧版本。

.PARAMETER BundleName
    应用包名。默认为 com.example.template。

.EXAMPLE
    .\install_hap.ps1
    .\install_hap.ps1 -ProjectPath "C:\Projects\MyLib"
    .\install_hap.ps1 -SkipBuild
    .\install_hap.ps1 -Uninstall
#>

param(
    [string]$ProjectPath = ".",
    [switch]$SkipBuild,
    [switch]$Uninstall,
    [string]$BundleName = "com.example.template"
)

$ErrorActionPreference = "Stop"

# 切换到项目目录
Push-Location $ProjectPath

try {
    $hapPath = "entry\build\default\outputs\default\entry-default-signed.hap"

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  HarmonyOS HAP 安装工具" -ForegroundColor Cyan
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
        Write-Host "         请连接手机并确保 USB 调试已开启" -ForegroundColor Yellow
        exit 1
    }
    Write-Host " ✅ 设备: $($targetList[0])" -ForegroundColor Green

    # Step 3: 编译 (可选)
    if (-not $SkipBuild) {
        Write-Host "[Step 3] 编译 HAP..." -ForegroundColor Cyan

        Write-Host "  清理旧构建产物..."
        & hvigorw clean 2>&1 | Out-Null

        Write-Host "  编译中 (hvigorw assembleHap)..."
        $buildOutput = & hvigorw assembleHap 2>&1
        $buildResult = $LASTEXITCODE

        if ($buildResult -ne 0) {
            Write-Host "  ❌ 编译失败" -ForegroundColor Red
            Write-Host ""
            Write-Host "--- 编译错误输出 ---" -ForegroundColor Yellow
            $buildOutput | Select-Object -Last 30 | ForEach-Object { Write-Host $_ }
            Write-Host "--- 编译错误结束 ---" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "请根据错误信息修复代码后重试" -ForegroundColor Yellow
            exit 1
        }
        Write-Host "  ✅ 编译成功" -ForegroundColor Green
    } else {
        Write-Host "[Step 3] 跳过编译 (-SkipBuild)" -ForegroundColor Gray
    }

    # Step 4: 检查 HAP 文件
    Write-Host "[Step 4] 检查 HAP 文件..." -NoNewline
    if (-not (Test-Path $hapPath)) {
        Write-Host " ❌ HAP 文件不存在: $hapPath" -ForegroundColor Red
        Write-Host "         请先运行 'hvigorw assembleHap' 编译" -ForegroundColor Yellow
        exit 1
    }
    $hapSize = (Get-Item $hapPath).Length
    $hapSizeMB = [math]::Round($hapSize / 1MB, 2)
    Write-Host " ✅ ($hapSizeMB MB)" -ForegroundColor Green

    # Step 5: 卸载旧版本 (可选)
    if ($Uninstall) {
        Write-Host "[Step 5] 卸载旧版本 ($BundleName)..." -NoNewline
        & hdc uninstall $BundleName 2>&1 | Out-Null
        Write-Host " ✅" -ForegroundColor Green
    }

    # Step 6: 安装
    Write-Host "[Step 6] 安装 HAP 到设备..." -NoNewline
    $installOutput = & hdc install $hapPath 2>&1
    $installStr = $installOutput -join " "

    if ($installStr -match "success") {
        Write-Host " ✅ 安装成功" -ForegroundColor Green
    } else {
        Write-Host " ❌ 安装失败" -ForegroundColor Red
        Write-Host ""
        Write-Host "--- 安装错误 ---" -ForegroundColor Yellow
        Write-Host $installStr
        Write-Host "--- 安装错误结束 ---" -ForegroundColor Yellow

        if ($installStr -match "already exist") {
            Write-Host ""
            Write-Host "提示：旧版本已安装，请使用 -Uninstall 参数先卸载" -ForegroundColor Yellow
            Write-Host "  .\install_hap.ps1 -Uninstall" -ForegroundColor Cyan
        }
        if ($installStr -match "signature") {
            Write-Host ""
            Write-Host "提示：签名验证失败，请确保 bundleName 为 'com.example.template'" -ForegroundColor Yellow
        }
        exit 1
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  ✅ 安装完成！" -ForegroundColor Green
    Write-Host "  包名: $BundleName" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan

} finally {
    Pop-Location
}
