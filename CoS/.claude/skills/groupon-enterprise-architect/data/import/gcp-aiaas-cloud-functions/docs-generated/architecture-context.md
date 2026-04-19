---
service: "gcp-aiaas-cloud-functions"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumAiaasAidgFunction"
    - "continuumAiaasDealScoreFunction"
    - "continuumAiaasGoogleScraperFunction"
    - "continuumAiaasInferPdsApiService"
    - "continuumAiaasMadInferPdsApiService"
    - "continuumAiaasInferPdsV3Function"
    - "continuumAiaasPdsPriorityFunction"
    - "continuumAiaasSocialLinkScraperFunction"
    - "continuumAiaasPostgres"
    - "continuumAiaasLangSmith"
    - "continuumAiaasTinyUrlApi"
---

# Architecture Context

## System Context

The GCP AIaaS Cloud Functions platform sits within Groupon's **Continuum** system as a collection of AI inference workers. Merchant advisors and sales tooling (primarily Salesforce-based) call these functions to enrich merchant accounts with AI-generated content, ML-predicted scores, and taxonomy classifications. The functions delegate intelligence work to external AI platforms (OpenAI, Vertex AI), gather merchant data from Salesforce CRM and web scraping services (Apify), and persist enriched results back to Salesforce and a shared PostgreSQL database. There is no direct customer-facing exposure; all consumers are internal Groupon tooling or data pipelines.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| AIDG Cloud Function | `continuumAiaasAidgFunction` | CloudFunction | Python/Flask on GCP Cloud Functions | Generates AI deal structures from request parameters and scraped merchant context |
| Deal Score Cloud Function | `continuumAiaasDealScoreFunction` | CloudFunction | Python/Flask on GCP Cloud Functions | Scores deals and predicts expected revenue labels for merchant offers |
| Google Scraper Cloud Function | `continuumAiaasGoogleScraperFunction` | CloudFunction | Python/Flask on GCP Cloud Functions | Collects Google reviews and merchant signals, then computes merchant potential |
| InferPDS Cloud Run API | `continuumAiaasInferPdsApiService` | CloudRun | Python/FastAPI on GCP Cloud Run | FastAPI service for service extraction, matching, and enrichment from merchant websites |
| MAD InferPDS Cloud Run API | `continuumAiaasMadInferPdsApiService` | CloudRun | Python/FastAPI on GCP Cloud Run | Variant of InferPDS API with API-key protection and feedback endpoints |
| Infer PDS V3 Cloud Function | `continuumAiaasInferPdsV3Function` | CloudFunction (Legacy) | Python/Flask on GCP Cloud Functions | Legacy InferPDS function that scrapes and matches services |
| PDS Priority Cloud Function | `continuumAiaasPdsPriorityFunction` | CloudFunction | Python/Flask on GCP Cloud Functions | Queries BigQuery to return prioritized PDS records using request filters |
| Social Link Scraper Cloud Function | `continuumAiaasSocialLinkScraperFunction` | CloudFunction | Python/Flask on GCP Cloud Functions | Extracts social media links from merchant websites with optional Instagram enrichment |
| AIaaS PostgreSQL Database | `continuumAiaasPostgres` | Database | PostgreSQL | Persisted scraped and feature data for AIaaS cloud functions |
| LangSmith | `continuumAiaasLangSmith` | SaaS (External) | SaaS | External tracing and feedback telemetry platform |
| TinyURL API | `continuumAiaasTinyUrlApi` | API (External) | API | External URL shortening API |

## Components by Container

### AIDG Cloud Function (`continuumAiaasAidgFunction`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| AIDG Request Handler | Validates request parameters (`pds_cat_id`, `city`, `area_tier`, `account_id`) and dispatches generation workflow | Flask Handler |
| Deal Generation Engine | Builds structured deal data from category, city, and tier inputs using OpenAI prompts | Domain Service |
| Postgres Adapter | Loads scraped merchant text by account ID from the `aidg.inferpds_scraped_data` table in PostgreSQL | Repository Adapter |

### Deal Score Cloud Function (`continuumAiaasDealScoreFunction`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deal Score Request Handler | Handles CORS preflight, validates required fields (`pds`, `title`, `content`), and shapes the scoring request | Flask Handler |
| Feature Extractor | Derives text and merchant features (word count, readability scores, red flags) required for Vertex AI inference | Feature Pipeline |
| Prediction Client | Calls Vertex AI model endpoint (`prj-grp-aiaas-stable-6113`, `us-central1`) for revenue prediction | ML Adapter |
| Response Builder | Builds normalized success and error payloads including revenue label, extracted features, and deal summary | Response Mapper |

### Google Scraper Cloud Function (`continuumAiaasGoogleScraperFunction`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Google Scraper Request Handler | Parses request parameters (`accountId`, `url`, `merchantName`, `city`, `state`, `postalCode`, `countryCode`, `pds`) and coordinates scraping | Flask Handler |
| Review Collector | Collects Google review and merchant profile signals via Apify actors | Scraping Adapter |
| Merchant Potential Scorer | Runs feature extraction and Vertex AI / LightGBM prediction for merchant potential classification | Scoring Service |
| Salesforce Updater | Persists computed merchant potential fields (`Workable_Merchant__c`, `Hero_PDS__c`, `Location_Tier__c`) back to Salesforce | CRM Adapter |

### InferPDS Cloud Run API (`continuumAiaasInferPdsApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Endpoints | Exposes FastAPI endpoints including `POST /extract-services` and `GET /health` | FastAPI Router |
| Extraction Orchestrator | Coordinates scraping mode (Playwright browser vs. Apify), HTML parsing, and service extraction execution | Application Service |
| Matching Engine | Resolves extracted services against PDS taxonomy using OpenAI embeddings and cosine similarity | Matching Engine |
| Persistence Adapter | Reads and writes account-linked scraping data in tables `aidg.inferpds_services` and `aidg.inferpds_scraped_data`; updates Salesforce account taxonomy metadata | Persistence Adapter |

### MAD InferPDS Cloud Run API (`continuumAiaasMadInferPdsApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Endpoints | Exposes authenticated FastAPI endpoints for extraction and ops controls | FastAPI Router |
| Extraction Orchestrator | Coordinates dual scraping and extraction in optimized request flows | Application Service |
| Matching Engine | Matches extracted services with OpenAI-assisted ranking and validation | Matching Engine |
| Persistence Adapter | Updates account records and scraped payload storage through integration adapters | Persistence Adapter |

### Infer PDS V3 Cloud Function (`continuumAiaasInferPdsV3Function`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| InferPDS V3 Request Handler | Handles request parsing (`accountId`, `url`) and endpoint response assembly with `pds`, `newServices`, `existingServices`, `scrapedData` | Flask Handler |
| InferPDS V3 Inference Engine | Executes scraping (Apify + Playwright), service extraction, and GPT-based service matching | Inference Engine |
| Salesforce Adapter | Reads account seed data and writes matched taxonomy service IDs back to Salesforce | CRM Adapter |

### PDS Priority Cloud Function (`continuumAiaasPdsPriorityFunction`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| PDS Priority Request Handler | Parses allowed filter parameters (`accountId`, `city`, `country`, `pdsCatName`, `merchantPotential`, etc.) from JSON body or query string | Flask Handler |
| BigQuery Client | Builds and executes parameterized queries against `prj-grp-dataview-prod-1ff9.supply.acc_information_pds` | Data Access Adapter |

### Social Link Scraper Cloud Function (`continuumAiaasSocialLinkScraperFunction`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Social Link Request Handler | Validates `merchantUrl` and optional parameters (`maxPages`, `timeout`, `scrapeInstagram`, `apifyToken`) | Flask Handler |
| Crawler | Fetches merchant pages (up to `maxPages`), extracts social links from anchor tags and JSON-LD `sameAs` blocks | Crawler |
| Apify Adapter | Optionally enriches discovered Instagram usernames through Apify actor `dSCLg0C3YEZ83HzYX` | SaaS Adapter |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAiaasAidgFunction` | `continuumAiaasPostgres` | Reads scraped merchant text by account from `aidg.inferpds_scraped_data` | PostgreSQL (psycopg2) |
| `continuumAiaasAidgFunction` | `openAi` | Generates AI deal structures via Chat Completions API | HTTPS / REST |
| `continuumAiaasDealScoreFunction` | `vertexAi` | Invokes revenue prediction endpoint on Vertex AI | HTTPS / REST |
| `continuumAiaasDealScoreFunction` | `salesForce` | Reads merchant account details for feature extraction | HTTPS / REST |
| `continuumAiaasDealScoreFunction` | `openAi` | Generates deal summary card content | HTTPS / REST |
| `continuumAiaasGoogleScraperFunction` | `salesForce` | Reads and updates merchant account attributes | HTTPS / REST |
| `continuumAiaasGoogleScraperFunction` | `vertexAi` | Scores merchant potential | HTTPS / REST |
| `continuumAiaasGoogleScraperFunction` | `openAi` | Classifies review sentiment and flags | HTTPS / REST |
| `continuumAiaasGoogleScraperFunction` | `apify` | Fetches Google place and review data | HTTPS / REST |
| `continuumAiaasGoogleScraperFunction` | `continuumAiaasTinyUrlApi` | Shortens review URLs | HTTPS / REST |
| `continuumAiaasInferPdsApiService` | `openAi` | Runs chat and embeddings APIs for extraction and matching | HTTPS / REST |
| `continuumAiaasInferPdsApiService` | `salesForce` | Reads and updates account taxonomy metadata | HTTPS / REST |
| `continuumAiaasInferPdsApiService` | `continuumAiaasPostgres` | Reads and persists scraped and matched data | PostgreSQL (psycopg2) |
| `continuumAiaasInferPdsApiService` | `continuumAiaasLangSmith` | Publishes traces and user feedback | HTTPS / REST |
| `continuumAiaasInferPdsApiService` | `apify` | Scrapes merchant pages when configured | HTTPS / REST |
| `continuumAiaasMadInferPdsApiService` | `openAi` | Runs chat and embeddings APIs for extraction and matching | HTTPS / REST |
| `continuumAiaasMadInferPdsApiService` | `salesForce` | Reads and updates account taxonomy metadata | HTTPS / REST |
| `continuumAiaasMadInferPdsApiService` | `continuumAiaasPostgres` | Reads and persists scraped and matched data | PostgreSQL (psycopg2) |
| `continuumAiaasMadInferPdsApiService` | `continuumAiaasLangSmith` | Publishes traces and user feedback | HTTPS / REST |
| `continuumAiaasInferPdsV3Function` | `openAi` | Runs legacy extraction and validation prompts | HTTPS / REST |
| `continuumAiaasInferPdsV3Function` | `salesForce` | Reads and updates account taxonomy metadata | HTTPS / REST |
| `continuumAiaasInferPdsV3Function` | `apify` | Scrapes merchant pages | HTTPS / REST |
| `continuumAiaasPdsPriorityFunction` | `bigQuery` | Queries current PDS priority datasets | BigQuery API |
| `continuumAiaasSocialLinkScraperFunction` | `apify` | Enriches Instagram profiles | HTTPS / REST |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumAiaasAidgFunction`
- Component: `components-continuumAiaasDealScoreFunction`
- Component: `components-continuumAiaasGoogleScraperFunction`
- Component: `components-continuumAiaasInferPdsApiService`
- Component: `components-continuumAiaasMadInferPdsApiService`
- Component: `components-continuumAiaasPdsPriorityFunction`
- Component: `components-continuumAiaasSocialLinkScraperFunction`
- Dynamic flow: `dynamic-infer-pds-extraction-flow`
