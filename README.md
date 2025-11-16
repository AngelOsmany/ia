# IA APP

A Flutter application for interacting with multiple AI APIs including Gemini and Hugging Face.

## Quick Start

### Prerequisites
- Flutter SDK installed and configured
- API keys for Gemini and/or Hugging Face

### Running the App

1. **Clone or extract the project**
   ```bash
   cd ia_app
   ```

2. **Configure API Keys**
   - Edit `lib/secrets.dart` and add your API keys:
     - `geminiApiKey`: Your Google Gemini API key
     - `huggingFaceToken`: Your Hugging Face API token

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## API Key Storage

- API keys are stored in `lib/secrets.dart`
- **Security Note**: Never commit `lib/secrets.dart` to version control
- For production, use environment variables or secure key management services

## Key Features

- **AI Interactions**: Chat with multiple AI models
- **REST API Integration**: Direct API calls with custom parameters
- **WebSocket Support**: Real-time communication for applicable APIs

## CORS Note

When running on web platform, ensure your backend or CORS-enabled APIs are properly configured to accept requests from this application's origin.

## Security Guidance

1. **Keep secrets private**: Never share or commit API keys
2. **Use environment variables**: In production, inject keys via environment variables
3. **Rotate keys regularly**: If accidentally exposed, regenerate your API keys
4. **Monitor usage**: Track API usage to detect unauthorized access
5. **Rate limiting**: Implement rate limiting on your backend if exposed to web

## Support

For issues or questions, please refer to the Flutter documentation and the respective AI service documentation.
