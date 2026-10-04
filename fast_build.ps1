#!/usr/bin/env pwsh
# ──────────────────────────────────────────────────────────────────────────────
# fast_build.ps1 — Fast APK build for local sideloading / testing
# Usage:
#   .\fast_build.ps1           # arm64-v8a only (fastest, covers 95%+ of devices)
#   .\fast_build.ps1 -AllAbi   # all architectures (slower, for distribution)
#   .\fast_build.ps1 -Clean    # wipe incremental cache first then build
# ──────────────────────────────────────────────────────────────────────────────
param(
    [switch]$AllAbi,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Set-Location $ProjectRoot

if ($Clean) {
    Write-Host "🧹 Cleaning previous build outputs..." -ForegroundColor Yellow
    flutter clean
    Write-Host ""
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

if ($AllAbi) {
    Write-Host "🏗️  Building release APK (ALL ABI — fat APK)..." -ForegroundColor Cyan
    flutter build apk --release `
        --no-tree-shake-icons `
        --dart-define=FLUTTER_BUILD_MODE=release
} else {
    Write-Host "🚀 Building release APK (arm64-v8a ONLY — fastest)..." -ForegroundColor Green
    flutter build apk --release `
        --target-platform android-arm64 `
        --split-per-abi `
        --no-tree-shake-icons `
        --dart-define=FLUTTER_BUILD_MODE=release
}

$stopwatch.Stop()
$elapsed = [math]::Round($stopwatch.Elapsed.TotalSeconds, 1)

Write-Host ""
Write-Host "✅ Build complete in ${elapsed}s" -ForegroundColor Green
Write-Host ""

# Show output APK paths
$apkDir = Join-Path $ProjectRoot "build\app\outputs\flutter-apk"
if (Test-Path $apkDir) {
    Write-Host "📦 Output APKs:" -ForegroundColor Cyan
    Get-ChildItem $apkDir -Filter "*.apk" | ForEach-Object {
        $sizeKb = [math]::Round($_.Length / 1MB, 1)
        Write-Host "   $($_.Name)  ($sizeKb MB)" -ForegroundColor White
    }
}
