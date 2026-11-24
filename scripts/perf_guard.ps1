# Static performance regression gate for Tally.
# Fails if prohibited GPU-expensive or main-thread-blocking patterns appear in lib/.
$ErrorActionPreference = 'Stop'

$violations = @()

function Check-Pattern {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Pattern,
        [string[]]$AllowFiles = @()
    )
    $files = Get-ChildItem -Path $Path -Recurse -Filter '*.dart'
    foreach ($f in $files) {
        $rel = $f.FullName.Substring((Get-Location).Path.Length + 1).Replace('\', '/')
        if ($AllowFiles -contains $rel) { continue }
        $matches = Select-String -Path $f.FullName -Pattern $Pattern
        foreach ($m in $matches) {
            $script:violations += "[$Name] ${rel}:$($m.LineNumber): $($m.Line.Trim())"
        }
    }
}

Check-Pattern -Name 'BackdropFilter' -Path 'lib' -Pattern 'BackdropFilter\s*\('
Check-Pattern -Name 'ImageFilter' -Path 'lib' -Pattern 'ImageFilter\.'
Check-Pattern -Name 'ShaderMask' -Path 'lib' -Pattern 'ShaderMask\s*\('
Check-Pattern -Name 'LargeBlurShadowInScreens' -Path 'lib/screens' -Pattern 'blurRadius:\s*([89]|[1-9][0-9]+)' -AllowFiles @(
    # Static non-scrolling splash/login/premium promotional hero screens
    'lib/screens/login_screen.dart',
    'lib/screens/premium_screen.dart',
    'lib/screens/saved_accounts_screen.dart'
)
Check-Pattern -Name 'OpacityInScrollScreens' -Path 'lib/screens' -Pattern '\bOpacity\s*\(' -AllowFiles @(
    'lib/screens/splash_screen.dart'
)
Check-Pattern -Name 'SyncExistsInLib' -Path 'lib' -Pattern '\.existsSync\s*\(' -AllowFiles @(
    # Cached single lookup per path in ImageHelper
    'lib/utils/image_helper.dart'
)

if ($violations.Count -gt 0) {
    Write-Host "PERF GUARD FAILED ($($violations.Count) violation(s)):" -ForegroundColor Red
    $violations | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host "PERF GUARD PASSED: 0 prohibited rendering/IO violations found." -ForegroundColor Green
exit 0
