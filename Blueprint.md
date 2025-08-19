
## Strategic Technical Blueprint: Ancient Languages AI Platform

### 1. Overall Architecture

We will implement a **Containerized, Service-Oriented Architecture (SOA)**, deployed on a major cloud provider (GCP, AWS, or Azure) and orchestrated via a central API gateway.

**Justification:**

*   **AI-Centric Scalability:** AI processes (LLM inference, RAG pipelines, TTS generation) have different computational profiles than standard user management. SOA allows us to scale these independently.
*   **Robustness and Maintainability:** Isolating functionalities makes the codebase easier to manage, test, and update as new AI research emerges.
*   **Flexibility (BYOK Model):** The architecture must securely support the "Bring Your Own Key" model. The backend will act as an orchestration layer, managing the complex RAG process and applying proprietary prompt engineering, using the user's provided API key for the final LLM call.

**Core Services (Initial):**

1.  **Auth & User Service:** Manages user profiles and progress tracking.
2.  **Linguistic Kernel (The AI Brain):** The core application logic. Handles lesson generation, RAG retrieval, prompt orchestration, and interaction with external AI providers.
3.  **Data Ingestion Service:** A separate, asynchronous service responsible for processing raw linguistic data (PDFs, XML) into the knowledge base.

**Security Note on BYOK:** User API keys must be stored encrypted on the client device (using Flutter Secure Storage). They should only be transmitted to the backend in memory for the duration of an API request and **never persisted on our servers**.

### 2. SOTA Tech Stack Recommendations

#### Frontend

*   **Framework:** **Flutter** (Confirmed).
*   **Justification:** Excellent cross-platform performance (iOS, Android, Web, Desktop) from a single codebase. The declarative UI framework is well-suited for the complex interactions of a language app.
*   **Key Libraries:**
    *   `Riverpod` or `Bloc`: For robust, scalable state management.
    *   `Dio`: For advanced networking.
    *   `flutter_secure_storage`: For securely storing user API keys locally.

#### Backend

*   **Language & Framework:** **Python** + **FastAPI**.
*   **Justification:** Python is the leader in the AI/ML ecosystem. FastAPI is modern, high-performance (ASGI), and provides excellent developer experience.
*   **Key Libraries:**
    *   `LangChain` or `LlamaIndex`: Crucial frameworks for implementing RAG, managing LLM abstractions (allowing easy switching between providers), and orchestrating AI workflows.
    *   `Pydantic`: For data validation (leveraged by FastAPI).

#### Data Layer (The Knowledge Base)

This is critical for ensuring accuracy and depth. We will use a hybrid strategy.

*   **Structured Data (Users, Progress, Structured Lexicons):** **PostgreSQL**. Reliable and feature-rich.
*   **Linguistic Knowledge Base (RAG):** **PostgreSQL with the `pgvector` extension**.
*   **Justification:** `pgvector` allows for efficient vector similarity search. Starting with it simplifies the initial stack by consolidating databases. As the corpus grows, we can migrate to a dedicated vector database (like Qdrant or Weaviate) if performance demands it.

#### AI Services

*   **Core LLM:** Models with exceptional reasoning capabilities are required.
    *   **Primary:** Anthropic's **Claude 3 Opus** (for maximum accuracy and nuance) or **Claude 3.5 Sonnet** (excellent balance of speed/intelligence).
    *   **Secondary:** OpenAI's **GPT-4o**.
*   **Embeddings (for RAG):** OpenAI's `text-embedding-3-large` or robust open-source models like `BAAI/bge-large-en-v1.5`.
*   **SOTA Text-to-Speech (TTS):** **ElevenLabs**. They offer the most natural TTS and crucial fine-tuning capabilities essential for reconstructing hypothesized pronunciations of ancient languages.

### 3. Data Strategy for Classical Greek

The quality of the AI tutor depends entirely on the quality of the data. We must build a "Ground Truth Corpus" from definitive scholarly sources.

#### Priority Sources

1.  **Grammar:** Smyth's *Greek Grammar* (the standard reference).
2.  **Lexicon:** Liddell-Scott-Jones (LSJ) Lexicon.
3.  **Corpora/Texts:** The **Perseus Digital Library**. Perseus provides TEI (Text Encoding Initiative) XML data for vast amounts of classical texts, including morphological analysis. This is a goldmine.
4.  **Pedagogical Texts:** Ingesting recognized textbooks (e.g., *Athenaze*) will help the AI understand modern pedagogical approaches.

#### Data Pipeline (Ingestion Workflow)

1.  **Acquisition:** Download PDFs/books, or use scripts to pull XML data from Perseus.
2.  **Extraction & Parsing:**
    *   *PDFs:* Use advanced tools (`PyMuPDF`) or LLM-powered extraction (e.g., Vision models) to convert PDFs into structured Markdown.
    *   *XML (Perseus):* Write custom Python parsers (`lxml` or `BeautifulSoup`) to extract text, metadata, and morphology from TEI XML.
3.  **Normalization:**
    *   **Critical Step:** Normalize Unicode (NFC) for Greek characters. Consistent handling of polytonic Greek diacritics is vital for accurate embedding and search.
4.  **Semantic Chunking:** Break data down logically by grammatical topic or lexicon entry, not arbitrary character counts.
5.  **Embedding & Indexing:** Generate vector representations using the embedding model and load them into `pgvector`, ensuring rich metadata (source, topic, language) is attached.

### 4. Phased Development Roadmap for the MVP (Classical Greek)

We will follow a foundational approach, ensuring the AI engine is robust before focusing heavily on the UI.

#### Milestone 1: Backend Foundation and Data Ingestion (Weeks 1-3)

*   **Objectives:** Set up core infrastructure and process the first major data source.
*   **Deliverables:**
    *   FastAPI backend initialized (Auth and Linguistic Kernel services).
    *   PostgreSQL database with `pgvector` configured.
    *   Docker configuration for all services.
    *   Data Ingestion pipeline V1 complete.
    *   Smyth's Grammar and LSJ Lexicon fully ingested, normalized, chunked, and indexed.

#### Milestone 2: The RAG Engine and Core Tutoring Logic (Weeks 4-6)

*   **Objectives:** Implement the AI logic for accurate Q&A and lesson generation.
*   **Deliverables:**
    *   RAG implementation using LangChain/LlamaIndex, utilizing Hybrid Search (see Section 5).
    *   Vector similarity search endpoint functional.
    *   Core prompt engineering templates for: (a) Explaining concepts, (b) Generating exercises, (c) Evaluating user input.
    *   LLM abstraction layer to handle different providers and BYOK integration.

#### Milestone 3: Flutter UI and Interactive Tutoring (Weeks 7-9)

*   **Objectives:** Build the primary user interface and connect it to the AI backend.
*   **Deliverables:**
    *   Flutter project setup with state management (Riverpod/Bloc).
    *   User authentication flow and secure API key input screen.
    *   Core lesson interface (displaying explanations, interactive exercises).
    *   Basic user progress tracking.

#### Milestone 4: The Interactive Reader (Weeks 10-11)

*   **Objectives:** Provide a tool for reading authentic ancient texts with AI assistance.
*   **Deliverables:**
    *   Ingestion of a target text (e.g., Book 1 of the *Iliad*) using Perseus data.
    *   Reader UI in Flutter with correct polytonic Greek rendering.
    *   "Tap-to-Analyze" feature: Tapping a word retrieves its morphological data (from Perseus) and its definition (RAG query to LSJ).

#### Milestone 5: SOTA TTS and Polish (Week 12)

*   **Objectives:** Integrate high-quality audio and finalize the MVP.
*   **Deliverables:**
    *   Integration with ElevenLabs API.
    *   Development of a "pronunciation profile" for Classical Greek (e.g., Erasmian or Reconstructed Attic).
    *   Ability to generate audio for vocabulary and sample sentences.

### 5. SOTA AI Integration Strategy

#### The Imperative of RAG (Retrieval-Augmented Generation)

For ancient languages, accuracy is non-negotiable. RAG ensures the AI acts as an intelligent interpreter of expert knowledge (our indexed scholarly sources), rather than generating answers from its generalized training data.

*   **Advanced RAG Implementation:**
    *   **Hybrid Search:** Combine semantic (vector) search with keyword search (e.g., BM25). This improves precision, especially with specific linguistic terminology (e.g., searching for "Aorist Passive").
    *   **Re-ranking:** After initial retrieval, use a cross-encoder model to re-rank the results for maximum relevance before passing them to the LLM.

#### Advanced Prompting Strategies

1.  **Rigorous Persona Definition:** Define the AI as an expert classicist (e.g., "You are an Oxford Don specializing in Homeric Greek. You are rigorous, encouraging, and always refer to grammatical authorities.").
2.  **Chain-of-Thought (CoT) Reasoning:** For complex tasks like parsing a sentence, prompt the LLM to show its work (e.g., "Step 1: Identify the main verb. Step 2: Analyze its morphology..."). This improves accuracy and pedagogy.
3.  **Dynamic Context Management:** The system must maintain the context of the lesson, the student's proficiency level, and recent mistakes to tailor the instruction dynamically.

#### "Moonshot" AI Features for the MVP

1.  **Context-Aware Socratic Dialogue Simulator:** An AI agent trained specifically to engage in dialogue *in Classical Greek*. It adopts a persona (e.g., Socrates) and engages the user in philosophical or daily life discussion, dynamically adjusting complexity based on the user's capabilities.
2.  **AI-Powered Phonological Reconstruction Simulation:** Use the LLM to generate precise IPA (International Phonetic Alphabet) representations based on different scholarly theories of pronunciation (e.g., Erasmian vs. Reconstructed Attic). Feed this IPA directly into ElevenLabs to generate comparative audio simulations.

### 6. Future-Proofing and Scalability

The goal is to make adding Koine Greek, Latin, or Sumerian seamless.

#### Standardized Linguistic Data Schema (LDS)

The most critical element for scalability is abstracting the data structure. We must design a standardized schema from day one that can represent the features of *any* language.

*   **Schema Components:** Standardized fields for Lexicons, a structured format (JSON/YAML) for defining Morphological rules (inflections, conjugations), and indexed Grammar/Syntax data.
*   **Strict Metadata Filtering:** In the Vector DB (`pgvector`), every entry must be tagged with its language code (e.g., `grc`, `lat`). All RAG queries must filter for the current language to prevent "bleed-over."

#### Towards Automated Language Onboarding

The long-term vision of AI automatically onboarding new languages requires a shift to **AI-driven Information Extraction**.

*   **Foundational Elements Needed Now:**
    1.  **The LDS (as above):** The AI needs a clear target structure to populate.
    2.  **A Robust Feedback Loop:** Implement mechanisms for expert linguists to correct the AI's outputs. This Human-in-the-Loop (HITL) data is invaluable for fine-tuning.
    3.  **Focus on Interlinear Data:** Prioritize the ingestion of interlinear texts (texts with word-by-word analysis). This is the gold standard for training NLP models to understand the structure of a new language.
