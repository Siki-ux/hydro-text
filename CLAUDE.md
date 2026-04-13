# Claude AI Instructions — Hydro Platform Thesis

This file provides instructions for Claude AI when assisting with the master's thesis of **Bc. Jakub Sikula** at the Faculty of Informatics, Masaryk University (FI MUNI).

The full writing plan is in [WRITING_PLAN.md](WRITING_PLAN.md). Read it before doing any writing work.

---

## Thesis at a Glance

| Field | Value |
|---|---|
| **Author** | Bc. Jakub Sikula |
| **Type** | Master's thesis (mgr) |
| **Faculty** | Faculty of Informatics, Masaryk University (FI MUNI) |
| **Department** | Department of Software Engineering |
| **Advisor** | RNDr. Tomáš Rebok, Ph.D. |
| **Title** | Design and Implementation of a Platform for Real-Time Environmental Sensor Data Collection, Integration, and Visualisation |
| **Thesis type** | Implementation work |

---

## Repository Layout

```
hydro-text/
├── CLAUDE.md               ← you are here
├── WRITING_PLAN.md         ← full AI writing instructions and style guide
├── syllabus.md             ← chapter-by-chapter content outline
├── Makefile                ← build targets (make lua / make pdf / make clean)
└── dp-text/
    ├── fi-lualatex.tex     ← main file (LuaLaTeX — use for local builds)
    ├── fi-pdflatex.tex     ← main file (pdfLaTeX — matches Overleaf)
    ├── thesis.bib          ← bibliography (TODO entries must be replaced)
    ├── fithesis4.cls       ← FI MUNI document class (do not modify)
    ├── fithesis/           ← fithesis style files (do not modify)
    └── chapters/
        ├── 01-introduction.tex
        ├── 02-background.tex
        ├── 03-requirements.tex
        ├── 04-architecture.tex
        ├── 05-implementation.tex
        ├── 06-testing.tex
        └── 07-conclusion.tex
```

The three code repositories described in the thesis are siblings of this repo:

```
~/sources/dp/
├── hydro-text/          ← this repo (thesis text)
├── water-dp/            ← FastAPI backend + Next.js frontend
├── tsm-orchestration/   ← adapted UFZ Time.IO stack (heavily modified fork)
└── hydro-deploy/        ← unified deployment orchestrator
```

### Upstream UFZ TSM Ecosystem

The local `tsm-orchestration` is a **heavily modified** fork of the upstream UFZ TSM project.
The original upstream lives at: https://codebase.helmholtz.cloud/ufz-tsm

Key upstream repositories (for reference — do NOT confuse with our local code):

| Repository | URL | Tech | Status at time of thesis |
|---|---|---|---|
| **tsm-orchestration** | `ufz-tsm/tsm-orchestration` | Docker Compose, Python workers | 1,628 commits, 14 releases. Core ingestion pipeline — what we forked. |
| **tsm-frontend** | `ufz-tsm/tsm-frontend` | Django 4.x, Python | 465 commits. Original Thing management UI. Buggy MQTT messages broke ingestion. |
| **thing-management** | `ufz-tsm/thing-management` | FastAPI (backend), Vue.js 3 + Quasar (frontend) | ~136 commits total (Sep 2024). Newer replacement for tsm-frontend. Still early, similar bugs. |
| **timeio-and-sms** | `ufz-tsm/timeio-and-sms` | Docker Compose bundle | 175 commits (May–Jul 2024). Combined SMS + Time.IO deployment. Impossible to start — broken deps & bugs. |
| **SMS** | Helmholtz Hub Terra (external) | — | Non-functional. SMS backend not operational. Local STA views (TSM-TEMP) bypass it. |

**Published paper:** Bumberger et al., "Digital ecosystem for FAIR time series data management in environmental system science", *SoftwareX* 29, 2025. DOI: `10.1016/j.softx.2025.102038`

**Critical context for writing:** Our `tsm-orchestration` differs significantly from upstream. Always verify against local code, never assume upstream docs apply.

---

## Build Commands

```bash
make lua        # Build PDF with LuaLaTeX (recommended for local work)
make pdf        # Build PDF with pdfLaTeX (matches Overleaf compiler)
make open       # Open the LuaLaTeX PDF
make open-pdf   # Open the pdfLaTeX PDF
make clean      # Remove build artifacts, keep PDFs
make clean-all  # Remove build artifacts and PDFs
```

Full compile sequence (done automatically by `make lua`):
```
lualatex fi-lualatex.tex → biber fi-lualatex → lualatex × 2
```

---

## Critical Rules

### 1. Verify before writing

**Every claim about implementation, design, or architecture must be verified against actual source code before being written into the thesis.**

- File exists? → `Glob` or `Read` the path
- Function/class exists? → `Grep` for it
- A service does X? → `Read` the service file
- Worker subscribes to topic Y? → `Read` the worker file, find the subscription
- Table has column Z? → `Read` the Alembic migration or SQLAlchemy model
- Version number? → `Read` `pyproject.toml` or `package.json`
- MQTT topic name? → `Grep` for the string

Trust the code. If code contradicts the plan, trust the code.

### 2. LaTeX conventions

- Citations: `\parencite{key}` (parenthetical), `\textcite{key}` (inline author)
- File/function names in text: `\texttt{filename.py}`
- Cross-references: always `\ref{label}` — never "as mentioned above"
- Figure captions: below figure, include `\emph{Source: author}`
- Table captions: above table (floatrow handles this), include `\emph{Source: author}`
- Code listings: use `lstlisting` environment for snippets under 20 lines

### 3. Language and style

- Impersonal / passive voice: *"the platform was designed to…"*, *"the service is responsible for…"*
- Never: "I", "we", "our", "you"
- Refer to the thesis as: *"this thesis"*, *"this work"*, *"the author"*
- Present tense for system descriptions, past tense for design decisions
- One idea per sentence; max ~35 words per sentence
- Introduce abbreviations once on first use: STA, FROST, TSM, MQTT, OIDC, RBAC, WMS, WFS, QC

### 4. FI MUNI formal requirements

- Target length: 50–70 standard pages (1 page = 1,800 chars); own contribution > 70%
- Background/theory chapters ≤ 30% of total
- ISO 690:2022 citations throughout
- AI tools disclosure section required

---

## Terminology

Use these terms consistently — do not mix synonyms:

| Concept | Use this term | Not these |
|---|---|---|
| A physical sensor device | **Thing** | device, node, entity (\"sensor\" is acceptable in generic domain contexts like \"sensor data management\") |
| A measured property's time-series | **Datastream** | channel, stream, series |
| A single measurement | **Observation** | measurement, reading, data point |
| The TSM schema per sensor | **per-thing schema** | sensor schema, thing schema |
| The UFZ stack | **tsm-orchestration** or **TSM** | Time.IO (ok in background chapter) |
| The application layer | **water-dp** | water-dp-api, water platform |
| The deployment repo | **hydro-deploy** | deployment repo |
| OGC SensorThings API | **STA** (after introduction) | SensorThings, OGC API |
| The FROST implementation | **FROST** or **FROST-Server** | Frost, frost server |

---

## Decommissioned Features

The following features were originally planned but have been **decommissioned** and removed from the requirements:

- **Computations (UC-16, G-10):** The sandboxed Python computation framework (upload and execute scripts against Datastream data) was decommissioned. UC-16 has been removed from the use case diagrams, use case table, and gap analysis. Any remaining references in functional/non-functional requirements should be ignored or removed.
- **Custom dashboards (FR-18):** The drag-and-drop custom dashboard feature was decommissioned. FR-18 has been removed from the functional requirements. Note: Grafana dashboards (part of TSM's built-in infrastructure) remain; only the water-dp custom dashboard builder was dropped.

---

## Chapter Status

| Chapter | File | Status |
|---|---|---|
| Introduction | `01-introduction.tex` | Draft — may need light revision |
| Background | `02-background.tex` | Skeleton + TODO comments |
| Requirements | `03-requirements.tex` | Skeleton + gap table |
| Architecture | `04-architecture.tex` | Skeleton + figure placeholders |
| Implementation | `05-implementation.tex` | Skeleton — most work remaining |
| Testing | `06-testing.tex` | Skeleton + evaluation table |
| Conclusion | `07-conclusion.tex` | Draft — needs expansion |

---

## Before Finishing Any Chapter

- All `% TODO:` comments replaced with real content
- All figure placeholders replaced with actual figures
- All `\label{}` references verified (no `??` in PDF output)
- `make lua` compiles with zero `!` errors
