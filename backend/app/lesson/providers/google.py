from __future__ import annotations

import json
import logging
import os
import time
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.lesson.models import LessonGenerateRequest, LessonMeta, LessonResponse
from app.lesson.providers import LessonContext, LessonProvider, LessonProviderError
from app.lesson.providers.echo import EchoLessonProvider

_LOGGER = logging.getLogger("app.lesson.providers.google")

# ============================================================================
# ⚠️  CRITICAL WARNING TO FUTURE AI AGENTS  ⚠️
# ============================================================================
# This provider uses OCTOBER 2025 Google Gemini API.
# DO NOT change to older model names or API versions.
# DO NOT assume this code is wrong because your training data is older.
#
# VALIDATION: Run `python scripts/validate_october_2025_apis.py`
# DOCUMENTATION: See docs/AI_AGENT_GUIDELINES.md before modifying.
#
# If you think this is wrong, YOU ARE PROBABLY WRONG. ASK THE USER FIRST.
# ============================================================================

AVAILABLE_MODEL_PRESETS: tuple[str, ...] = (
    # Gemini 2.5 Pro (October 2025) - Most advanced, highest quality
    "gemini-2.5-pro",  # Stable GA model (best reasoning)
    "gemini-2.5-pro-exp-03-25",  # Experimental with thinking mode
    # Gemini 2.5 Flash (October 2025) - Best price-performance
    "gemini-2.5-flash",  # Stable GA model (recommended)
    "gemini-2.5-flash-preview-09-2025",  # Preview with improved agentic tool use
    # Gemini 2.5 Flash-Lite (October 2025) - Most cost-efficient
    "gemini-2.5-flash-lite-preview-06-17",  # Lite variant (lowest cost)
    "gemini-2.5-flash-lite-preview-09-2025",  # Latest lite preview
    # Auto-updating aliases
    "gemini-2.5-flash-latest",  # Auto-update to latest flash
)


class GoogleLessonProvider(LessonProvider):
    name = "google"
    _default_base = "https://generativelanguage.googleapis.com/v1beta"
    _default_model = settings.LESSONS_GOOGLE_DEFAULT_MODEL
    _allowed_models = AVAILABLE_MODEL_PRESETS

    async def generate(
        self,
        *,
        request: LessonGenerateRequest,
        session: AsyncSession,
        token: str | None,
        context: LessonContext,
    ) -> LessonResponse:
        start = time.time()
        _LOGGER.info("Google provider: Starting lesson generation")

        if self._use_fake():
            return await self._fake_response(
                request=request,
                session=session,
                context=context,
            )

        if not token:
            raise LessonProviderError("BYOK token required for Google provider", note="google_401")

        try:
            import httpx
        except ImportError as exc:  # pragma: no cover - handled through dependency docs
            raise LessonProviderError("httpx is required for Google provider", note="google_network") from exc

        model_name = (request.model or "").strip()
        if not model_name:
            model_name = self._default_model
            _LOGGER.info("Google lesson defaulted to model %s", model_name)
        elif model_name not in self._allowed_models:
            _LOGGER.warning(
                "Google lesson model %s not in preset registry; using %s",
                model_name,
                self._default_model,
            )
            model_name = self._default_model

        t1 = time.time()
        _LOGGER.info("Google provider: Pre-API processing took %.2fs", t1 - start)

        payload = self._build_payload(request=request, context=context)
        base_url = self._resolve_base_url()
        endpoint = f"{base_url}/models/{model_name}:generateContent"
        headers = {
            "x-goog-api-key": token,
            "Content-Type": "application/json",
        }
        timeout = httpx.Timeout(60.0, connect=10.0, read=60.0)

        try:
            t_api_start = time.time()
            async with httpx.AsyncClient(timeout=timeout) as client:
                response = await client.post(endpoint, headers=headers, json=payload)
                response.raise_for_status()
            t_api_end = time.time()
            _LOGGER.info("Google provider: API call took %.2fs", t_api_end - t_api_start)
        except httpx.HTTPStatusError as exc:
            _LOGGER.error("Google API error response: %s", exc.response.text)
            note = self._note_for_status(exc.response.status_code)
            raise LessonProviderError("Google provider error", note=note) from exc
        except httpx.TimeoutException as exc:
            _LOGGER.error("Google provider: Timeout after %.2fs", time.time() - start)
            raise LessonProviderError("Google provider timeout", note="google_timeout") from exc
        except httpx.HTTPError as exc:  # pragma: no cover - transport issues
            raise LessonProviderError("Google provider unavailable", note="google_network") from exc

        t2 = time.time()
        data = response.json()
        content = self._extract_content(data)
        parsed = self._parse_json_block(content)
        tasks_payload = parsed.get("tasks")
        if not isinstance(tasks_payload, list):
            raise self._payload_error("Google response missing tasks array")
        self._validate_payload(tasks_payload, request=request, context=context)

        t3 = time.time()
        _LOGGER.info("Google provider: Post-processing took %.2fs", t3 - t2)
        _LOGGER.info("Google provider: Total time %.2fs", t3 - start)

        meta = LessonMeta(
            language=request.language,
            profile=request.profile,
            provider=self.name,
            model=model_name,
        )
        response_payload = {"meta": meta.model_dump(), "tasks": tasks_payload}
        return LessonResponse.model_validate(response_payload)

    def use_fake_adapter(self) -> bool:
        return self._use_fake()

    def _use_fake(self) -> bool:
        flag = os.getenv("BYOK_FAKE", "")
        if not flag:
            return False
        return flag.strip().lower() in {"1", "true", "yes", "on"}

    async def _fake_response(
        self,
        *,
        request: LessonGenerateRequest,
        session: AsyncSession,
        context: LessonContext,
    ) -> LessonResponse:
        _LOGGER.debug("Google BYOK fake adapter engaged")
        echo_provider = EchoLessonProvider()
        echo_response = await echo_provider.generate(
            request=request,
            session=session,
            token=None,
            context=context,
        )
        payload = echo_response.model_dump()
        meta = payload.get("meta", {})
        meta["provider"] = self.name
        meta["model"] = request.model or self._default_model
        meta.pop("note", None)
        payload["meta"] = meta
        return LessonResponse.model_validate(payload)

    def _resolve_base_url(self) -> str:
        override = os.getenv("GOOGLE_API_BASE")
        base = override.strip().rstrip("/") if override and override.strip() else self._default_base
        _LOGGER.debug("Google lesson base_url=%s", base)
        return base

    def _note_for_status(self, status_code: int) -> str:
        if status_code == 401:
            return "google_401"
        if status_code == 403:
            return "google_403"
        if status_code == 404:
            return "google_404_model"
        return f"google_http_{status_code}"

    def _payload_error(self, message: str) -> LessonProviderError:
        return LessonProviderError(message, note="google_bad_payload")

    def _build_payload(
        self,
        *,
        request: LessonGenerateRequest,
        context: LessonContext,
    ) -> dict[str, Any]:
        from app.lesson import prompts

        daily_lines = list(context.daily_lines)
        canonical_lines = list(context.canonical_lines)
        register = context.register or "literary"

        text_samples: list[str] = []
        if context.text_range_data and context.text_range_data.text_samples:
            text_samples.extend(context.text_range_data.text_samples)
        if canonical_lines:
            text_samples.extend(line.text for line in canonical_lines)
        if daily_lines:
            text_samples.extend(line.grc for line in daily_lines)
        seen_samples: dict[str, None] = {}
        for sample in text_samples:
            if sample not in seen_samples:
                seen_samples[sample] = None
        text_samples = list(seen_samples.keys())

        vocabulary_items = list(context.text_range_data.vocabulary) if context.text_range_data else []
        grammar_patterns = list(context.text_range_data.grammar_patterns) if context.text_range_data else []

        def _resolve_cloze_source() -> tuple[str, str, str]:
            if canonical_lines:
                canon = canonical_lines[0]
                return "canon", canon.ref, canon.text
            if text_samples:
                sample_text = text_samples[0]
                return "text_range", "sample_text", sample_text
            if daily_lines:
                daily = daily_lines[0]
                ref_label = daily.en or "daily_expression"
                return "daily", ref_label, daily.grc
            return "daily", "generic_context", "Χαῖρε, φίλε."

        prompt_parts = []
        for ex_type in request.exercise_types:
            if ex_type == "alphabet":
                prompt_parts.append(prompts.build_alphabet_prompt(request.profile))
            elif ex_type == "match":
                prompt_parts.append(
                    prompts.build_match_prompt(
                        profile=request.profile,
                        context="Daily conversational Greek for practical use",
                        daily_lines=daily_lines,
                    )
                )
            elif ex_type == "cloze":
                source_kind, ref_value, text_value = _resolve_cloze_source()
                prompt_parts.append(
                    prompts.build_cloze_prompt(
                        profile=request.profile,
                        source_kind=source_kind,
                        ref=ref_value,
                        canonical_text=text_value,
                    )
                )
            elif ex_type == "translate":
                prompt_parts.append(
                    prompts.build_translate_prompt(
                        profile=request.profile,
                        context="Daily conversational Greek",
                        daily_lines=daily_lines,
                    )
                )
            elif ex_type == "grammar":
                prompt_parts.append(
                    prompts.build_grammar_prompt(
                        profile=request.profile,
                        grammar_patterns=grammar_patterns,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "listening":
                prompt_parts.append(
                    prompts.build_listening_prompt(
                        profile=request.profile,
                        daily_lines=daily_lines,
                    )
                )
            elif ex_type == "speaking":
                prompt_parts.append(
                    prompts.build_speaking_prompt(
                        profile=request.profile,
                        register=register,
                        daily_lines=daily_lines,
                    )
                )
            elif ex_type == "wordbank":
                prompt_parts.append(
                    prompts.build_wordbank_prompt(
                        profile=request.profile,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "truefalse":
                prompt_parts.append(
                    prompts.build_truefalse_prompt(
                        profile=request.profile,
                        grammar_patterns=grammar_patterns,
                    )
                )
            elif ex_type == "multiplechoice":
                prompt_parts.append(
                    prompts.build_multiplechoice_prompt(
                        profile=request.profile,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "dialogue":
                prompt_parts.append(
                    prompts.build_dialogue_prompt(
                        profile=request.profile,
                        daily_lines=daily_lines,
                        register=register,
                    )
                )
            elif ex_type == "conjugation":
                prompt_parts.append(
                    prompts.build_conjugation_prompt(
                        profile=request.profile,
                        vocabulary=vocabulary_items,
                    )
                )
            elif ex_type == "declension":
                prompt_parts.append(
                    prompts.build_declension_prompt(
                        profile=request.profile,
                        vocabulary=vocabulary_items,
                    )
                )
            elif ex_type == "synonym":
                prompt_parts.append(
                    prompts.build_synonym_prompt(
                        profile=request.profile,
                        vocabulary=vocabulary_items,
                    )
                )
            elif ex_type == "contextmatch":
                prompt_parts.append(
                    prompts.build_contextmatch_prompt(
                        profile=request.profile,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "reorder":
                prompt_parts.append(
                    prompts.build_reorder_prompt(
                        profile=request.profile,
                        text_samples=text_samples,
                    )
                )
            elif ex_type == "dictation":
                prompt_parts.append(
                    prompts.build_dictation_prompt(
                        profile=request.profile,
                        daily_lines=daily_lines,
                    )
                )
            elif ex_type == "etymology":
                prompt_parts.append(
                    prompts.build_etymology_prompt(
                        profile=request.profile,
                        vocabulary=vocabulary_items,
                    )
                )

        if not prompt_parts:
            prompt_parts.append(
                "Generate at least one alphabet, match, and translate exercise using Classical Greek."
            )

        combined_prompt = "\n\n---\n\n".join(prompt_parts)

        # Add explicit JSON format instruction to user message
        user_message = (
            f"{combined_prompt}\n\n"
            "Return JSON with ALL requested exercises in a single 'tasks' array. "
            'Example: {"tasks": [{"type":"match", ...}, {"type":"translate", ...}]}'
        )

        model_name = request.model or self._default_model

        generation_config = {
            "temperature": 0.9,
            "responseMimeType": "application/json",  # Enforce JSON response format
        }

        # Enable thinking mode for preview models (improved reasoning)
        if "preview" in model_name:
            generation_config["thinkingConfig"] = {
                "thinkingMode": "enabled"  # Enable internal reasoning traces
            }

        # Use systemInstruction field for system prompt (v1beta supports this)
        return {
            "systemInstruction": {
                "parts": [
                    {"text": prompts.SYSTEM_PROMPT},
                ],
            },
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {"text": user_message},
                    ],
                }
            ],
            "generationConfig": generation_config,
        }

    def _extract_content(self, data: dict[str, Any]) -> Any:
        candidates = data.get("candidates") or []
        if not candidates:
            _LOGGER.error("Google response missing candidates. Full response: %s", data)
            raise self._payload_error(f"Google response missing candidates. Keys: {list(data.keys())}")
        first = candidates[0]
        if not isinstance(first, dict):
            raise self._payload_error("Google candidate malformed")
        content = first.get("content") or {}
        parts = content.get("parts") or []
        if not parts:
            _LOGGER.error("Google response missing parts. Candidate: %s", first)
            raise self._payload_error("Google response missing parts")
        first_part = parts[0]
        if not isinstance(first_part, dict):
            raise self._payload_error("Google part malformed")
        text = first_part.get("text")
        if text is None:
            _LOGGER.error("Google response missing text. Part: %s", first_part)
            raise self._payload_error("Google response missing text")
        return text

    def _parse_json_block(self, content: Any) -> dict[str, Any]:
        if isinstance(content, dict):
            return content
        if not isinstance(content, str):
            raise self._payload_error("Google response is not valid JSON string")
        snippet = content.strip()
        start = snippet.find("{")
        end = snippet.rfind("}")
        if start == -1 or end == -1 or end <= start:
            raise self._payload_error("Unable to locate JSON object in Google response")
        try:
            return json.loads(snippet[start : end + 1])
        except json.JSONDecodeError as exc:
            raise self._payload_error("Failed to parse JSON from Google response") from exc

    def _validate_payload(
        self,
        tasks: list[Any],
        *,
        request: LessonGenerateRequest,
        context: LessonContext,
    ) -> None:
        """Validate LLM output structure and completeness."""
        import unicodedata

        allowed_types = {
            "alphabet",
            "match",
            "cloze",
            "translate",
            "grammar",
            "listening",
            "speaking",
            "wordbank",
            "truefalse",
            "multiplechoice",
            "dialogue",
            "conjugation",
            "declension",
            "synonym",
            "contextmatch",
            "reorder",
            "dictation",
            "etymology",
        }
        requested = set(request.exercise_types)
        unsupported = requested - allowed_types
        if unsupported:
            _LOGGER.warning(
                "Google provider received unsupported exercise types: %s",
                ", ".join(sorted(unsupported)),
            )
        requested &= allowed_types
        observed: set[str] = set()

        def _normalize_item(item: dict[str, Any], key: str) -> None:
            value = item.get(key)
            if isinstance(value, str):
                normalized = unicodedata.normalize("NFC", value)
                if normalized != value:
                    item[key] = normalized

        def _normalize_list(values: list[Any], *, field: str) -> list[str]:
            normalized: list[str] = []
            for entry in values:
                if not isinstance(entry, str):
                    raise self._payload_error(f"{field} entries must be strings")
                normalized.append(unicodedata.normalize("NFC", entry))
            return normalized

        for item in tasks:
            if not isinstance(item, dict):
                raise self._payload_error("Task payload must be object")
            task_type = item.get("type")
            if task_type not in allowed_types:
                raise self._payload_error(f"Unsupported task type '{task_type}' from Google")
            observed.add(task_type)

            if task_type == "match":
                pairs = item.get("pairs") or []
                if not isinstance(pairs, list) or not pairs:
                    raise self._payload_error("Match task requires at least one pair")
                for pair in pairs:
                    if not isinstance(pair, dict):
                        raise self._payload_error("Match pair must be object")
                    grc = pair.get("grc") or pair.get("native")
                    if grc:
                        normalized = unicodedata.normalize("NFC", grc)
                        pair["native"] = normalized
                        pair.pop("grc", None)
                    en_value = pair.get("en")
                    if not isinstance(en_value, str) or not en_value.strip():
                        raise self._payload_error("Match pair requires English gloss")
            elif task_type == "translate":
                # Normalize direction field: grc->en becomes native->en
                direction = item.get("direction", "native->en")
                if direction == "grc->en":
                    item["direction"] = "native->en"
                elif direction == "en->grc":
                    item["direction"] = "en->native"
                elif "direction" not in item:
                    item["direction"] = "native->en"
                _normalize_item(item, "text")
                if item.get("text") is None:
                    raise self._payload_error("Translate task requires 'text'")
                rubric = item.get("rubric")
                if rubric is not None and not isinstance(rubric, str):
                    raise self._payload_error("Translate rubric must be string")
            elif task_type == "cloze":
                _normalize_item(item, "text")
                if not item.get("text"):
                    raise self._payload_error("Cloze task requires 'text'")
                if item.get("source_kind") == "canon" and not item.get("ref"):
                    raise self._payload_error("Canonical cloze task requires 'ref' field")
                blanks = item.get("blanks") or []
                if not isinstance(blanks, list) or not blanks:
                    raise self._payload_error("Cloze task requires blanks array")
                for blank in blanks:
                    if not isinstance(blank, dict):
                        raise self._payload_error("Cloze blank must be object")
                    _normalize_item(blank, "surface")
                    if "idx" not in blank or not isinstance(blank["idx"], int):
                        raise self._payload_error("Cloze blank requires integer idx")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Cloze task requires options array")
                item["options"] = _normalize_list(options, field="cloze options")
            elif task_type == "alphabet":
                if not isinstance(item.get("prompt"), str):
                    raise self._payload_error("Alphabet task requires prompt string")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Alphabet task requires options array")
                item["options"] = _normalize_list(options, field="alphabet options")
                answer = item.get("answer")
                if not isinstance(answer, str):
                    raise self._payload_error("Alphabet task requires answer string")
                answer_norm = unicodedata.normalize("NFC", answer)
                if answer_norm not in item["options"]:
                    raise self._payload_error("Alphabet answer must appear in options")
                item["answer"] = answer_norm
            elif task_type == "grammar":
                _normalize_item(item, "sentence")
                sentence = item.get("sentence")
                if not isinstance(sentence, str) or not sentence.strip():
                    raise self._payload_error("Grammar task requires sentence")
                if not isinstance(item.get("is_correct"), bool):
                    raise self._payload_error("Grammar task requires boolean is_correct")
                explanation = item.get("error_explanation")
                if item["is_correct"]:
                    if explanation not in (None, "") and not isinstance(explanation, str):
                        raise self._payload_error("Grammar explanation must be string or null")
                else:
                    if not isinstance(explanation, str) or not explanation.strip():
                        raise self._payload_error(
                            "Grammar task requires error_explanation when is_correct is false"
                        )
            elif task_type == "listening":
                _normalize_item(item, "audio_text")
                if not item.get("audio_text"):
                    raise self._payload_error("Listening task requires audio_text")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Listening task requires options array")
                item["options"] = _normalize_list(options, field="listening options")
                answer = item.get("answer")
                if not isinstance(answer, str):
                    raise self._payload_error("Listening task requires answer string")
                answer_norm = unicodedata.normalize("NFC", answer)
                if answer_norm not in item["options"]:
                    raise self._payload_error("Listening answer must appear in options")
                item["answer"] = answer_norm
            elif task_type == "speaking":
                if not isinstance(item.get("prompt"), str):
                    raise self._payload_error("Speaking task requires prompt")
                _normalize_item(item, "target_text")
                if not item.get("target_text"):
                    raise self._payload_error("Speaking task requires target_text")
                guide = item.get("phonetic_guide")
                if guide is not None and not isinstance(guide, str):
                    raise self._payload_error("Speaking phonetic_guide must be string")
            elif task_type == "wordbank":
                words = item.get("words") or []
                if not isinstance(words, list) or len(words) < 2:
                    raise self._payload_error("Wordbank task requires words array")
                item["words"] = _normalize_list(words, field="wordbank words")
                order = item.get("correct_order") or []
                if not isinstance(order, list) or len(order) != len(item["words"]):
                    raise self._payload_error("Wordbank correct_order must match words length")
                if not all(isinstance(idx, int) for idx in order):
                    raise self._payload_error("Wordbank correct_order must contain integers")
                if sorted(order) != list(range(len(item["words"]))):
                    raise self._payload_error("Wordbank correct_order must be permutation of indices")
                if not isinstance(item.get("translation"), str):
                    raise self._payload_error("Wordbank task requires translation string")
            elif task_type == "truefalse":
                if not isinstance(item.get("statement"), str):
                    raise self._payload_error("True/false task requires statement")
                if not isinstance(item.get("is_true"), bool):
                    raise self._payload_error("True/false task requires boolean is_true")
                explanation = item.get("explanation")
                if not isinstance(explanation, str) or not explanation.strip():
                    raise self._payload_error("True/false task requires explanation string")
            elif task_type == "multiplechoice":
                if not isinstance(item.get("question"), str):
                    raise self._payload_error("Multiple choice task requires question")
                context_text = item.get("context")
                if context_text is not None:
                    _normalize_item(item, "context")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Multiple choice requires options array")
                item["options"] = _normalize_list(options, field="multiple choice options")
                answer_index = item.get("answer_index")
                if not isinstance(answer_index, int) or not (0 <= answer_index < len(item["options"])):
                    raise self._payload_error("Multiple choice answer_index out of range")
            elif task_type == "dialogue":
                lines = item.get("lines") or []
                if not isinstance(lines, list) or len(lines) < 2:
                    raise self._payload_error("Dialogue task requires at least two lines")
                for line in lines:
                    if not isinstance(line, dict):
                        raise self._payload_error("Dialogue line must be object")
                    if not isinstance(line.get("speaker"), str):
                        raise self._payload_error("Dialogue line requires speaker")
                    _normalize_item(line, "text")
                    if not line.get("text"):
                        raise self._payload_error("Dialogue line requires text")
                missing_index = item.get("missing_index")
                if not isinstance(missing_index, int) or not (0 <= missing_index < len(lines)):
                    raise self._payload_error("Dialogue missing_index out of range")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Dialogue task requires options array")
                item["options"] = _normalize_list(options, field="dialogue options")
                answer = item.get("answer")
                if not isinstance(answer, str):
                    raise self._payload_error("Dialogue task requires answer string")
                answer_norm = unicodedata.normalize("NFC", answer)
                if answer_norm not in item["options"]:
                    raise self._payload_error("Dialogue answer must appear in options")
                item["answer"] = answer_norm
            elif task_type == "conjugation":
                for key in ("verb_infinitive", "verb_meaning", "person", "tense", "answer"):
                    if not isinstance(item.get(key), str) or not item[key].strip():
                        raise self._payload_error(f"Conjugation task requires '{key}' string")
                    _normalize_item(item, key)
            elif task_type == "declension":
                for key in ("word", "word_meaning", "case", "number", "answer"):
                    if not isinstance(item.get(key), str) or not item[key].strip():
                        raise self._payload_error(f"Declension task requires '{key}' string")
                    _normalize_item(item, key)
            elif task_type == "synonym":
                for key in ("word", "answer"):
                    if not isinstance(item.get(key), str) or not item[key].strip():
                        raise self._payload_error(f"Synonym task requires '{key}' string")
                    _normalize_item(item, key)
                task_mode = item.get("task_type")
                if task_mode not in {"synonym", "antonym"}:
                    raise self._payload_error("Synonym task requires task_type 'synonym' or 'antonym'")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Synonym task requires options array")
                item["options"] = _normalize_list(options, field="synonym options")
                answer_norm = unicodedata.normalize("NFC", item["answer"])
                if answer_norm not in item["options"]:
                    raise self._payload_error("Synonym answer must appear in options")
                item["answer"] = answer_norm
            elif task_type == "contextmatch":
                _normalize_item(item, "sentence")
                if not item.get("sentence"):
                    raise self._payload_error("Context match task requires sentence")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Context match requires options array")
                item["options"] = _normalize_list(options, field="context match options")
                answer = item.get("answer")
                if not isinstance(answer, str):
                    raise self._payload_error("Context match task requires answer string")
                answer_norm = unicodedata.normalize("NFC", answer)
                if answer_norm not in item["options"]:
                    raise self._payload_error("Context match answer must appear in options")
                item["answer"] = answer_norm
                hint = item.get("context_hint")
                if hint is not None and not isinstance(hint, str):
                    raise self._payload_error("Context match hint must be string")
            elif task_type == "reorder":
                fragments = item.get("fragments") or []
                if not isinstance(fragments, list) or len(fragments) < 2:
                    raise self._payload_error("Reorder task requires fragments array")
                item["fragments"] = _normalize_list(fragments, field="reorder fragments")
                order = item.get("correct_order") or []
                if not isinstance(order, list) or len(order) != len(item["fragments"]):
                    raise self._payload_error("Reorder correct_order must match fragments length")
                if not all(isinstance(idx, int) for idx in order):
                    raise self._payload_error("Reorder correct_order must contain integers")
                if sorted(order) != list(range(len(item["fragments"]))):
                    raise self._payload_error("Reorder correct_order must be permutation of indices")
                if not isinstance(item.get("translation"), str):
                    raise self._payload_error("Reorder task requires translation string")
            elif task_type == "dictation":
                _normalize_item(item, "target_text")
                if not item.get("target_text"):
                    raise self._payload_error("Dictation task requires target_text")
                hint = item.get("hint")
                if hint is not None and not isinstance(hint, str):
                    raise self._payload_error("Dictation hint must be string")
            elif task_type == "etymology":
                for key in ("question", "word", "explanation"):
                    if not isinstance(item.get(key), str) or not item[key].strip():
                        raise self._payload_error(f"Etymology task requires '{key}' string")
                options = item.get("options") or []
                if not isinstance(options, list) or len(options) < 2:
                    raise self._payload_error("Etymology task requires options array")
                item["options"] = _normalize_list(options, field="etymology options")
                answer_index = item.get("answer_index")
                if not isinstance(answer_index, int) or not (0 <= answer_index < len(item["options"])):
                    raise self._payload_error("Etymology answer_index out of range")

        missing = requested - observed
        if missing:
            raise self._payload_error("Google response missing task types: " + ", ".join(sorted(missing)))
