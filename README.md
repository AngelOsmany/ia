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

Example run for web with proxy and token (PowerShell):

```powershell
flutter run -d chrome --dart-define=HF_TOKEN=your_token --dart-define=CORS_PROXY=https://your-proxy/?url=
```

If you don't provide a CORS proxy, the app will show a helpful message explaining the CORS limitation in the UI.
