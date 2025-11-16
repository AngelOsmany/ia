# ia

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Notes for running on Web

- The app uses the Hugging Face Inference API. Browsers may block direct requests to that API due to CORS.
- Recommended approaches:
	- Run the app on Android/iOS where CORS is not an issue: `flutter run -d android`.
	- Provide a CORS proxy and rebuild the app for web. Example: `flutter run -d chrome --dart-define=CORS_PROXY=https://your-proxy/?url=`
	- Provide your Hugging Face token via `--dart-define=HF_TOKEN=your_token` to avoid hardcoding it in source.
	
If you need to call Hugging Face APIs from the browser (web) you will likely hit CORS restrictions. A small local proxy is included at `scripts/proxy.py` that forwards requests and injects an `Authorization` header if you provide an `HF_TOKEN`.

Proxy quickstart (local):

1. Install dependencies and start the proxy (it will ask for an optional HF token):

```powershell
cd c:/Users/Manii/Desktop/ia/ia
.\scripts\run-proxy.ps1
```

2. The proxy listens by default on `http://127.0.0.1:7860/proxy` (or you can start it on another port). To test it quickly, run:

```powershell
python scripts/test_proxy.py
```

3. Run the Flutter web app and point it to the proxy (example):

```powershell
flutter run -d chrome --dart-define=CORS_PROXY=http://127.0.0.1:7860/proxy
```

The service `lib/services/huggingface_service.dart` detects `CORS_PROXY` and routes requests through the proxy (supports both query-style proxies like `https://corsproxy.io/?` and our JSON `/proxy` endpoint).

Running on Android
------------------

Android does not enforce browser CORS, so the simplest way to run the app against Hugging Face is on a device or emulator. Steps:

1. Ensure you have an Android device connected (`adb devices`) or an emulator running.
2. Provide your Hugging Face token safely at runtime. You can either set the environment variable `HF_TOKEN` for the session or let the script prompt you.

Run interactively (prompts for token):

```powershell
.\scripts\run-android.ps1
```

Or build an APK and install it later (prompts for token):

```powershell
.\scripts\build-android.ps1
```

Notes:
- I added the `INTERNET` permission to `android/app/src/main/AndroidManifest.xml` so network requests are allowed.
- The app will use the `HF_TOKEN` you supply at runtime. Do not hardcode tokens in source or commit them.


Example run for web with proxy and token (PowerShell):

```powershell
flutter run -d chrome --dart-define=HF_TOKEN=your_token --dart-define=CORS_PROXY=https://your-proxy/?url=
```

If you don't provide a CORS proxy, the app will show a helpful message explaining the CORS limitation in the UI.
