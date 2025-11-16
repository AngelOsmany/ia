# Run the Flutter app on Android using a Hugging Face token provided interactively or via env var HF_TOKEN
param()

if (-not $env:HF_TOKEN -or $env:HF_TOKEN -eq "") {
    $token = Read-Host -Prompt 'Introduce tu HF_TOKEN (no se guardará)'
} else {
    $token = $env:HF_TOKEN
}

if (-not $token -or $token -eq "") {
    Write-Error "No se proporcionó token. Cancelo."
    exit 1
}

Write-Host "Ejecutando Flutter en Android con HF_TOKEN (no se guarda en disco)..."
flutter run -d android --dart-define="HF_TOKEN=$token"
