---
service: "tronicon-ui"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Tools / Campaign Management / Merchandising"
platform: "Continuum"
team: "Tronicon / Sparta"
status: active
tech_stack:
  language: "Python"
  language_version: "2.7"
  framework: "web.py"
  framework_version: "0.37"
  runtime: "Gunicorn"
  runtime_version: "19.10.0"
  build_tool: "Grunt (frontend), Fabric (deployment)"
  package_manager: "pip, npm"
---

# Tronicon UI Overview

## Purpose

Tronicon UI is the internal web application used by Groupon merchandising and campaign teams to create, configure, and manage card-based campaigns, geo-targeted content, CMS content versions, and UI themes. It provides a unified browser-based workspace for the full lifecycle of campaign content — from card and deck creation through publishing and archiving. The service acts as the operator-facing control plane for the Tronicon campaign card system within the Continuum platform.

## Scope

### In scope

- Card campaign creation and management (cards, decks, campaign groups)
- Card template definition and application
- Geographic boundary (geo-polygon) targeting for campaigns
- CMS content creation, editing, versioning, and archiving with audit trail
- UI theme configuration including CSV upload and scheduling
- Business group management
- Proxy routing to Campaign Service via `/c/` path prefix
- Async task processing for long-running operations via Celery

### Out of scope

- Consumer-facing storefront rendering (handled by MBNXT / front-end platform)
- A/B experiment configuration (handled by Birdcage / `birdcageExperiments` and Alligator `continuumAlligatorService`)
- Taxonomy category management (owned by `continuumTaxonomyService`)
- Image storage and processing (owned by `grouponImageService`)
- Brand data management (owned by `brandService`)
- Audience segmentation logic (owned by `audienceService`)

## Domain Context

- **Business domain**: Merchant Tools / Campaign Management / Merchandising
- **Platform**: Continuum
- **Upstream consumers**: Internal merchandising and campaign operations teams (browser-based users); no known programmatic API consumers
- **Downstream dependencies**: Campaign Service, Tronicon CMS, Alligator Service, Groupon API, Taxonomy Service, Card UI Preview, Geo Taxonomy API, Image Service, Brand Service, Gconfig Service, Audience Service, Rocketman Render, API Proxy US/EMEA

## Stakeholders

| Role | Description |
|------|-------------|
| Merchandising Team | Primary end users who create and manage card campaigns, CMS content, and themes |
| Campaign Operations | Users who manage campaign groups, decks, and geo targeting |
| Tronicon / Sparta Team | Engineering team owning and maintaining the service |
| Platform / Architecture | Architects integrating Tronicon UI within the Continuum C4 model |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 2.7 | requirements.txt, Dockerfile |
| Framework | web.py | 0.37 | requirements.txt |
| Runtime | Gunicorn | 19.10.0 | requirements.txt |
| Build tool | Grunt | — | Gruntfile.js, package.json |
| Build tool | Fabric | 1.8.2 | requirements.txt, fabfile.py |
| Package manager | pip, npm | — | requirements.txt, package.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| web.py | 0.37 | http-framework | Lightweight URL routing and request handling |
| gunicorn | 19.10.0 | runtime | Production WSGI server |
| sqlalchemy | 0.9.4 | orm | Database abstraction and queries |
| mysql-python | 1.2.5 | db-client | MySQL adapter |
| alembic | 0.8.4 | migration | Database schema versioning |
| requests | 2.7.0 | http-client | API calls to internal services |
| celery | 3.1.13 | message-client | Async job processing |
| beautifulsoup4 | 4.3.2 | parsing | HTML/XML parsing |
| fabric | 1.8.2 | deployment | Deployment automation |
| eventlet | 0.30.2 | concurrency | Green threading support |
| python-dotenv | 0.18.0 | config | Environment variable management from .env files |
| pytest | 2.6.3 | testing | Unit and functional testing |
| selenium | 2.49.2 | testing | UI and browser-level testing |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
