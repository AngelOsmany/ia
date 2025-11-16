from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import httpx
import os

app = FastAPI(title="HF CORS Proxy")

# Allow all origins for local development; restrict in production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Optional token provided via environment variable HF_TOKEN
HF_TOKEN = os.getenv("HF_TOKEN", "")


@app.post("/proxy")
async def proxy(request: Request):
    """Proxy generic POST JSON -> forwards to `url` provided in body.

    Expected JSON body:
      {
        "url": "https://...",
        "data": {... or [...]},
        "headers": {"Custom-Header": "value"}
      }

    The proxy will add Authorization: Bearer <HF_TOKEN> if the env var is set
    and the incoming `headers` does not already contain an Authorization header.
    """
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON body")

    url = body.get("url")
    data = body.get("data")
    headers = body.get("headers") or {}

    if not url:
        raise HTTPException(status_code=400, detail="Missing 'url' in request body")

    # Inject HF token if available and not provided explicitly
    if HF_TOKEN and not any(h.lower() == "authorization" for h in headers):
        headers["Authorization"] = f"Bearer {HF_TOKEN}"

    timeout = httpx.Timeout(60.0, connect=20.0)
    async with httpx.AsyncClient(timeout=timeout) as client:
        try:
            resp = await client.post(url, json=data, headers=headers)
        except httpx.RequestError as e:
            raise HTTPException(status_code=502, detail=f"Upstream request failed: {e}")

    # Try to return JSON, otherwise return text content
    content_type = resp.headers.get("content-type", "")
    if "application/json" in content_type:
        try:
            return JSONResponse(status_code=resp.status_code, content=resp.json())
        except Exception:
            # malformed json
            return JSONResponse(status_code=resp.status_code, content={"raw": resp.text})

    return JSONResponse(status_code=resp.status_code, content={"raw": resp.text})


@app.get("/health")
async def health():
    return {"status": "ok", "proxy": True}
