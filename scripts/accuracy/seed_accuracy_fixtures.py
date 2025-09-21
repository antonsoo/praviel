from __future__ import annotations

import asyncio
from typing import Any

from app.db.util import SessionLocal, text_with_json
from app.ingestion.jobs import ensure_language, ensure_source, ensure_work
from app.ingestion.normalize import accent_fold, nfc
from sqlalchemy import text

LEXEME_FIXTURES: list[dict[str, Any]] = [
    {
        "lemma": "μῆνις",
        "gloss": "wrath; anger",
        "citation": "Demo lexicon μῆνις",
        "forms": [
            {"surface": "μῆνιν", "msd": {"perseus_tag": "n-s---fa-"}},
            {"surface": "μῆνι", "msd": {"perseus_tag": "n-s---fd-"}},
        ],
    },
    {
        "lemma": "ἀείδω",
        "gloss": "sing; chant",
        "citation": "Demo lexicon ἀείδω",
        "forms": [
            {"surface": "ἄειδε", "msd": {"perseus_tag": "v-imp---2s-"}},
            {"surface": "ἄειδον", "msd": {"perseus_tag": "v-ia---1s-"}},
        ],
    },
    {
        "lemma": "θεά",
        "gloss": "goddess",
        "citation": "Demo lexicon θεά",
        "forms": [
            {"surface": "θεὰ", "msd": {"perseus_tag": "n-s---fn-"}},
            {"surface": "θεάν", "msd": {"perseus_tag": "n-s---fa-"}},
        ],
    },
    {
        "lemma": "ἥρως",
        "gloss": "hero",
        "citation": "Demo lexicon ἥρως",
        "forms": [
            {"surface": "ἥρωα", "msd": {"perseus_tag": "n-s---ma-"}},
            {"surface": "ἥρωες", "msd": {"perseus_tag": "n-p---mn-"}},
        ],
    },
    {
        "lemma": "ἀνήρ",
        "gloss": "man",
        "citation": "Demo lexicon ἀνήρ",
        "forms": [
            {"surface": "ἄνδρα", "msd": {"perseus_tag": "n-s---ma-"}},
            {"surface": "ἀνδρῶν", "msd": {"perseus_tag": "n-p---mg-"}},
        ],
    },
    {
        "lemma": "ψυχή",
        "gloss": "soul; life",
        "citation": "Demo lexicon ψυχή",
        "forms": [
            {"surface": "ψυχήν", "msd": {"perseus_tag": "n-s---fa-"}},
            {"surface": "ψυχῇ", "msd": {"perseus_tag": "n-s---fd-"}},
        ],
    },
    {
        "lemma": "θάλασσα",
        "gloss": "sea",
        "citation": "Demo lexicon θάλασσα",
        "forms": [
            {"surface": "θάλασσαν", "msd": {"perseus_tag": "n-s---fa-"}},
            {"surface": "θαλάσσῃ", "msd": {"perseus_tag": "n-s---fd-"}},
        ],
    },
    {
        "lemma": "λόγος",
        "gloss": "word; reason",
        "citation": "Demo lexicon λόγος",
        "forms": [
            {"surface": "λόγον", "msd": {"perseus_tag": "n-s---ma-"}},
            {"surface": "λόγοι", "msd": {"perseus_tag": "n-p---mn-"}},
        ],
    },
    {
        "lemma": "φιλία",
        "gloss": "friendship",
        "citation": "Demo lexicon φιλία",
        "forms": [
            {"surface": "φιλίαν", "msd": {"perseus_tag": "n-s---fa-"}},
            {"surface": "φιλίας", "msd": {"perseus_tag": "n-s---fg-"}},
        ],
    },
    {
        "lemma": "στρατός",
        "gloss": "army",
        "citation": "Demo lexicon στρατός",
        "forms": [
            {"surface": "στρατόν", "msd": {"perseus_tag": "n-s---ma-"}},
            {"surface": "στρατοῦ", "msd": {"perseus_tag": "n-s---mg-"}},
        ],
    },
]

GRAMMAR_TOPICS: list[dict[str, str]] = [
    {
        "anchor": "smyth-accuracy-001",
        "title": "Accusative of Respect (demo)",
        "body": (
            "Ὁ αἰτιατικὸς τοῦ προσώπου δηλοῖ τὸ πεδίον τῆς ἀναφορᾶς. "
            "Ἰσχύειν ἰσχὺν μέγαν, φυλάσσειν χεῖρας καθαράς, δείκνυσθαι πρόσωπον χαρίεν, "
            "σώζειν σῶμα ἀκέραιον· ταῦτα πάντα ἀποδίδωσι τὸ τίνος ἄξιον."
        ),
    },
    {
        "anchor": "smyth-accuracy-002",
        "title": "Superlative with partitive genitive (demo)",
        "body": (
            "Τὰ ὑπερθετικὰ φιλοῦσι τὴν μεριστικὴν γενικήν· σοφώτατος τῶν Ἑλλήνων, "
            "κάλλιστος τῶν παρθένων, πρῶτοι τῶν συμμάχων, τιμιώτατοι τῶν πολιτῶν."
        ),
    },
    {
        "anchor": "smyth-accuracy-003",
        "title": "Dative of cause (demo)",
        "body": (
            "Ἡ δοτικὴ δηλοῖ ἀφορμήν ἢ συνοδεύουσαν διάθεσιν· χαρᾷ λαμπρᾷ, λύπῃ βαρείᾳ, "
            "φοβῷ νυκτερινῷ, νόσῳ λοιμώδει."
        ),
    },
    {
        "anchor": "smyth-accuracy-004",
        "title": "Middle voice reflexive nuance (demo)",
        "body": (
            "Ὁ μέσος λόγος προστίθησιν ἀνταποδοτικὸν χρῶμα· οἱ στρατιῶται παρεσκευάσαντο ἑαυτούς, "
            "οἱ ἡγεμόνες διελέξαντο πρὸς τοὺς φίλους, οἱ πολῖται ἐποιήσαντο στάσιν, "
            "οἱ ναῦται ἠμύναντο τὰς ναῦς."
        ),
    },
    {
        "anchor": "smyth-accuracy-005",
        "title": "μέν ... δέ balance (demo)",
        "body": (
            "Τὸ ζεῦγος μέν ... δέ ἰσορροπεῖ τὴν διήγησιν· οἱ μὲν ἄνδρες ἔμειναν, οἱ δὲ παῖδες ἔφυγον· "
            "τοὺς μὲν φίλους ἔπεμψεν, τοὺς δὲ πολεμίους ἀπώσατο."
        ),
    },
]


async def seed_accuracy_fixtures() -> None:
    async with SessionLocal() as session:
        language_id = await ensure_language(session, "grc", "Ancient Greek")

        lex_source_id = await ensure_source(
            session,
            "accuracy-lexicon-fixtures",
            "Accuracy Lexicon Fixtures",
            {"license": "CC0"},
            {"language": "grc", "purpose": "accuracy-fixtures"},
        )
        grammar_source_id = await ensure_source(
            session,
            "accuracy-grammar-fixtures",
            "Accuracy Grammar Fixtures",
            {"license": "CC0"},
            {"language": "grc", "purpose": "accuracy-fixtures"},
        )

        work_id = await ensure_work(
            session,
            "grc",
            lex_source_id,
            "Accuracy Author",
            "Accuracy Sample Text",
            "section",
        )

        segment_ref = "accuracy.1"
        segment_text = " ".join(form["surface"] for fixture in LEXEME_FIXTURES for form in fixture["forms"])
        segment_nfc = nfc(segment_text.strip())
        segment_fold = accent_fold(segment_nfc)

        seg_row = await session.execute(
            text_with_json(
                """
                INSERT INTO text_segment(work_id, ref, text_raw, text_nfc, text_fold, meta)
                VALUES(:work_id, :ref, :raw, :nfc, :fold, :meta)
                ON CONFLICT (work_id, ref) DO UPDATE SET
                    text_raw = EXCLUDED.text_raw,
                    text_nfc = EXCLUDED.text_nfc,
                    text_fold = EXCLUDED.text_fold,
                    meta = EXCLUDED.meta,
                    updated_at = now()
                RETURNING id
                """,
                "meta",
            ),
            {
                "work_id": work_id,
                "ref": segment_ref,
                "raw": segment_nfc,
                "nfc": segment_nfc,
                "fold": segment_fold,
                "meta": {"purpose": "accuracy-fixture"},
            },
        )
        segment_id = seg_row.scalar_one()

        await session.execute(text("DELETE FROM token WHERE segment_id=:sid"), {"sid": segment_id})

        idx = 0
        for fixture in LEXEME_FIXTURES:
            lemma = nfc(fixture["lemma"])
            lemma_fold = accent_fold(lemma)
            for form in fixture["forms"]:
                surface = nfc(form["surface"])
                await session.execute(
                    text_with_json(
                        """
                        INSERT INTO token(
                            segment_id,
                            idx,
                            surface,
                            surface_nfc,
                            surface_fold,
                            lemma,
                            lemma_fold,
                            msd
                        ) VALUES (
                            :segment_id,
                            :idx,
                            :surface,
                            :surface_nfc,
                            :surface_fold,
                            :lemma,
                            :lemma_fold,
                            :msd
                        )
                        """,
                        "msd",
                    ),
                    {
                        "segment_id": segment_id,
                        "idx": idx,
                        "surface": surface,
                        "surface_nfc": surface,
                        "surface_fold": accent_fold(surface),
                        "lemma": lemma,
                        "lemma_fold": lemma_fold,
                        "msd": form.get("msd", {}),
                    },
                )
                idx += 1

        for fixture in LEXEME_FIXTURES:
            lemma = nfc(fixture["lemma"])
            await session.execute(
                text_with_json(
                    """
                    INSERT INTO lexeme(language_id, lemma, lemma_fold, data)
                    VALUES(:language_id, :lemma, :lemma_fold, :data)
                    ON CONFLICT (language_id, lemma) DO UPDATE SET
                        lemma_fold = EXCLUDED.lemma_fold,
                        data = EXCLUDED.data
                    """,
                    "data",
                ),
                {
                    "language_id": language_id,
                    "lemma": lemma,
                    "lemma_fold": accent_fold(lemma),
                    "data": {
                        "gloss": fixture["gloss"],
                        "citation": fixture["citation"],
                    },
                },
            )

        for topic in GRAMMAR_TOPICS:
            title = nfc(topic["title"])
            body = nfc(topic["body"])
            payload = {
                "source_id": grammar_source_id,
                "anchor": topic["anchor"],
                "title": title,
                "body": body,
                "body_fold": accent_fold(body),
            }
            existing = await session.execute(
                text("SELECT id FROM grammar_topic WHERE source_id=:source_id AND anchor=:anchor"),
                payload,
            )
            topic_id = existing.scalar()
            if topic_id:
                await session.execute(
                    text(
                        """
                        UPDATE grammar_topic
                        SET title=:title,
                            body=:body,
                            body_fold=:body_fold,
                            updated_at=now()
                        WHERE id=:topic_id
                        """
                    ),
                    {**payload, "topic_id": topic_id},
                )
            else:
                await session.execute(
                    text(
                        """
                        INSERT INTO grammar_topic(source_id, anchor, title, body, body_fold)
                        VALUES(:source_id, :anchor, :title, :body, :body_fold)
                        """
                    ),
                    payload,
                )

        await session.commit()


def main() -> int:
    asyncio.run(seed_accuracy_fixtures())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
