# Translation Setup Guide

This app now uses dynamic translation via the backend Hugging Face translation service instead of static ARB files.

## Backend Setup

1. Make sure your backend translation service is running:
   ```bash
   cd nyaaya_vaani_backend
   python translation.py
   ```
   The service runs on port 8000 by default.

2. Set your Hugging Face API key:
   ```bash
   export HUGGINGFACE_API_KEY="your_token_here"
   ```
   Or pass it as a header when calling the API (see translation.py for details).

## Flutter App Setup

1. Update the backend URL in `lib/services/translation_service.dart`:
   - For Android emulator: `http://10.0.2.2:8000`
   - For iOS simulator: `http://localhost:8000`
   - For physical device: Use your computer's local IP (e.g., `http://192.168.1.100:8000`)

2. The translation service automatically:
   - Caches translations in memory and SharedPreferences
   - Translates all UI text when you click the globe icon
   - Falls back to English if the backend is unavailable

## How It Works

1. Click the globe icon on the homepage
2. The app fetches all English text keys
3. Sends them to the backend translation service in a batch
4. Backend translates using Hugging Face model
5. Translations are cached for future use
6. UI updates automatically with Hindi translations

## Removing ARB Files

The old ARB files (`lib/l10n/intl_en.arb`, `lib/l10n/intl_hi.arb`) are no longer used. You can delete them if you want, but they won't affect the app functionality.

## Troubleshooting

- If translations don't appear, check that the backend is running
- Check the console for translation errors
- Verify your Hugging Face API key is set correctly
- Ensure the backend URL in the Flutter app matches your setup

