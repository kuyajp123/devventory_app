param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    foreach ($probe in @('seed', 'restore', 'signed-out')) {
        # Preserve the real SDK session and native SQLite across separate processes.
        flutter test integration_test/projects_journey_test.dart --no-uninstall --flavor development -d $Device --dart-define="SESSION_PROBE=$probe"
        if ($LASTEXITCODE -ne 0) { throw "Native projects probe failed: $probe" }
    }
} finally {
    Pop-Location
}
