# Thesis Writing Plan — Hydro Platform (AI Instructions)

## Context

This plan is a guide for an AI assistant writing the master's thesis of Bc. Jakub Sikula at the Faculty of Informatics, Masaryk University (FI MUNI). The thesis is an **implementation-type** work describing three software repositories: `tsm-orchestration`, `water-dp`, and `hydro-deploy`. The LaTeX skeleton with chapter files already exists in `hydro-text/dp-text/chapters/`. This plan governs how to fill those files with real content.

---

## 1. Formal Requirements (FI MUNI)

| Item | Requirement |
|---|---|
| **Target length** | 50–70 standard pages (1 page = 1,800 characters); minimum 30 pages |
| **Own contribution share** | > 70% of total scope (background/theory ≤ 30%) |
| **Language** | English throughout |
| **Citations** | ISO 690:2022 standard; bibtex key format in `thesis.bib` |
| **Font / layout** | Handled by fithesis4 — do not override |
| **Required sections** | Authorship declaration, AI tools disclosure, abstract, keywords, TOC, introduction, core chapters, conclusion, bibliography |
| **Figures** | Caption below, `\emph{Source: author}` or real source. Minimum 100 px/cm for raster images |
| **Tables** | Caption above (floatrow already configured), `\emph{Source: author}` if original |
| **Citations in text** | `\parencite{key}` for parenthetical; `\textcite{key}` for inline author mention |

---

## 2. Code Verification Rule (Critical)

> **Before writing any sentence that describes implementation, design, or architecture — verify it against the actual source code.**

This rule applies to every chapter but is most critical in Chapters 4 and 5. The plan file and the session summaries contain a best-effort reconstruction of the codebase from exploration, but they are not authoritative. The code is authoritative.

**What must be verified before writing:**

| Claim type | How to verify |
|---|---|
| File/module exists | `Glob` or `Read` the actual path |
| Function or class exists | `Grep` for the name in the repo |
| A service does X | `Read` the service file and confirm the logic |
| A worker listens to topic Y | `Read` the worker file and find the subscription |
| A table has column Z | `Read` the Alembic migration or SQLAlchemy model |
| Version number | `Read` `pyproject.toml` or `package.json` |
| MQTT topic name | `Grep` for the topic string in the codebase |
| A feature was replaced/removed | `Grep` for the old code to confirm it's gone |
| A TSM-TEMP item | `Grep` for `TSM-TEMP` in the relevant file |

**When writing a section:**
1. Read the relevant source files first (`Read` tool on actual paths)
2. Write the description based on what the code actually does
3. If the code contradicts the plan, trust the code — update the thesis accordingly

**Never write:**
- *"The service uses X"* based only on the plan or session summary
- Version numbers from memory — always read from `pyproject.toml` / `package.json`
- File paths that haven't been confirmed to exist with `Glob`/`Read`

---

## 3. Tone and Language Style

### The target register: "Technical professional — clear and direct"

Think of a well-written engineering blog post or RFC document, not a journal paper. The text should be readable by a technical person who is not an expert in the exact domain (environmental monitoring), but should never sound casual or journalistic.

### Rules

**Voice and person:**
- Use **impersonal / passive** constructions as the default: *"the platform was designed to…"*, *"the service is responsible for…"*
- Use *"this thesis"*, *"this work"*, *"the author"* when referring to the contribution
- Never use *"I"*, *"we"* (unless quoting a multi-author source), *"you"*, *"our team"*

**Precision over decoration:**
- State facts directly; no metaphors, no journalistic flair
- ✅ *"The SMS service was non-functional at the time of this work."*
- ❌ *"The SMS service was basically broken and nobody had fixed it."*
- One idea per sentence; avoid sentences over 35 words

**Terminology consistency:**
- Use one term consistently for the same concept throughout: **Thing** (not sensor/device/entity interchangeably), **Datastream** (not channel/stream), **Observation** (not measurement/reading)
- Introduce abbreviations once: *"OGC SensorThings API (STA)"*, then use STA
- Key abbreviations to introduce on first use: STA, FROST, TSM, MQTT, OIDC, RBAC, WMS, WFS, QC, QA/QC

**Verb tense:**
- Present tense for describing the system as it exists: *"The API exposes…"*, *"The worker subscribes to…"*
- Past tense for design decisions and implementation steps: *"The alert evaluator was redesigned to use MQTT triggers…"*

**Section transitions:**
- Each chapter should begin with a short paragraph naming its sections (already scaffolded in the LaTeX)
- Each section should end with a sentence bridging to the next, or close by summarising what was established

**What to avoid:**
- "It is worth noting that…" (just say it)
- "As mentioned above/below" — use `\ref{}` cross-references instead
- "Obviously", "clearly", "of course" — nothing is obvious to the reader
- Starting a sentence with "So,", "Also,", "And," — rewrite
- Redundant phrases: "in order to" → "to"; "due to the fact that" → "because"

---

## 4. Chapter-by-Chapter Writing Instructions

### Introduction (`01-introduction.tex`)

**Status: draft text already present — can refine but mostly done**

- ~1–1.5 pages
- Establish: the problem (heterogeneous sensor data at CZU), the approach (adapt UFZ Time.IO), the dual goal (CZU + eLTER)
- End with a clear paragraph listing what each subsequent chapter covers (already written)
- No citations needed here except possibly one for CZU or eLTER as institutions

---

### Chapter 2 — Background (`02-background.tex`)

**Goal: give the reader exactly what they need to understand the rest. Nothing more.**

Keep this chapter tight — it is background, not a survey. Each section should answer "why does the reader need to know this?"

**Section 2.1 — Environmental Sensor Data Management**
- 1–2 pages
- Describe the generic challenge: heterogeneous sensors, multiple protocols (MQTT, HTTP, SFTP, file), time-series at scale, interoperability
- Mention 2–3 real platforms or standards as context (can cite OGC STA, ODM2, ERDDAP, or similar)
- Close: *"This thesis addresses this challenge in the context of the CZU deployment, described in Chapter 3."*

**Section 2.2 — OGC SensorThings API and FROST**
- 2–3 pages
- Describe the STA data model: Thing → Datastream → Observation, plus Sensor, ObservedProperty, FeatureOfInterest, Location
- Explain FROST-Server: Java, Tomcat, PostgreSQL backing store
- Include a small diagram or table of the entity model if possible
- Explain why STA was chosen for this platform (interoperability, vendor-neutral access)

**Section 2.3 — UFZ Time.IO**
- 3–4 pages — this is the most important background section
- Describe the architecture: dispatcher, workers (configdb-updater, thing-setup, file-ingest, mqtt-ingest, run-qaqc, sync-extapi, sync-extsftp)
- Explain per-thing schema provisioning (each sensor gets its own PostgreSQL schema with observation hypertable)
- Describe what SMS was supposed to do and why it was non-functional
- Be direct and honest: *"At the time of this work, the upstream SMS service was not operational, and the project showed limited development activity."* This is critical context for all architectural decisions in Chapter 4.
- Describe the TSM-TEMP workaround label and what it means in the codebase

**Section 2.4 — Institutional Context (eLTER/UFZ engagement)**
- 1 page
- Explain Time.IO was not selected through open competition — it came from eLTER/UFZ engagement
- This section justifies why the thesis works with Time.IO at all

**Section 2.5 — eLTER**
- 1 page
- Describe eLTER network, long-term ecosystem monitoring, European scope
- Note their data integration requirements as they relate to the platform

---

### Chapter 3 — Requirements (`03-requirements.tex`)

**Goal: derive what was needed, show what was missing, drive the scope of Chapters 4–5**

**Section 3.1 — CZU Use Cases**
- Describe CZU's actual monitoring setup: river gauging stations, catchment networks, multiple sensor manufacturers
- Primary use cases: MQTT online ingestion, offline CSV/SFTP batch upload, project-centric management, RBAC for research groups, visualisation, alerts, geospatial display
- Can write these as numbered use cases (UC-1, UC-2...) or as prose — prose is fine for a 50-70 page thesis

**Section 3.2 — Functional Requirements**
- Enumerate by area (a) through (h) as per syllabus
- Keep requirements short and precise: *"FR-7: The system shall allow uploading historical observation data as CSV files and parsing them using a configurable parser."*
- 8 areas: ingestion, sensor management, project management, quality, visualisation, auth, batch import, multilingual UI

**Section 3.3 — Non-Functional Requirements**
- Containerised deployment (Docker + Podman rootless), response time, OGC STA compliance, OIDC, maintainability, eLTER interoperability alignment

**Section 3.4 — Gap Analysis**
- The table is already in the LaTeX skeleton — fill in the description
- For each gap, explain *why* it is a gap (what Time.IO lacks and what the requirement demands)
- This section directly motivates every component described in Chapters 4–5

---

### Chapter 4 — Architecture (`04-architecture.tex`)

**Goal: explain WHY things are structured as they are, not just WHAT they are**

This is the most conceptually important chapter. Every design decision needs a one-sentence justification.

**Section 4.1 — Overall Architecture**
- Describe the three-component split: `tsm-orchestration` (infrastructure layer), `water-dp` (application layer), `hydro-deploy` (deployment layer)
- Key point: both stacks remain independently deployable; `hydro-deploy` is optional
- A figure showing the three boxes with arrows (REST, MQTT, direct DB) is essential here — create or note as TODO
- Mention the `hydro-platform-net` bridge network connecting both stacks

**Section 4.2 — Component Responsibilities**
- `tsm-orchestration`: owns raw time-series storage, per-thing schema provisioning, data ingestion, FROST access
- `water-dp`: owns application concepts (projects, alerts, geospatial) and user portal
- `hydro-deploy`: owns nothing at runtime — only assembly and configuration
- Explicitly justify keeping the two stacks separate: allows TSM to be replaced or upgraded independently

**Section 4.3 — Database Design**
- Describe the two deployment variants (shared PostgreSQL vs separate instances)
- In the shared variant: `public` schema for TSM config, per-thing schemas for time-series data, `water_dp` schema for application state
- Describe the per-thing schema pattern: one schema per sensor, observation table as TimescaleDB hypertable (chunk by week, auto-compress after 3 months)
- Mention the `water_dp` schema tables: `projects`, `project_members`, `project_sensors`, `alert_definitions`, `alerts`, `computation_scripts`, `computation_jobs`, `geo_layers`, `layer_assignments`
- Explain local STA views: PostgreSQL views in `sta_views_local/` provide FROST with a unified entity view over per-thing schemas

**Section 4.4 — MQTT Event Architecture**
- MQTT is the integration backbone — explain the topic structure
- Key topics: `frontend_thing_update`, `configdb_update`, `mqtt_ingest/{username}/data`, `object_storage_notification`, `data_parsed`
- Trace the lifecycle of a Thing from creation to data availability (Thing created → configdb-updater → thing-setup → schema provisioned)
- Alert evaluation change: replaced Celery Beat periodic polling with MQTT-triggered evaluation — motivate this: lower latency, event-driven, avoids polling overhead

**Section 4.5 — Technology Justifications**
This section is **required by FI MUNI**. For each choice, write 2–3 sentences: what it does, why it was chosen over alternatives.

| Technology | Key justification points |
|---|---|
| FastAPI | Async Python, automatic OpenAPI docs, Pydantic validation — preferred over Flask (no async) and Django (too heavy) |
| Next.js 15 App Router | React Server Components + SSR for auth-protected routes, built-in i18n, file-based routing — preferred over plain React (no SSR) or Vue (smaller ecosystem for complex apps) |
| TimescaleDB | Native hypertables on PostgreSQL (no new infrastructure), automatic chunking and compression — preferred over InfluxDB (separate system, different query language) |
| GeoServer | Standards-compliant WMS/WFS over PostGIS, proven in research institutions — preferred over alternatives as it speaks OGC standards matching the STA philosophy |
| Keycloak | Battle-tested OIDC provider, realm/client model supports multi-tenant RBAC, already present in Time.IO stack |
| MinIO | S3-compatible, self-hosted (no cloud dependency), per-thing buckets with lifecycle policies |

**Section 4.6 — Deployment Strategy**
- Four Compose files merged via Docker Compose `-f` flag
- Single `.env` with `@sync` markers for cross-stack variables
- Makefile targets: `setup`, `secrets`, `build`, `up`, `migrate`, `seed`, `check`
- Podman support: `podman_prep.py` transforms compose files (converts env list to dict, removes disabled service references)
- Cloudflare Tunnel optional integration

---

### Chapter 5 — Implementation (`05-implementation.tex`)

**Goal: describe what was built and how, with enough detail for a reader to understand the code structure without reading every file**

This is the longest chapter. Reference actual file paths and function names — this is an implementation thesis.

**Section 5.1 — TSM Adaptations**

Key subsections:
- **Local STA views**: Describe the PostgreSQL view layer (`sta_views_local/`). Explain what FROST expects and how the views provide it. Name the views and their source tables.
- **Compose modularisation**: Describe adding `docker-compose-water-dp.yml` overlay and modular structure
- **Worker architecture**: Describe the dispatcher/scheduler pattern. For each worker, 2–3 sentences: input (MQTT topic), output (DB write / MQTT event), key logic. Workers: configdb-updater, thing-setup, file-ingest, mqtt-ingest, run-qaqc, sync-extapi, sync-extsftp
- **Parser framework**: Describe abstract base class + implementations (CSV, JSON, MQTT, Pandas) + device-specific parsers (ChirpStack, Campbell CR6)
- **TSM-TEMP assessment**: Be direct: *"Given the stagnation of the upstream project, these workarounds are unlikely to be resolved by upstream activity. A targeted rewrite of the affected components is the more defensible long-term approach."*

**Section 5.2 — water-dp Backend**

Structure:
- Project layout: describe `app/api/v1/endpoints/`, `app/services/`, `app/models/`, `app/schemas/` — one paragraph each
- SQLAlchemy 2.0 async patterns: mention `async_sessionmaker`, `AsyncSession`, Alembic migrations
- FROST API client: `services/timeio/frost_client.py` and `async_frost_client.py` — explain synchronous vs async variants
- Alert evaluation: `alert_evaluator.py` — describe the MQTT subscription, rule evaluation loop, state machine (active → acknowledged → resolved)
- GeoServer integration: `geoserver_service.py` REST API calls for layer creation
- Keycloak integration: `keycloak_service.py` token validation, `python-keycloak` library, RBAC roles
- Mention each endpoint module briefly — a table with module name + one-line description is appropriate here

**Section 5.3 — water-dp Frontend**

Structure:
- Next.js 15 App Router: explain SSR + RSC usage, protected layout pattern (`/projects/layout.tsx`)
- Key pages: list them with purpose (projects, sms/sensors, layers, settings, register)
- Key components: SensorCreateDialog (bulk form), BulkImportDialog (CSV upload + results), ProjectMap (MapLibre GL), TimeSeriesChart (Recharts)
- Authentication: NextAuth + Keycloak OIDC, token forwarded to API as Bearer header
- State: Zustand for global UI state (current project, selected sensor), React Query for server state
- i18n: locale files in `frontend/locales/`, `en.ts`, `cs.ts`, and `sk.ts`, middleware-based locale detection
- Simulator: fake sensor data generation without physical hardware

**Section 5.4 — hydro-deploy**

Structure:
- Compose multi-file merge: explain the 4-file chain and what each layer contributes
- `.env` + symlinks: one file, credentials consistent, `@sync` markers
- `podman_prep.py`: describe the two transformations it makes (env list → dict; remove disabled services)
- Makefile targets: describe `make setup`, `make secrets`, `make build`, `make up`, `make migrate`, `make check` individually
- Rootless Podman specifics: UID/GID passing, network pre-creation in `podman-prep.sh`, GeoServer UID fix

---

### Chapter 6 — Testing and Evaluation (`06-testing.tex`)

**Goal: show that the platform actually works and meets the requirements**

**Section 6.1 — Testing Approach**
- pytest integration tests for water-dp backend — real PostgreSQL, not mocked
- Justify: *"Mock-based testing was deliberately avoided given the tight coupling to PostgreSQL-specific features (per-thing schema isolation, TimescaleDB hypertables) and prior experience where mock/production divergence masked integration errors."*
- Manual end-to-end testing procedures

**Section 6.2 — Requirements Evaluation**
- Go through the requirements table from Chapter 3 row by row
- The table in the LaTeX skeleton already has the right rows — fill in the Notes column with evidence (screenshot reference, test name, or 1-sentence description)

**Section 6.3 — Performance**
- TimescaleDB chunk-based storage — explain why time-range queries are efficient
- Async FastAPI + async SQLAlchemy throughput characteristics
- Known bottleneck: FROST queries (synchronous Java, not async); mitigation: async_frost_client for non-blocking calls

**Section 6.4 — CZU Deployment and eLTER Path**
- Document the actual CZU deployment environment (hardware/OS/network — whatever you know)
- eLTER path: which components are already general-purpose, what would be needed (eLTER metadata schemas, cross-site federation, additional auth requirements)
- TSM-TEMP sustainability: repeat the argument — rewrite, not wait for upstream

---

### Chapter 7 — Conclusion (`07-conclusion.tex`)

**Status: draft already present — needs expansion**

- Summarise the 3 contributions as numbered items (already in the draft)
- Limitations section: 3–4 paragraphs — TSM-TEMP workarounds, test coverage gaps, eLTER not yet deployed, performance not benchmarked at scale
- Future Work: rewrite non-functional TSM components, eLTER extension layer, advanced QA/QC, performance tuning, full automated test coverage
- Closing paragraph: reflect on OGC STA as the right standard choice

---

## 5. Cross-Cutting Writing Rules

### Referring to the codebase

- Always give the **file path** when first describing a module: *"The alert evaluator (`water-dp/api/app/services/alert_evaluator.py`) subscribes to…"*
- Use `\texttt{module_name.py}` in LaTeX for file/function names
- Do not paste large code blocks. For short illustrative snippets (< 20 lines), use `lstlisting`. For longer code, reference the appendix.
- When describing a design pattern, name it: *"…follows the Observer pattern"*, *"…uses a Strategy pattern for parser selection"*

### Figures and diagrams

- Every major architecture decision needs a figure (the ones marked as placeholder in the skeleton)
- Minimum required figures:
  1. High-level three-component architecture (Chapter 4.1)
  2. Per-thing database schema ER diagram (Chapter 4.3)
  3. MQTT event flow sequence diagram (Chapter 4.4)
  4. water-dp backend layer diagram (Chapter 5.2)
  5. Screenshot of the portal (Chapter 5.3) — count as evidence in Chapter 6
- All figures: `\emph{Source: author}` unless from elsewhere

### Numbers and technical claims

- Back every performance claim with a measurement or a citation
- For implementation counts (e.g., "15 endpoint modules, 17 router registrations"), verify against the actual codebase — the numbers in this plan come from repo exploration and should be confirmed
- Version numbers: Python 3.11, FastAPI 0.115.14, Next.js 15.5.14, etc. — get from `pyproject.toml` and `package.json`

### What to describe vs. what to skip

**Describe in detail:**
- Anything that represents the author's own design decision
- Anything where the implementation deviates from the upstream (TSM-TEMP items)
- The MQTT-driven alert system (original contribution replacing Celery Beat)
- The Podman rootless support implementation
- The local STA views approach

**Describe briefly:**
- Standard library usage (SQLAlchemy patterns, Alembic migrations)
- Third-party services used as-is (MinIO, Keycloak configuration)

**Skip or mention only in passing:**
- Obvious boilerplate (Docker Compose volume mounts, nginx config details)
- Code that directly follows framework conventions without novel logic

---

## 6. Bibliography (`thesis.bib`) Instructions

**Placeholder entries** in `thesis.bib` must be replaced with real entries before submission. Priority order:

1. OGC SensorThings API spec (OGC standard document)
2. FROST-Server paper or GitHub (Hylke van der Schaaf, Fraunhofer IOSB)
3. UFZ Time.IO — if there is a published paper, use it; otherwise cite the GitLab repo
4. eLTER RI — cite the official eLTER documentation or a relevant paper
5. TimescaleDB — white paper or technical documentation
6. FastAPI, Next.js, Keycloak — cite official documentation (acceptable for software tools)
7. Any environmental monitoring background papers cited in Chapter 2

Use `\parencite{key}` for all citations (ISO 690 numeric style via biblatex-iso690). Never use raw `\cite{}` for standard text citations.

---

## 7. File Structure (Current State)

```
hydro-text/dp-text/
├── fi-lualatex.tex         ← main file (preamble + \input chain)
├── fi-pdflatex.tex         ← identical structure, pdfLaTeX variant for Overleaf
├── thesis.bib              ← bibliography (TODO entries need replacing)
├── fithesis4.cls           ← document class (do not modify)
├── fithesis/               ← fithesis style files (do not modify)
└── chapters/
    ├── 01-introduction.tex ← ~done, may need light revision
    ├── 02-background.tex   ← skeleton + TODO comments
    ├── 03-requirements.tex ← skeleton + gap table
    ├── 04-architecture.tex ← skeleton + figure placeholder
    ├── 05-implementation.tex ← skeleton, most detailed TODO
    ├── 06-testing.tex      ← skeleton + evaluation table
    └── 07-conclusion.tex   ← draft present, needs expansion
```

**Compilation:**
```bash
cd hydro-text
make lua      # LuaLaTeX — for local development (recommended)
make pdf      # pdfLaTeX — matches Overleaf compiler
make open     # open result PDF
make clean    # remove build artifacts
```

---

## 8. Checklist Before Submission

- [ ] Abstract: 150–250 words, in English; mentions problem, approach, key results
- [ ] Keywords: 5–8 specific terms (sensor data, MQTT, OGC SensorThings API, FastAPI, Next.js, TimescaleDB, Keycloak, environmental monitoring)
- [ ] All TODO comments in chapter files are replaced with real content
- [ ] All `TODO-*` bibliography entries replaced with real citations
- [ ] All figure placeholders replaced with real figures
- [ ] All `\label{}` references resolve (no `??` in PDF)
- [ ] All tables have captions above and source attribution
- [ ] Page count: 50–70 standard pages
- [ ] Background/theory chapters (Ch. 2, Ch. 3) ≤ 30% of total length
- [ ] `make lua` compiles with zero `!` errors (warnings OK)
- [ ] AI tools disclosure section present (FI MUNI requirement since 2023)
