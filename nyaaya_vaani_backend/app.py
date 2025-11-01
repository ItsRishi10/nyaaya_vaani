from typing import List, Dict, Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import re
import uvicorn

# Transformers imports are inside try/except to give a clear error if not installed.
try:
    from transformers import pipeline
except Exception as e:
    pipeline = None
    _TRANSFORMERS_IMPORT_ERROR = e

app = FastAPI(title="Nyaaya Vaani Translation Backend")

# Load translator pipeline on startup
_TRANSLATOR = None
_MODEL_NAME = "Helsinki-NLP/opus-mt-en-hi"


class TextIn(BaseModel):
    texts: List[str]


class SingleTextIn(BaseModel):
    text: str


class ExtractRequest(BaseModel):
    content: str  # Dart file content
    replace: Optional[bool] = False  # whether to return a version of the file with translations applied


def _ensure_translator():
    global _TRANSLATOR, pipeline
    if pipeline is None:
        raise RuntimeError(f"transformers package not available: {_TRANSFORMERS_IMPORT_ERROR}")
    global _TRANSLATOR
    if _TRANSLATOR is None:
        # create a translation pipeline from English to Hindi
        _TRANSLATOR = pipeline("translation_en_to_hi", model=_MODEL_NAME)
    return _TRANSLATOR


@app.post('/translate')
async def translate(req: TextIn):
    """Translate a list of English texts to Hindi. Returns translations in the same order."""
    if not req.texts:
        return {"translations": []}
    translator = _ensure_translator()
    # batch translate
    try:
        results = translator(req.texts)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    translations = [r['translation_text'] for r in results]
    return {"translations": translations}


@app.post('/translate_one')
async def translate_one(req: SingleTextIn):
    translator = _ensure_translator()
    try:
        r = translator(req.text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"translation": r[0]['translation_text']}


# Regex to capture simple string literals. This is conservative and may miss complex multi-line strings.
_STRING_LITERAL_RE = re.compile(r'(["\'])(?P<text>.*?)(?<!\\)\1')


def _is_ui_text(s: str) -> bool:
    # Heuristics: must contain at least one letter and not look like a path, URL, or code identifier
    if len(s.strip()) < 2:
        return False
    if re.search(r'[a-zA-Z]', s) is None:
        return False
    if '/' in s or '\\' in s:
        return False
    if s.strip().startswith('http'):
        return False
    if re.match(r'^[\w\-_.]+@[\w\-_.]+', s):
        return False
    # avoid single letters like 'A' or 'I' unless longer
    if len(s.strip()) <= 1:
        return False
    return True


@app.post('/extract_and_translate')
async def extract_and_translate(req: ExtractRequest):
    """
    Extracts string literals from provided Dart content, filters likely UI strings, translates them to Hindi,
    and optionally returns a version of the content with the strings replaced by their Hindi translations.

    Returns a mapping original -> translated and (if replace=True) the modified content.
    """
    content = req.content
    matches = list(_STRING_LITERAL_RE.finditer(content))
    candidates = []
    for m in matches:
        text = m.group('text')
        if _is_ui_text(text):
            candidates.append(text)
    # deduplicate while preserving order
    seen = set()
    uniq = []
    for t in candidates:
        if t not in seen:
            seen.add(t)
            uniq.append(t)

    if not uniq:
        return {"mapping": {}, "translated_content": content if req.replace else None}

    translator = _ensure_translator()
    try:
        results = translator(uniq)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    translations = [r['translation_text'] for r in results]
    mapping = dict(zip(uniq, translations))

    translated_content = None
    if req.replace:
        # perform safe replacement: replace only the literal occurrences inside quotes
        def _replace_match(m):
            quote = m.group(1)
            txt = m.group('text')
            if txt in mapping:
                # preserve surrounding quotes
                # escape any quote characters in translation that match the original quote
                newtxt = mapping[txt].replace(quote, '\\' + quote)
                return f'{quote}{newtxt}{quote}'
            return m.group(0)

        translated_content = _STRING_LITERAL_RE.sub(_replace_match, content)

    return {"mapping": mapping, "translated_content": translated_content}


if __name__ == '__main__':
    # Run for local debugging
    uvicorn.run(app, host='0.0.0.0', port=8000)
