---
service: "AIGO-ContentServices"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumPromptDatabasePostgres"
    type: "postgresql"
    purpose: "Stores AI agent configurations and L1/L2/TG editorial guidelines"
---

# Data Stores

## Overview

AIGO-ContentServices owns a single PostgreSQL database managed by the Prompt Database Service (`continuumPromptDatabaseService`). The database stores AI agent prompt configurations (name, version, role, system prompt, response class) and three tiers of editorial guidelines (L1 general, L2 category-specific, TG taxonomy-group-specific). The Content Generator and Web Scraper services are stateless with respect to primary storage; the scraper temporarily writes Salesforce CSV results to the local container filesystem (`salesforce/salesforce_data/salesforce_data.csv`), but this is ephemeral.

## Stores

### Prompt Database PostgreSQL (`continuumPromptDatabasePostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `continuumPromptDatabasePostgres` |
| Purpose | Stores AI agent configurations and editorial guideline data (L1, L2, TG tiers) |
| Ownership | owned |
| Migrations path | `service_prompt_database/alembic/versions/` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `agent_configurations` | Stores versioned AI agent definitions used by generator and scraper | `id`, `agent_name` (max 100), `version` (max 10), `role` (text), `prompt` (text), `response_class` (max 50); unique on `(agent_name, version)` |
| `l1_guidelines` | General (Level 1) editorial guidelines applicable to all deal copy | `id`, `type` (`deal` or `section`), `section` (nullable; one of `gallery_title`, `api_title`, `nutshell`, `introduction`, `what_we_offer`, `why_you_should_grab_the_offer`), `instructions` (text); unique on `(type, section)` |
| `l2_guidelines` | Category-specific (Level 2) editorial guidelines | `id`, `category` (max 50), `type`, `section` (nullable), `instructions` (text); unique on `(category, type, section)` |
| `tg_guidelines` | Taxonomy-group-specific editorial guidelines | `id`, `taxonomy_group` (max 50), `type`, `section` (nullable), `instructions` (text); unique on `(taxonomy_group, type, section)` |

#### Access Patterns

- **Read**: Guidelines fetched per request during content generation — L1 guidelines loaded wholesale; L2/TG guidelines fetched by category or taxonomy group derived from deal PDS code via `data/pds_conversion.csv` lookup. Agent configurations queried by `(agent_name, version)` pairs at scraper startup.
- **Write**: CRUD operations via the Prompt Database Service REST API. Initial data seeded via Alembic migrations from JSON files (`alembic/data/ai_agents.json`, `alembic/data/l1_guidelines.json`, `alembic/data/l2_guidelines.json`, `alembic/data/tg_guidelines.json`).
- **Indexes**: Unique constraints on `(agent_name, version)` in `agent_configurations`; `(type, section)` in `l1_guidelines`; `(category, type, section)` in `l2_guidelines`; `(taxonomy_group, type, section)` in `tg_guidelines`.

## Caches

> No evidence found in codebase. No Redis or in-memory caching layer is implemented.

## Data Flows

- `continuumPromptDatabaseService` is the sole writer and reader of `continuumPromptDatabasePostgres` via SQLAlchemy ORM sessions.
- `continuumWebScraperService` reads agent configurations from `continuumPromptDatabaseService` over HTTP at crawl initiation time.
- `continuumContentGeneratorService` reads guidelines from `continuumPromptDatabaseService` over HTTP during generation request processing.
- Salesforce CSV results are written to `salesforce/salesforce_data/salesforce_data.csv` within the `continuumContentGeneratorService` container filesystem (ephemeral; not replicated to any external store).
- PDS-to-category and PDS-to-taxonomy-group mappings are resolved from a static CSV file `service_prompt_database/data/pds_conversion.csv` bundled in the container image.
