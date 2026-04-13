# Hydro Platform — Thesis Text

Master's thesis of **Bc. Jakub Sikula** at the Faculty of Informatics, Masaryk University (FI MUNI).

| Field | Value |
|---|---|
| **Author** | Bc. Jakub Sikula |
| **Type** | Master's thesis (mgr) — implementation work |
| **Faculty** | Faculty of Informatics, Masaryk University (FI MUNI) |
| **Department** | Department of Software Engineering |
| **Advisor** | RNDr. Tomáš Rebok, Ph.D. |
| **Title** | Design and Implementation of a Platform for Real-Time Environmental Sensor Data Collection, Integration, and Visualisation |

---

## Repository Layout

```
hydro-text/
├── README.md
├── syllabus.md             ← chapter-by-chapter content outline
├── Makefile                ← build targets (make lua / make pdf / make clean)
└── dp-text/
    ├── fi-lualatex.tex     ← main file (LuaLaTeX — use for local builds)
    ├── fi-pdflatex.tex     ← main file (pdfLaTeX — matches Overleaf)
    ├── thesis.bib          ← bibliography
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

---

## Build Commands

Requires a TeX distribution (MiKTeX or TeX Live) with `lualatex` and `biber`.

```bash
make lua        # Build PDF with LuaLaTeX (recommended for local work)
make pdf        # Build PDF with pdfLaTeX (matches Overleaf compiler)
make open       # Open the LuaLaTeX PDF
make open-pdf   # Open the pdfLaTeX PDF
make figures    # Regenerate PlantUML figures (requires plantuml + java)
make docx       # Convert to DOCX (requires pandoc)
make clean      # Remove build artifacts, keep PDFs
```

Full compile sequence (done automatically by `make lua`):
```
lualatex fi-lualatex.tex → biber fi-lualatex → lualatex × 2
```

---

## FI MUNI Formal Requirements

| Item | Requirement |
|---|---|
| **Target length** | 50–70 standard pages (1 page = 1,800 characters); minimum 30 pages |
| **Own contribution** | > 70% of total scope (background/theory ≤ 30%) |
| **Language** | English |
| **Citations** | ISO 690:2022 standard via `biblatex-iso690` |
| **Required sections** | Authorship declaration, AI tools disclosure, abstract, keywords, TOC, introduction, core chapters, conclusion, bibliography |

---

## LaTeX Conventions

- Citations: `\parencite{key}` (parenthetical), `\textcite{key}` (inline author)
- File/function names in text: `\texttt{filename.py}`
- Cross-references: always `\ref{label}` — never "as mentioned above"
- Figure captions: below figure, include `\emph{Source: author}`
- Table captions: above table (floatrow handles this), include `\emph{Source: author}`
- Code listings: use `lstlisting` environment for snippets under 20 lines

---

## Language and Style

- **Voice:** impersonal / passive — *"the platform was designed to…"*, *"the service is responsible for…"*
- **Person:** never use "I", "we", "our", "you". Use *"this thesis"*, *"this work"*, *"the author"*
- **Tense:** present for system descriptions, past for design decisions
- **Sentences:** one idea per sentence; max ~35 words
- Introduce abbreviations once on first use: STA, FROST, TSM, MQTT, OIDC, RBAC, WMS, WFS, QC

---

## Terminology

| Concept | Use this term | Not these |
|---|---|---|
| A physical sensor device | **Thing** | device, node, entity |
| A measured property's time-series | **Datastream** | channel, stream, series |
| A single measurement | **Observation** | measurement, reading, data point |
| The TSM schema per sensor | **per-thing schema** | sensor schema, thing schema |
| The UFZ stack | **tsm-orchestration** or **TSM** | Time.IO (ok in background chapter) |
| The application layer | **water-dp** | water-dp-api, water platform |
| The deployment repo | **hydro-deploy** | deployment repo |
| OGC SensorThings API | **STA** (after introduction) | SensorThings, OGC API |
| The FROST implementation | **FROST** or **FROST-Server** | Frost, frost server |

---

## Upstream UFZ TSM Ecosystem

The local `tsm-orchestration` is a **heavily modified** fork of the upstream UFZ TSM project.
Original upstream: https://codebase.helmholtz.cloud/ufz-tsm

| Repository | Tech | Notes |
|---|---|---|
| **tsm-orchestration** | Docker Compose, Python workers | Core ingestion pipeline — what was forked |
| **tsm-frontend** | Django 4.x | Original Thing management UI |
| **thing-management** | FastAPI + Vue.js 3 / Quasar | Newer replacement for tsm-frontend |
| **timeio-and-sms** | Docker Compose bundle | Combined SMS + Time.IO deployment |
| **SMS** | Helmholtz Hub Terra | Non-functional at time of thesis |

**Published paper:** Bumberger et al., "Digital ecosystem for FAIR time series data management in environmental system science", *SoftwareX* 29, 2025. DOI: `10.1016/j.softx.2025.102038`

---

## Decommissioned Features

These features were originally planned but removed from scope:

- **Computations (UC-16, G-10):** Sandboxed Python computation framework — decommissioned and removed from requirements.
- **Custom dashboards (FR-18):** Drag-and-drop custom dashboard builder — decommissioned. Grafana dashboards (TSM built-in) remain.

---

## Checklist Before Submission

- [ ] All `% TODO:` comments replaced with real content
- [ ] All figure placeholders replaced with actual figures
- [ ] All `\label{}` references verified (no `??` in PDF output)
- [ ] All `TODO-*` bibliography entries replaced with real citations
- [ ] Abstract: 150–250 words
- [ ] Keywords: 5–8 specific terms
- [ ] Page count: 50–70 standard pages
- [ ] Background/theory chapters ≤ 30% of total length
- [ ] `make lua` compiles with zero `!` errors
- [ ] AI tools disclosure section present
