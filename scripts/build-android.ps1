# Build Android APK/AAB with an optional HF token passed securely at runtime.
param()

# Prompt for token if not provided in env
if (-not $env:HF_TOKEN -or $env:HF_TOKEN -eq "") {
    $token = Read-Host -Prompt 'HF token (leave empty to build without token)'
} else {
    $token = $env:HF_TOKEN
}

if ($token -ne "") {
    Write-Host "Building APK with HF_TOKEN provided for this process..."
    flutter build apk --release --dart-define="HF_TOKEN=$token"
} else {
    Write-Host "Building APK without HF_TOKEN..."
    flutter build apk --release
}

Write-Host "Build finished. Find the APK in build/app/outputs/flutter-apk/"
