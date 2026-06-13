# CLAUDE.md — Instructions for Creating the Master's Thesis Defense Presentation

## Overview

This file contains all context needed to create a LaTeX Beamer defense presentation for the master's thesis:
**"Design and Implementation of a Real-Time Sensor Data Platform for River and Catchment Monitoring"**
by **Bc. Jakub Sikula**, supervised by **RNDr. Tomáš Rebok, Ph.D.**, at the **Faculty of Informatics, Masaryk University**.

The presentation is for the **defense of a master's thesis (DP)**. The student will have **15 minutes** for the opening presentation.

---

## 1. LaTeX Template & Build Instructions

### Template
Use the MU Beamer theme already present in this directory. The template file `fi.tex` shows the structure. Key setup:

```latex
\documentclass[]{beamer}
\usepackage[no-math]{fontspec}       %% LuaLaTeX with fontspec for Unicode
\defaultfontfeatures{Mapping=tex-text}
\usepackage{polyglossia}
\setmainlanguage{slovak}             %% Slovak language
\usepackage{csquotes}
\usepackage{expl3,biblatex}
\addbibresource{example.bib}
\usepackage{booktabs}
\usepackage{tikz}
\usetikzlibrary{arrows.meta, calc, positioning}
\graphicspath{{../dp-text/figures/}}
\usetheme[workplace=fi]{MU}
```

**Note:** We use `fontspec` + `polyglossia` (not `babel` + T1) for proper Slovak diacritics under LuaLaTeX.

### Metadata to set
```latex
\title[Hydro Platform]{Design and Implementation of a Real-Time Sensor Data Platform for River and Catchment Monitoring}
\subtitle[Obhajoba diplomovej práce]{Obhajoba diplomovej práce}
\author[J. Sikula]{Bc. Jakub Sikula\texorpdfstring{\\}{, }sikula@mail.muni.cz}
\institute[FI MU]{Fakulta informatiky, Masarykova univerzita}
\date{\today}
\subject{Obhajoba diplomovej práce}
\keywords{senzorové dáta, environmentálny monitoring, OGC SensorThings API, MQTT, TimescaleDB, FastAPI, Next.js, Docker, eLTER}
```

**Note:** The thesis title stays in English (as written in the thesis). Subtitle, institute, and other metadata are in Slovak.

### Build
From `hydro-text/` directory:
```bash
make pres          # build presentation PDF
make open-pres     # open the PDF
```

### Architecture diagram
The architecture on slide 6 is a **native TikZ drawing** inside the beamer file, optimized for the slide aspect ratio. It is NOT the `arch-overview.pdf` from the thesis (which was designed for landscape A4). The TikZ code uses the same structure and color-coding:
- `fill=blue!15` (newbox) — components created in this thesis
- `fill=orange!18` (modbox) — inherited & modified components
- white (box) — inherited upstream components

### Available figure files (in `../dp-text/figures/`)
- `timeio-ecosystem.jpg` — UFZ Time.IO ecosystem diagram (no longer used in slides — replaced by TikZ diagram on slide 3)
- `screenshot-dashboard.png` — Project list page (used on slide 8)
- `screenshot-timeseries.png` — Sensor detail with time-series chart (used on slide 8)
- `screenshot-map.png` — Interactive map with WMS overlay (used on slide 9)
- `screenshot-sensor-detail.png` — Sensor metadata and chart view
- `screenshot-sms.png` — SMS management interface
- `screenshot-qaqc.png` — QA/QC configuration interface
- `screenshot-layers.png` — Geospatial layer management
- `screenshot-batch-import.png` — Bulk import interface
- `screenshot-i18n.png` — Multilingual interface demo

---

## 2. Defense Presentation Guidelines (FI MU)

These rules MUST be followed:

- **15 minutes** for the opening presentation (master's thesis)
- **PDF format** with embedded fonts
- **Introduction ≤ 1 minute** — no general chit-chat
- **6×6 rule**: max 6 bullets per slide, max 6 words per bullet
- Use mainly **pictures, graphs, tables** — text only in bullet-point format
- **Bold** important information
- Cite all figures properly
- **Do NOT** include responses to reviewer questions in the main presentation — prepare separate slides at the end
- The last slide should be reserved for **questions from reviews** (to be shown after testimonials are read)
- Goal: **"sell the thesis"** — do NOT try to present the topic exhaustively; convince the committee that the thesis goals were fulfilled and the problem was hard
- The aim is NOT to walk through all chapters — it is to show: problem → what I did → proof it works
- Committee members are CS generalists, not domain experts — introduce domain-specific concepts briefly, avoid implementation internals
- Clearly define what the student did vs. what existed before (upstream Time.IO)
- **Language: Slovak** — all slide text in Slovak, technical terms (Time.IO, FROST-Server, FastAPI, Docker, etc.) stay in English

---

## 3. Thesis Content Summary

### 3.1 Problem Statement
Environmental monitoring networks generate continuous streams of heterogeneous sensor data from devices by different manufacturers, using different protocols (MQTT, HTTP, SFTP, CSV upload), with different data models. CZU (Czech University of Life Sciences Prague) operates hydrological monitoring infrastructure but had no unified, standards-compliant platform. The UFZ Time.IO system was identified as a candidate foundation, but had critical gaps.

### 3.2 Thesis Goals (enumerate these clearly in presentation)
1. **Analyze** the capabilities and limitations of UFZ Time.IO for CZU/eLTER deployment
2. **Design and implement** the Water Data Platform (`water-dp`): application layer with project management, alerting, geospatial integration, multilingual portal
3. **Implement** a unified deployment layer (`hydro-deploy`): single-command installation of the complete stack
4. **Evaluate** the platform against identified requirements

### 3.3 Context: eLTER Research Infrastructure
- eLTER = European Long-Term Ecosystem Research infrastructure
- Time.IO is the time-series data acquisition component of eLTER CyberInfrastructure
- CZU deployment is a pilot: testing if Time.IO can serve beyond UFZ's own sites
- Dual purpose: address CZU operational needs + provide evidence for eLTER suitability

### 3.4 Gap Analysis (11 gaps identified — key ones to highlight)
| Gap | Description | Addressed by |
|-----|-------------|--------------|
| G-1 | No project-oriented data model | Data platform |
| G-2 | No user-facing web portal | Data platform |
| G-3 | No geospatial layer management | Data platform |
| G-4 | Non-functional STA views (FROST-Server broken) | TSM adaptation |
| G-5 | Non-functional SMS service | TSM adaptation |
| G-6 | No alert evaluation subsystem | Data platform |
| G-7 | No unified deployment mechanism | Deployment layer |
| G-8 | No Podman rootless support | Deployment layer |
| G-9 | No multilingual interface | Data platform |
| G-10 | Upstream frontend bugs (invalid MQTT messages) | Data platform |
| G-11 | Hardcoded parsers and device types | Data platform |

### 3.5 Architecture (TWO-LAYER DESIGN — key diagram)
The platform has two runtime layers + a deployment layer:

**Layer 1: tsm-orchestration (Infrastructure layer — inherited & modified)**
- PostgreSQL + TimescaleDB (time-series storage)
- Mosquitto MQTT broker (event backbone)
- FROST-Server (OGC SensorThings API)
- MinIO (S3-compatible object storage)
- Keycloak (OIDC authentication)
- Grafana (visualization)
- 9 Python ingestion workers (configdb-updater, thing-setup, mqtt-ingest, file-ingest, run-qaqc, sync-extapi, sync-extsftp, grafana-user, monitor-mqtt)
- Cron scheduler

**Layer 2: Water Data Platform (Application layer — NEW, this thesis)**
- FastAPI backend (Python)
- Next.js 15 frontend (TypeScript/React)
- Celery worker (background tasks)
- GeoServer (geospatial layers via WMS/WFS)
- Redis (Celery message broker)

**Layer 3: hydro-deploy (Deployment layer — NEW, this thesis)**
- Docker Compose multi-file merge (4 Compose files)
- Makefile operator interface (`make setup`, `make secrets`, `make build`, `make up`, `make check`)
- Automated secret generation
- Podman rootless support
- 22 containers total in the full stack

**Shared Data Layer:**
- Single PostgreSQL instance with schema-level isolation
- `config_db` schema (TSM-owned)
- Per-thing schemas (TSM-owned, one per sensor)
- `water_dp` schema (data platform-owned)

**Key design decision:** Keeping infrastructure and application layers separate allows upstream TSM updates to be merged without conflicting with application code.

### 3.6 Key Implementation Details

#### TSM Adaptations
- **Local STA Views**: Replaced non-functional SMS-dependent views with 9 local views querying per-thing schema tables directly → made FROST-Server functional
- **18 TSM-TEMP markers** in codebase for easy identification/revert
- Compose modularization for overlay-based configuration

#### Water Data Platform Backend (FastAPI)
- Layered architecture: endpoints → schemas → services → models
- 16 REST API router modules
- Project-oriented data model linking sensors to projects
- Two-tier RBAC: Keycloak groups (Tier 1) + per-project roles owner/editor/viewer (Tier 2)
- FROST API client (sync + async variants) for STA entity access
- Alert system: threshold, no-data, QA/QC-based rules with state machine (active → acknowledged → resolved)
- TimeIO Orchestrator: constructs Thing config payloads, publishes to MQTT
- Alembic database migrations
- AST-based sandboxing for user-uploaded parser scripts (security)

#### Water Data Platform Frontend (Next.js 15)
- App Router with React Server Components
- Multilingual: English, Czech, Slovak (Zustand-persisted locale)
- Interactive time-series charts (Recharts) with zoom and brush
- Interactive maps (MapLibre GL JS) with GeoServer WMS overlay
- Sensor management, project management, alert management
- NextAuth OIDC integration with Keycloak
- 10 React Query hook modules for API data fetching

#### Deployment Layer (hydro-deploy)
- Single `make up` starts all 22 containers
- `generate-secrets.sh` for cryptographic secret generation
- `check.sh` for health verification
- Podman rootless support via `podman_prep.py` (7 automated transformations)
- Optional Cloudflare Tunnel for internet exposure

### 3.7 Testing & Evaluation Results

#### Test Coverage
- **Backend**: 804 unit/integration tests across 43 files (pytest)
  - TimeIO DB service: 152 tests
  - RBAC permission resolver: 76 tests
  - Alert evaluator: 69 tests
- **Frontend**: 96 test cases in 13 files (Vitest + React Testing Library)
- **TSM upstream**: 131 inherited test functions (all pass)
- **Total**: 1,031 automated tests

#### Requirements Evaluation
- **23 of 24 functional requirements fully met**
- 1 partially met (FR-22: Keycloak group management — decommissioned from portal, users manage via Keycloak admin console)
- All 8 non-functional requirements met

#### Performance (Locust load tests)
- All API endpoints respond within 2-second threshold
- Lightweight CRUD: sub-15ms median latency
- Data-heavy endpoints (FROST fan-out): under 310ms at 95th percentile
- Sustained 11.7 req/s under 25 concurrent users

#### Deployment Validation
- Full stack deployed on cloud.muni.cz
- CZU testing with a small number of sensors (full synchronization pending)
- `check.sh` confirmed all 22 containers healthy

### 3.8 Conclusion & Key Takeaways (for "selling" the thesis)

**What was built:**
1. Adapted TSM ingestion stack (restored FROST-Server functionality)
2. New application layer (FastAPI + Next.js) with project management, alerts, maps, multilingual portal
3. Unified deployment (single `make up` for 22-container stack)

**Key finding:** The architectural ideas behind Time.IO (per-Thing schema isolation, MQTT-driven workers, OGC STA compliance) are sound, but a purpose-built implementation targeting eLTER's needs would be more sustainable than continued adaptation of the upstream codebase.

**Limitations to acknowledge:**
- 18 TSM-TEMP workarounds still in place (upstream SMS never fixed)
- FROST client integration test coverage gaps (14%)
- Not benchmarked beyond CZU scale
- Not yet eLTER-ready (missing metadata schemas, federation, FAIR compliance)

**Future work highlights:**
1. TSM component rewrite (clean STA view layer)
2. eLTER metadata integration (DEIMS-SDR, EnvThes)
3. eLTER LogIn federation (Perun AAI)
4. Cross-site federation
5. Performance optimization (Redis caching, FROST clustering)

---

## 4. Current Slide Structure (fi.tex)

The presentation has 13 main slides + appendix for review questions.

| # | Title | Content | Time |
|---|-------|---------|------|
| 1 | Titulný snímok | `\maketitle` | — |
| 2 | Problém a motivácia | 4 bullets: heterogénne dáta, ČZU, Time.IO, eLTER | ~1 min |
| 3 | Východisko: UFZ Time.IO | Native TikZ diagram of original TSM architecture + caption | ~1 min |
| 4 | Analýza nedostatkov | 6 bullets (key gaps) + "11 nedostatkov" | ~1 min |
| 5 | Ciele práce | 4 numbered goals | ~30 sec |
| 6 | Architektúra riešenia | Native TikZ diagram with legend | ~1.5 min |
| 7 | Čo som vytvoril | 3 blocks: TSM adaptácia, WDP, hydro-deploy | ~1 min |
| 8 | Portál: správa projektov | 2-column screenshots: dashboard + timeseries | ~1.5 min |
| 9 | Interaktívna mapa | `screenshot-map.png` full width | ~1 min |
| 10 | Nasadenie jedným príkazom | 2-column: bullets + Compose merge block | ~1 min |
| 11 | Testovanie a validácia | Test count table + 3 result bullets | ~1.5 min |
| 12 | Kľúčové zistenie | block + alertblock + 2 bullets | ~1 min |
| 13 | Obmedzenia a budúca práca | 2 bullet groups | ~1 min |
| 14 | Ďakujem za pozornosť | plain frame | — |
| A | Odpovede na otázky | placeholder (fill after receiving reviews) | after reviews |

**Total speaking time: ~13 minutes** (leaves ~2 min buffer for pace variation)

### Style decisions already applied
- **Language**: Slovak with `polyglossia`, technical terms in English
- **No `---`** in titles (use `:` or `–` instead)
- **No G-x identifiers** in gap analysis
- **No tables** for contributions (use `\block` elements instead)
- **English kept** for: health-check, workaround, upstream, FROST client, compliance
- Architecture is a **native TikZ diagram** (not the thesis PDF which was for landscape A4)
- `screenshot-dashboard.png` used (not `screenshot-project-list.png` which was a placeholder)
- TSM adaptácia mentions **ingestion worker modifications** alongside STA views

---

## 5. Example Speech Script (Slovak, ~13 minutes)

Below is a timed speech for each slide. Read it naturally — this is a guide, not a script to memorize. Practice aloud and adjust to your speaking pace.

---

### Snímok 1: Titulný snímok (~15 sec)

> Dobrý deň, volám sa Jakub Sikula a rád by som vám predstavil svoju diplomovú prácu s názvom „Design and Implementation of a Real-Time Sensor Data Platform for River and Catchment Monitoring". Vedúcim práce bol pan doktor Tomaš Rebok.

---

### Snímok 2: Problém a motivácia (~1 min)

> Environmentálne senzorové siete produkujú nepretržité toky heterogénnych dát. Rôzni výrobcovia, rôzne komunikačné protokoly — MQTT, SFTP, CSV upload — a rôzne dátové formáty. Zjednotiť tieto dáta pod jednu platformu je naozaj netriviálny problém.
>
> Česká zemědělská univerzita v Prahe prevádzkuje monitorovaciu infraštruktúru na riečnych povodiach, ale doteraz nemala žiadnu jednotnú platformu, ktorá by tieto dáta spravovala štandardizovaným spôsobom.
>
> Ako východisko sme zvolili open-source systém Time.IO, vyvinutý v Helmholtz Centre v Lipsku. Toto nasadenie je zároveň pilotným projektom v rámci európskej výskumnej infraštruktúry eLTER, ktorej cieľom je dlhodobý ekosystémový monitoring.

---

### Snímok 3: Východisko: UFZ Time.IO (~1 min)

> Na diagrame vidíte architektúru Time.IO tak, ako sme ju zdedili. Hore vstupujú dáta z MQTT senzorov do Mosquitto brokera. Ten ich rozdelí medzi ingestion workery — mqtt-ingest, file-ingest, run-qaqc a ďalšie — ktoré ukladajú observácie do PostgreSQL s TimescaleDB. Každý senzor má vlastnú schému, takzvané per-thing schemas.
>
> Pod workermi sú služby: FROST-Server pre OGC SensorThings API, Keycloak pre autentifikáciu, Grafana a Cron ktory spušťa ulohy na napriklad pravidelne getovanie dat z externych API. Súbory z SFTP alebo CSV uploadov idú priamo do MinIO.
>
> Ale všimnite si červené čiarky. SMS Backend nikdy nepodarilo sprevádzkovať — a FROST-Server aj Grafana na ňom záviseli cez SQL views. Upstream frontendy posielali nevalidné MQTT správy do brokera, čo spôsobovalo tiché zlyhania. Tieto a mnoho ďalších problémom definovalo rozsah mojej práce.

---

### Snímok 4: Analýza nedostatkov (~1 min 15 sec)

> Nedostatky som rozdelil do dvoch skupín. Prvá sú technické problémy v upstream kóde — to, čo vidíte na predchádzajúcom diagrame červenou.
>
> FROST-Server bol nefunkčný kvôli závislosti na SMS. Upstream frontendy posielali nevalidné MQTT správy. Celý systém bol hardcoded pre UFZ prostredie — Keycloak klienti s natvrdo zadanými UFZ prefixmi, špecificky nakonfigurované scopes — a k ničomu z toho neexistovala dokumentácia. Veľa času som strávil dolovaním z kódu, prečo niektoré časti nefungujú.
>
> K tomu upstream tím kontinuálne vyvíjal bez ohľadu na backward kompatibilitu — mazali staršie verzie a artefakty. Napriek pinnovaniu verzií som musel neustále preberať upstream zmeny. Nachádzal som závažné bugy, ktoré po pár týždňoch opravili, ale nemohol som ich reportovať, pretože mi nedali prístup k ich bug trackeru.
>
> Druhá skupina sú chýbajúce funkcie pre ČZU — žiadny webový portál, projektová správa, upozornenia, jednotné nasadenie a viacjazyčnosť.
>
> Celkovo jedenásť nedostatkov, ktoré definovali rozsah mojej práce.

---

### Snímok 5: Ciele práce (~30 sec)

> Ciele práce sú štyri. Prvý — analyzovať Time.IO voči požiadavkám ČZU a eLTER. Druhý — navrhnúť a implementovať Water Data Platform, teda aplikačnú vrstvu s projektmi, portálom, upozorneniami a mapami. Tretí — implementovať jednotné nasadenie, hydro-deploy. A štvrtý — vyhodnotiť výslednú platformu voči identifikovaným požiadavkám.

---

### Snímok 6: Architektúra riešenia (~1 min 30 sec)

> Toto je kľúčový snímok — architektúra celého riešenia.
>
> Platforma má dve runtime vrstvy. Vpravo je tsm-orchestration, infraštruktúrna vrstva, zdedená a upravená. Obsahuje FROST-Server, Keycloak, Grafanu, ingestion workery a cron scheduler. Komponenty v oranžovej farbe som modifikoval — najmä ingestion workery, kde som upravoval provisioning, parsery a MQTT integráciu.
>
> Vľavo, v modrej, je Water Data Platform — celá táto vrstva je nová, navrhnutá a implementovaná v rámci tejto práce. Obsahuje FastAPI backend, Next.js frontend, Celery worker pre asynchrónne úlohy a GeoServer pre geospatial vrstvy.
>
> Dole je zdieľaná dátová vrstva — jeden PostgreSQL s TimescaleDB, MinIO pre súbory a Mosquitto MQTT broker ako integračná chrbtica. MQTT zariadenia posielajú dáta priamo do brokera.
>
> Dôležité rozhodnutie: tieto dve vrstvy sú oddelené, čo umožňuje nezávislý vývoj a jednoduchšie updaty z upstreamu.

---

### Snímok 7: Čo som vytvoril (~1 min)

> Poďme si zhrnúť tri hlavné príspevky.
>
> Prvý — TSM adaptácia. Nahradil som nefunkčné STA views deviatimi lokálnymi views, čím sa FROST-Server stal funkčným. Upravil som tiež ingestion workery — provisioning, parsery a MQTT integráciu. Celkovo je v kóde osemnásť označených workaroundov, pripravených na jednoduchý revert.
>
> Druhý — Water Data Platform. Kompletne nová aplikačná vrstva: FastAPI backend a Next.js 15 portál s projektovou správou, dvojúrovňovým RBAC, systémom upozornení, interaktívnymi mapami a podporou troch jazykov.
>
> Tretí — hydro-deploy. Jediný príkaz `make up` naštartuje dvadsaťdva kontajnerov. Automatická správa hesiel a health-check.

---

### Snímok 8: Portál – správa projektov a senzorov (~1 min 30 sec)

> Tu vidíte ukážky z portálu. Vľavo je zoznam projektov — každý projekt zobrazuje popis, počet prepojených senzorov a rolu používateľa. Projekty sú filtrovateľné podľa Keycloak skupín.
>
> Vpravo je detail senzora s vizualizáciou časových radov. Grafy sú interaktívne — podporujú zoom, výber časového rozsahu a prepínanie medzi datastreams. Dáta sa načítavajú cez React Query s cachingom.
>
> Celý portál je viacjazyčný — angličtina, čeština a slovenčina — s automatickou detekciou jazyka prehliadača.

---

### Snímok 9: Interaktívna mapa a GeoServer vrstvy (~1 min)

> Ďalšou kľúčovou funkciou je interaktívna mapa. Senzory sú zobrazené ako farebné markery na CARTO basemape. Po kliknutí na senzor sa zobrazí popup s aktuálnymi hodnotami — tu napríklad vodná hladina a teplota.
>
> Cez GeoServer je možné prekryť WMS vrstvy — napríklad hranice povodí alebo geologické mapy. Vrstva sa dá zapnúť a vypnúť v layer selectore vľavo hore. Celé je postavené na MapLibre GL JS s tridsaťsekundovým auto-refreshom.

---

### Snímok 10: Nasadenie jedným príkazom (~1 min)

> Posledný komponent je deployment layer. Operátor spustí `make up` a celá platforma — dvadsaťdva kontajnerov — sa naštartuje v správnom poradí.
>
> Funguje to tak, že štyri Docker Compose súbory sa mergujú do jednej konfigurácie. Skripty automaticky vygenerujú kryptograficky bezpečné heslá a synchronizujú ich medzi stackami.
>
> `make check` overí zdravie všetkých služieb. Celé je navrhnuté tak, aby operátor nepotreboval znalosti vnútornej architektúry. Podporovaný je aj rootless Podman pre prostredia bez Docker démona.

---

### Snímok 11: Testovanie a validácia (~1 min 30 sec)

> Teraz k validácii. Backend má osemsto štyri testov pokrývajúcich API endpointy, služby, RBAC a alerty. Frontend má deväťdesiatšesť testov cez Vitest. Z upstreamu sme zdedili stotridsaťjeden testov — všetky prechádzajú. Celkovo vyše tisíc automatizovaných testov.
>
> Z dvadsiatich štyroch funkčných požiadaviek sme dvadsaťtri splnili úplne. Jedna — správa Keycloak skupín cez portál — bola čiastočne splnená, používatelia ju riešia priamo cez Keycloak admin konzolu.
>
> Záťažové testy cez Locust potvrdili odozvu pod tristodesať milisekúnd na deväťdesiatom piatom percentile pri dvadsiatich piatich súbežných používateľoch. Platforma je nasadená na cloud.muni.cz a ČZU ju aktuálne testuje v malom rozsahu s niekoľkými senzormi.

---

### Snímok 12: Kľúčové zistenie (~1 min)

> Aké je hlavné zistenie tejto práce?
>
> Architektonické myšlienky za Time.IO sú správne. Per-thing izolácia v databáze, MQTT-driven worker pipeline a OGC SensorThings API ako interoperabilný štandard — to všetko funguje.
>
> Problém je v upstream implementácii. SMS služba nikdy nebola funkčná, frontendy generovali chybné správy, kód bol hardcoded pre UFZ bez dokumentácie a upstream tím kontinuálne lámal backward kompatibilitu. Podpora pre externých prispievateľov prakticky neexistuje — nemali sme ani prístup k bug trackeru. V kóde je stále osemnásť dočasných workaroundov.
>
> Záver je, že účelová implementácia zameraná na konkrétne potreby eLTER by bola udržateľnejšia než ďalšia adaptácia upstream kódu.

---

### Snímok 13: Obmedzenia a budúca práca (~1 min)

> Budem úprimný ohľadom obmedzení. TSM-TEMP workaroundy sú stále v kóde. Testovacie pokrytie FROST clienta je len štrnásť percent. Platforma nebola overená vo väčšej mierke než ČZU a ešte nie je pripravená pre plnú eLTER integráciu.
>
> Budúca práca zahŕňa prepísanie TSM komponentov s čistou STA vrstvou, integráciu eLTER metadátových štandardov — DEIMS-SDR, EnvThes a LogIn — a implementáciu federácie medzi nezávislými inštanciami platformy.

---

### Snímok 14: Ďakujem za pozornosť (~10 sec)

> Ďakujem za pozornosť. Som pripravený odpovedať na otázky z posudkov, a potom na vaše otázky.

---

**Celkový čas: ~13 minút** — zostáva ~2-minútová rezerva pre prirodzené pauzy a tempo.

---

## 5. Key Technologies to Reference

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Backend API | FastAPI (Python) | REST API, async support |
| Frontend | Next.js 15 (TypeScript) | Web portal, SSR, i18n |
| Time-series DB | PostgreSQL + TimescaleDB | Observation storage |
| Message broker | Mosquitto MQTT | Event-driven architecture |
| STA endpoint | FROST-Server | OGC SensorThings API |
| Object storage | MinIO | S3-compatible file storage |
| Auth | Keycloak | OIDC, RBAC |
| Visualization | Grafana, Recharts | Dashboards, charts |
| Maps | MapLibre GL JS, GeoServer | Geospatial, WMS/WFS |
| Task queue | Celery + Redis | Background processing |
| Deployment | Docker Compose, Makefile | Container orchestration |
| QA/QC | SaQC | Automated quality control |
| DB migrations | Alembic (water-dp), Flyway (TSM) | Schema evolution |

---

## 6. Numbers to Highlight

- **22 containers** in the full stack
- **1,031 automated tests** total
- **804 backend tests** across 43 files
- **23/24 functional requirements** fully met
- **11 gaps** identified and addressed
- **9 local STA views** replacing broken upstream views
- **18 TSM-TEMP** marked workarounds
- **9 ingestion workers** in TSM
- **16 API router modules** in the backend
- **3 languages** supported (EN, CS, SK)
- **15-minute** presentation time limit
- **sub-310ms** 95th percentile latency under load
- **11.7 req/s** sustained under 25 concurrent users

---

## 7. Presentation Style Notes

- Language: **Slovak** (thesis is written in English, but the defense presentation is delivered in Slovak)
- All slide text, bullet points, and frame titles must be in **Slovak**
- Technical terms and proper names (Time.IO, FROST-Server, FastAPI, etc.) stay in English — do not translate them
- Keep English for naturally used terms: **health-check, workaround, upstream, compliance, FROST client, provisioning**
- Do NOT force Slovak translations of technical phrases (e.g. NOT "zdravotné kontroly" for health-check)
- Do NOT use `---` (em-dash) in titles — use `:` or `–` (en-dash) instead
- Do NOT use tables for contributions/gap analysis — use `\block` elements or bullet lists
- Do NOT use G-x identifiers from the thesis in the presentation
- Architecture is a **native TikZ diagram** inside fi.tex, not the thesis PDF
- Tone: confident, technical but accessible to CS generalists
- Emphasize **what the student did** vs. what was inherited from Time.IO
- The three-component structure (TSM adaptation + Water Data Platform + hydro-deploy) should be the narrative backbone
- Use screenshots and architecture diagrams — they are more effective than text
- The gap analysis provides a natural "before/after" narrative arc
- End with the key insight: Time.IO concepts are sound, purpose-built implementation would be better