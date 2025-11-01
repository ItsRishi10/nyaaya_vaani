Nyaaya Vaani — Translation Backend

This small FastAPI app provides endpoints to translate English text to Hindi using Hugging Face Transformers.

Endpoints

- POST /translate
  - Body: {"texts": ["Hello", "How are you?"]}
  - Returns: {"translations": ["हैलो", "आप कैसे हैं?"]}

- POST /translate_one
  - Body: {"text": "Hello"}
  - Returns: {"translation": "हैलो"}

- POST /extract_and_translate
  - Body: {"content": "<contents of a Dart file>", "replace": false}
  - Extracts string literals that look like UI text, translates them, and returns a mapping original->translation.
  - If replace=true, also returns a `translated_content` where the original strings are replaced with the Hindi translations.

Quick start (Windows PowerShell)

1. Create a virtual environment and install dependencies

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. Run the server

```powershell
python app.py
```

3. Example curl (translate)

```powershell
curl -X POST http://127.0.0.1:8000/translate -H "Content-Type: application/json" -d '{"texts": ["Hello", "Register"]}'
```

Notes / Caveats

- The app downloads a transformer model (Helsinki-NLP/opus-mt-en-hi) on first run; this requires network and may take time and disk space.
- The translation quality is suitable for rough UI localization and prototyping. For production-grade localization (context-aware, consistent terminology), consider human reviews or a hybrid approach.
- Replacing strings inside source files is best-effort. Review the replaced file before committing changes.
