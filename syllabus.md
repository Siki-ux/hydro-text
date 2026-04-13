# Thesis Syllabus

**Working title:** Design and Implementation of a Platform for Real-Time Environmental Sensor Data Collection, Integration, and Visualisation

---

## 1. Introduction

This chapter establishes the motivation and context for the thesis. It describes the problem of managing heterogeneous environmental sensor data across distributed field deployments covering the challenges of multiple manufacturers, communication protocols, and project specific data structures. The chapter introduces CZU as the primary stakeholder, outlines its sensor infrastructure across river and catchment monitoring projects, and explains why the existing UFZ Time.IO solution from the Helmholtz Centre for Environmental Research (UFZ) was chosen as a starting point rather than building from scratch. The chapter closes by stating the thesis goals and providing a structural overview of all subsequent chapters.

The connection to the European eLTER (Long-Term Ecosystem Research) research infrastructure is introduced here as a secondary motivation, establishing early that the platform must be designed not only for CZU-specific needs but with sufficient generality for broader European deployment scenarios.

---

## 2. Background and Related Work

### 2.1 Environmental Sensor Data Management

This section surveys the state of the art in environmental monitoring data infrastructures. It covers typical architectures for sensor data pipelines from edge devices through ingestion, storage, and access layers and identifies the key challenges: data heterogeneity, protocol diversity (MQTT, HTTP, file uploads, SFTP), time-series storage at scale, and the need for interoperability standards. The section provides the domain context necessary to evaluate design choices made later in the thesis.

### 2.2 OGC SensorThings API and the FROST Server

The OGC SensorThings API standard is described as the primary interoperability layer adopted in this work. This section explains the standard's data model (Things, Datastreams, Observations, ObservedProperties, Sensors, FeaturesOfInterest, Locations) and how it enables vendor-neutral access to sensor data. The open-source FROST-Server implementation used in the platform is introduced, including its capabilities, configuration model, and integration with PostgreSQL as the backing store.

### 2.3 The UFZ Time.IO Solution

This section analyses the original Time.IO solution developed at the Helmholtz Centre for Environmental Research. It describes the system's architecture, the dispatcher-based worker model, configdb-updater, thing-setup worker, per-thing PostgreSQL schema provisioning, MinIO object storage, Keycloak authentication, and MQTT-driven event flow. The section also honestly documents the state of the upstream codebase at the time of this thesis: specifically the non-functional SMS service and local STA views that required local workarounds (the `TSM-TEMP` approach), and missing integration points that motivated building the `water-dp` layer. The section concludes with an assessment of the upstream project's development activity and maintainability, raising the question of whether continued patchwork adaptation is a viable long-term strategy or whether a targeted rewrite of the problematic components would be more sustainable. This analysis forms the basis for the gap analysis in Chapter 3.

### 2.4 Institutional Context: eLTER and the Adoption of Time.IO

This section explains the institutional and organisational context in which Time.IO was selected as the foundation for this thesis. Time.IO was not chosen through an open technical comparison; rather, it emerged from the active engagement of eLTER leadership with the UFZ development team at the Helmholtz Centre. At the time the thesis was assigned, eLTER was evaluating Time.IO as a candidate platform for standardised data acquisition and integration across its European network of research sites. The thesis was framed explicitly within this evaluation effort, with the goal of assessing whether Time.IO could be adapted to serve real institutional deployments beyond the UFZ context. This section describes the relationship between UFZ and eLTER, the nature of eLTER's interest in Time.IO, and how the CZU use case fits into the broader picture of piloting the platform in a concrete operational environment providing evidence for or against its suitability for wider eLTER adoption.

### 2.5 eLTER Research Infrastructure

The European eLTER infrastructure is described, its goals for long-term ecosystem monitoring, the network of research sites it connects, and its data integration requirements. This section identifies the relevant eLTER data standards and access patterns that the platform should support to enable future deployment in that context.

---

## 3. Requirements Analysis

### 3.1 CZU Use Cases and Stakeholder Needs

This section derives the concrete requirements from the CZU deployment context. It describes the primary use cases: online data acquisition from sensors deployed in the field (via MQTT), offline ingestion of batch data from devices that upload files (CSV, via MinIO or SFTP), integration of sensors from different manufacturers with heterogeneous data formats, and organisation of sensors into project-oriented structures shared among teams. Additional use cases include data quality assessment, time-series visualisation, and role-based access control for different CZU project groups.

### 3.2 Functional Requirements

A structured list of functional requirements derived from the use cases and the thesis assignment. Requirements cover: 
(a) data ingestion - MQTT real-time, CSV file upload, SFTP polling, external API synchronisation; 
(b) sensor management - CRUD operations on Things/Datastreams, parser configuration, device type support; 
(c) project management - creating projects, assigning members and sensors, per project data views; 
(d) data quality - automated QA/QC checks, manual override, quality flag propagation; 
(e) visualisation - time series charts, geospatial layer display;
(f) authentication and access control - OIDC via Keycloak, per-project permissions; 
(g) batch import - bulk sensor onboarding, historical data loading; 
(h) multilingual UI - Czech and English at minimum.

### 3.3 Non-Functional Requirements

Non-functional requirements are specified here: containerised deployment (Docker and Podman support including rootless), horizontal extensibility for adding new ingestion worker types, response time targets for the API, standards compliance (OGC SensorThings API, OIDC), maintainability (modular codebase, database migrations), and alignment with eLTER interoperability requirements.

### 3.4 Gap Analysis: Time.IO vs. Target Platform

This section compares the capabilities of the original UFZ Time.IO system against the requirements identified in 3.1–3.3, producing a gap table that motivates the architectural additions described in Chapter 4. Key gaps include: no project-oriented data model, no custom frontend portal, no geospatial layer support, broken local STA views blocking FROST functionality, a non-functional upstream sensor management system (SMS) that was supposed to mediate between the configdb and FROST but was not operational at the time of this work, no alert evaluation subsystem, and no unified deployment mechanism for a combined stack. The gap analysis drives the scope of both the `water-dp` and `hydro-deploy` contributions.

---

## 4. Architecture Design

### 4.1 Overall System Architecture

This section presents the high-level architecture of the resulting platform, which integrates three components: `tsm-orchestration` (the adapted Time.IO stack providing MQTT, PostgreSQL/TimescaleDB, FROST, MinIO, Keycloak, Grafana, and ingestion workers), `water-dp` (the new application layer providing the project-centric API, portal, alert system, and GeoServer), and `hydro-deploy` (the unified deployment orchestrator). An architecture diagram illustrates the component boundaries, communication paths (REST, MQTT, direct database access), and network topology.

### 4.2 Component Responsibilities and Boundaries

Each major component's responsibility is precisely defined: `tsm-orchestration` owns raw time-series storage, per-thing schema provisioning, data ingestion pipeline, and FROST-based access; `water-dp` owns application-level concepts (projects, alerts, geospatial layers) and the user-facing portal; `hydro-deploy` owns nothing at runtime but everything about how the two stacks are assembled and configured. The decision to keep the two stacks separately deployable (with `hydro-deploy` as an optional integration layer) is justified.

### 4.3 Database Design

The database architecture is described, including two supported deployment variants: a shared PostgreSQL instance with TimescaleDB extension where both stacks coexist in the same database server (with schema-level isolation between TSM and water-dp), and a separate-database variant where each stack runs its own independent PostgreSQL instance — used when the stacks are deployed standalone without the `hydro-deploy` integration layer. The tradeoffs of each variant are discussed. In the shared variant, the `config_db` schema contains TSM configuration tables (`thing`, `schema_thing_mapping`, `file_parser_type`, `mqtt_device_type`, `project`, `database`). Each onboarded sensor gets an isolated per-thing schema containing its own `thing`, `datastream`, `observation`, and `location` tables — implemented as TimescaleDB hypertables for efficient time-series querying. The `water_dp` schema holds application-state tables: `projects`, `project_members`, `project_sensors`, `alert_definitions`, `alerts`, `computation_scripts`, `computation_jobs`, `dashboards`, `geo_layers`, `geo_features`, `simulations`, `sensor_activity_configs`. This section also describes the local STA views approach that exposes per-thing data through a unified FROST-compatible interface.

### 4.4 MQTT-Driven Event Architecture

The MQTT event bus is presented as the integration backbone of the platform. This section describes the event topics, message schemas, and the producer/consumer pattern used by all workers. The lifecycle of a sensor (Thing) is traced through MQTT events: creation triggers configdb-updater → thing-setup → schema provisioning. The same pattern is used for alert evaluation in `water-dp`, where the Celery Beat polling model was replaced by MQTT-triggered evaluation — the motivation, tradeoffs, and implementation of this change are explained.

### 4.5 Technology Selection Justifications

For each major technology choice, the rationale is stated explicitly as required by FI MUNI guidelines: FastAPI (async Python, automatic OpenAPI docs, Pydantic integration) over Flask/Django; Next.js 15 with App Router (React Server Components, SSR, file-based routing) over plain React or Vue; TimescaleDB (native time-series hypertables on PostgreSQL) over InfluxDB; GeoServer (standards-compliant WMS/WFS over PostGIS) for geospatial; Keycloak (battle-tested OIDC provider with realm/client model) for auth; MinIO (S3-compatible, self-hosted) for object storage.

### 4.6 Deployment Strategy

The deployment architecture is described: four Docker Compose files (tsm-orchestration base, water-dp base, water-dp TSM integration overlay, hydro-deploy bridge) are merged by Docker Compose's multi-file `-f` mechanism into a single project. A single `.env` file contains all credentials with `@sync` comment markers identifying variables that must match between stacks. The Makefile provides a scripted operator interface (`make setup`, `make secrets`, `make build`, `make up`, `make migrate`, `make seed`, `make check`). Podman rootless support is implemented via a Python preprocessing step that transforms compose files to fix Podman incompatibilities.

---

## 5. Implementation

### 5.1 TSM Orchestration Adaptation

This chapter section describes the changes made to the upstream `tsm-orchestration` codebase. The primary technical contribution is the local STA views implementation: since the upstream UFZ SMS service (which would normally expose FROST views) was non-functional at the time of this work, the platform implements a set of PostgreSQL views directly in the database (`sta_views_local/`) that aggregate per-thing schemas into a FROST-compatible unified view. All such changes are marked with `TSM-TEMP-*` identifiers in the codebase. While the naming convention was chosen to allow clean reversion if the upstream service is ever fixed, this section also critically evaluates the realistic prospects of that happening: given the apparent stagnation of the upstream project, the thesis argues that a targeted rewrite of the broken components is a more pragmatic path forward than indefinitely maintaining workarounds against an uncertain upstream. Additional adaptations include: restructuring the monolithic compose file into modular overlays, implementing the `docker-compose-water-dp.yml` integration overlay, adding Grafana views for per-thing time-series dashboards, and extending Flyway SQL migrations to include water-dp schema setup.

The worker architecture is described: the dispatcher/scheduler pattern common to all TSM workers, and the specific responsibilities of each: `worker-configdb-updater` (MQTT listener → `config_db.thing` table sync), `worker-thing-setup` (schema provisioning, MinIO bucket creation, Grafana org setup), `worker-file-ingest` (CSV parsing and observation insertion), `worker-mqtt-ingest` (real-time MQTT message processing), `worker-run-qaqc` (automated quality checks), `worker-sync-extapi` (external API polling), `worker-sync-extsftp` (SFTP file polling).

### 5.2 Water Data Platform — Backend

The `water-dp` API is a FastAPI application that acts as the application-logic layer on top of `tsm-orchestration`. This section describes the project structure (routers, models, schemas, services layers), the SQLAlchemy 2.0 async ORM patterns used, and the Alembic migration strategy. Key implementation areas covered: 
(a) the project-oriented data model and how sensors are linked to projects across the TSM schema boundary; 
(b) FROST API client integration for querying and creating Things/Datastreams without direct database access; 
(c) the alert evaluation system — the design of alert definitions (threshold, comparison, target datastream), the MQTT-triggered evaluation worker, and the alert state machine; 
(d) computation scripts and job management for user-defined data transformations; 
(e) GeoServer integration via REST API for publishing and querying PostGIS-backed spatial layers; 
(f) Keycloak OIDC integration including token validation middleware and per-project role enforcement.

### 5.3 Water Data Platform — Frontend Portal

The `water-dp` frontend is a Next.js 15 application using the App Router and React 19. This section covers the portal's information architecture and major feature areas: sensor and project management views, time-series chart views (Recharts), the data quality assessment interface, batch import workflows for historical data, the geospatial layer viewer, and the simulated sensor feature enabling testing without physical hardware. The multilingual implementation (Czech/English) using Next.js internationalisation is described. The section also covers the state management approach (Zustand), API client generation from the FastAPI OpenAPI schema, and authentication flow with Keycloak via NextAuth.

### 5.4 Hydro Deploy — Unified Deployment Layer

This section documents the `hydro-deploy` repository, which provides a single entry point for deploying the full integrated platform. The Docker Compose multi-file merge technique is explained in detail, including how the `hydro-platform-net` bridge network is used to allow both stacks to communicate while keeping their internal network namespaces separate, and how the database consolidation works (the water-dp application database is served by the TSM PostgreSQL instance, while a separate `postgres-app` instance remains for GeoServer's data directory). The Makefile targets are described individually: `setup` (repository cloning and symlink creation), `secrets` (cryptographically secure password generation into `.env`), `build` (building locally-compiled images for Keycloak themes and water-dp), `migrate` (running Flyway and Alembic migrations), `seed` (populating test data), and `check` (health-checking all services including `@sync` pair validation). The Podman support path is described, including the `podman_prep.py` transformation script and rootless-specific configuration adjustments.

---

## 6. Testing and Evaluation

### 6.1 Testing Approach

This chapter describes the testing strategy applied to the platform. The `water-dp` backend includes a pytest-based integration test suite that runs against a real PostgreSQL instance (not mocked), covering API endpoints, database operations, and service logic. The TSM worker components rely on the event-driven architecture for verification — correct behaviour is observable through MQTT event flow and database state. Manual end-to-end testing procedures for full-stack scenarios (thing creation → data ingestion → FROST query → portal display) are described.

### 6.2 Evaluation Against CZU Requirements

Each functional and non-functional requirement from Chapter 3 is evaluated: which are fully met, which are partially met, and which remain future work. The evaluation is supported by evidence from test results and deployed system screenshots. Special attention is given to the requirements most specific to CZU: project-oriented sensor management, offline batch import, heterogeneous protocol support, and multilingual portal.

### 6.3 Performance and Scalability Considerations

TimescaleDB hypertable query performance for time-series access is discussed, including the chunk-based storage model and its benefits for the expected observation data volumes. The async FastAPI + async SQLAlchemy stack is evaluated for API throughput. Known bottlenecks and their mitigation (e.g., Redis caching, background worker offloading) are noted.

### 6.4 Deployment on CZU Infrastructure and eLTER Path

This section documents the actual deployment of the platform on CZU infrastructure, describing the hardware/network environment and any deployment-specific configuration. The chapter then discusses the path to eLTER deployment: which components are already sufficiently general, what additional work would be required (e.g., eLTER-specific metadata schemas, federation across research sites, additional authentication requirements), and and a frank assessment of the `TSM-TEMP` workarounds — given the upstream project's apparent stagnation, the section argues that waiting for UFZ to fix the SMS is not a realistic plan and that a rewrite of the affected components is the more defensible long-term strategy.

---

## 7. Conclusion

This chapter summarises the thesis contributions: 
(1) a working adaptation of the UFZ Time.IO `tsm-orchestration` stack with local STA views, modular compose structure, and Podman support; 
(2) the `water-dp` platform providing project-oriented sensor management, MQTT-driven alerts, geospatial integration, and a multilingual portal; 
(3) the `hydro-deploy` unified deployment layer enabling single-command installation of the complete stack. The chapter reflects on the design decisions that most significantly shaped the outcome and identifies the limitations of the current implementation — including the `TSM-TEMP` workarounds for the non-functional upstream SMS — workarounds that are unlikely to be resolved by upstream activity and point toward a rewrite as the realistic next step and areas of the `water-dp` backend not yet covered by automated tests.

Future work directions include: a rewrite of the non-functional TSM components (SMS, local STA views) to replace the `TSM-TEMP` workarounds with a clean implementation rather than relying on upstream fixes that may never materialise, deployment of the platform for active CZU sensor projects, implementation of the eLTER extension layer, advanced QA/QC rules with configurable thresholds, and performance optimisation for larger sensor networks. The chapter ends with a reflection on the suitability of the OGC SensorThings API as the interoperability standard for this class of environmental monitoring platform.

---

## References

*To be populated. Will include: OGC SensorThings API specification, FROST-Server documentation, UFZ Time.IO publications, eLTER documentation, TimescaleDB technical documentation, and relevant literature on environmental sensor data management.*

---

## Appendices

- **Appendix A:** Installation guide for the Hydro Platform (`hydro-deploy` setup walkthrough)
- **Appendix B:** `water-dp` API reference (generated from OpenAPI schema)
- **Appendix C:** Database schema diagrams (TSM public schema, per-thing schema, water_dp schema)
- **Appendix D:** TSM worker configuration reference (parser types, device types, event topics)
- **Appendix E:** Sample sensor data ingestion workflow (end-to-end walkthrough with screenshots)
