# Run this from PowerShell in the repo root (or this scripts folder).
# It will prompt for an optional Hugging Face token and start the FastAPI proxy.

$token = Read-Host "HF token (leave empty to run without token)"
if ($token -ne "") {
    $env:HF_TOKEN = $token
    Write-Host "HF_TOKEN set for this process."
} else {
    Write-Host "Starting proxy without HF token (pass token to access private models)."
}

Write-Host "Installing dependencies (virtualenv recommended)..."
python -m pip install -r "scripts/requirements.txt"

Write-Host "Starting proxy at http://0.0.0.0:7860 (press Ctrl+C to stop)"
python -m uvicorn scripts.proxy:app --host 0.0.0.0 --port 7860
