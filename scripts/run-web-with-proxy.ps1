# Run the Flutter app on Chrome (web) using a Hugging Face token and optional CORS proxy.
# The script asks for token and proxy if not provided in env vars HF_TOKEN and CORS_PROXY.

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

# Proxy is optional; si lo dejas vacío, la app mostrará mensaje sobre CORS en web
if (-not $env:CORS_PROXY) {
    $proxy = Read-Host -Prompt 'Introduce CORS_PROXY (ej: https://corsproxy.io/?url=) o deja vacío para no usar proxy'
} else {
    $proxy = $env:CORS_PROXY
}

$cmd = "flutter run -d chrome --dart-define=HF_TOKEN=$token"
if ($proxy -and $proxy -ne "") {
    $cmd += " --dart-define=CORS_PROXY=$proxy"
}

Write-Host "Ejecutando: $cmd"
Invoke-Expression $cmd
