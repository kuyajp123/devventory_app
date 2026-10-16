param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    foreach ($probe in @('seed', 'restore', 'signed-out')) {
        # Flutter otherwise uninstalls the APK and erases native auth storage.
        flutter test integration_test/auth_journey_test.dart --no-uninstall --flavor development -d $Device --dart-define="SESSION_PROBE=$probe"
        if ($LASTEXITCODE -ne 0) { throw "Native authentication probe failed: $probe" }
    }
} finally {
    Pop-Location
}
