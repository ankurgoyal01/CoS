---
service: "gcp-aiaas-cloud-functions"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 6
internal_count: 1
---

# Integrations

## Overview

The AIaaS platform integrates with six external systems: OpenAI (LLM inference and embeddings), Vertex AI (custom ML model prediction), Salesforce CRM (merchant account read/write), Apify (web scraping actors), LangSmith (AI tracing), and TinyURL (URL shortening). One internal dependency exists: the shared AIaaS PostgreSQL database. Most integrations are synchronous HTTP/REST calls made during request processing.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| OpenAI API | REST (HTTPS) | Chat completions and embeddings for deal generation, service extraction, sentiment classification, and matching | yes | `openAi` |
| Vertex AI | REST (HTTPS) | Custom ML model prediction for merchant potential scoring and deal revenue label prediction | yes | `vertexAi` |
| Salesforce CRM | REST (HTTPS) | Reads merchant account seed data; writes enriched PDS taxonomy metadata and merchant potential scores | yes | `salesForce` |
| Apify | REST (HTTPS) | Fetches Google Places/review data and scrapes merchant web pages via actor tasks | yes | `apify` |
| LangSmith | REST (HTTPS) | Publishes AI trace events and receives dynamic prompt configurations | no | `continuumAiaasLangSmith` |
| TinyURL API | REST (HTTPS) | Shortens merchant review URLs before writing to Salesforce | no | `continuumAiaasTinyUrlApi` |

### OpenAI API Detail

- **Protocol**: HTTPS REST
- **SDK**: `openai` Python SDK (versions 1.3.0–1.77.0 depending on function)
- **Auth**: `OPENAI_API_KEY` environment variable
- **Purpose**: Used by AIDG for deal structure prompt generation; by InferPDS functions for service extraction from page text and cosine-similarity-based taxonomy matching via text embeddings; by Google Scraper for review sentiment classification; by Deal Score for summary card generation
- **Failure mode**: Returns `500` error to caller with status `MODEL_PREDICTION_ERROR` or `INTERNAL_ERROR`; no automatic retry in evidence
- **Circuit breaker**: No evidence found in codebase

### Vertex AI Detail

- **Protocol**: HTTPS REST
- **SDK**: `google-cloud-aiplatform` Python SDK (versions 1.91.0 / >=1.38.0)
- **Auth**: GCP service account (application default credentials or `GOOGLE_APPLICATION_CREDENTIALS_JSON`)
- **Purpose**: Invoked by Deal Score function for revenue label prediction (`prj-grp-aiaas-stable-6113`, region `us-central1`, endpoint `1617826906667745280`); invoked by Google Scraper for merchant potential classification
- **Failure mode**: Returns `500 MODEL_PREDICTION_ERROR` to caller; falls back to LightGBM local model if `test=true` query parameter is set in Google Scraper
- **Circuit breaker**: No evidence found in codebase

### Salesforce CRM Detail

- **Protocol**: HTTPS REST
- **SDK**: `simple-salesforce` Python library (version 1.12.6)
- **Auth**: Username + password + security token; configured via `SF_CLIENT_ID`, `SF_CLIENT_SECRET`, `SF_USERNAME`, `SF_PASSWORD`, `SF_INSTANCE_URL` environment variables; falls back to hardcoded dev instance (`groupon-dev.my.salesforce.com`)
- **Purpose**: All functions that operate on a merchant account read seed data (account URL, PDS, city) from Salesforce. Google Scraper and InferPDS functions write back enriched fields (`Workable_Merchant__c`, `Hero_PDS__c`, `Location_Tier__c`, taxonomy service IDs)
- **Failure mode**: Google Scraper logs a warning and continues without Salesforce update if authentication fails; InferPDS services degrade gracefully by skipping Salesforce persistence
- **Circuit breaker**: No evidence found in codebase

### Apify Detail

- **Protocol**: HTTPS REST
- **SDK**: `apify-client` Python SDK (versions 0.6.0 / 1.7.1)
- **Auth**: `APIFY_TOKEN` / `APIFY_API_TOKEN` / `APIFY_API_KEY` environment variable; or `apifyToken` request parameter for Social Link Scraper
- **Purpose**: Google Scraper uses Apify to collect Google Places merchant profiles and review data; InferPDS V3 uses Apify to scrape merchant website pages; Social Link Scraper optionally uses Apify actor `dSCLg0C3YEZ83HzYX` to enrich discovered Instagram usernames
- **Failure mode**: Social Link Scraper returns an error description in the `instagram_apify` field but completes the rest of the response; other functions propagate errors upward
- **Circuit breaker**: No evidence found in codebase

### LangSmith Detail

- **Protocol**: HTTPS REST
- **SDK**: `langsmith` Python SDK (0.4.x), `langchain` / `langchain-core`
- **Auth**: `LANGSMITH_API_KEY` environment variable
- **Purpose**: InferPDS Cloud Run API and MAD InferPDS wrap OpenAI client calls with `@traceable` decorators and LangSmith `wrap_openai()` to publish execution traces to project `InferPDS-Production` (or `InferPDS-Dev` / `InferPDS-Stable`). Dynamic prompt prefixes are driven by the `LANGSMITH_PROJECT` environment variable.
- **Failure mode**: Tracing failures are non-blocking; inference continues without traces
- **Circuit breaker**: Not applicable

### TinyURL API Detail

- **Protocol**: HTTPS REST
- **Auth**: No evidence of auth requirements found in codebase
- **Purpose**: Google Scraper shortens merchant review page URLs before persisting them to Salesforce account fields
- **Failure mode**: No explicit failure handling found; URL shortening failures would propagate as unhandled exceptions
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| AIaaS PostgreSQL Database | PostgreSQL (psycopg2) | Shared scrape-data and InferPDS service record store | `continuumAiaasPostgres` |

The InferPDS Cloud Run API and AIDG function share the same PostgreSQL database. InferPDS writes scraped content and matched services; AIDG reads scraped content for deal generation context.

## Consumed By

> Upstream consumers are tracked in the central architecture model. Based on code evidence, known consumers include Salesforce merchant advisor tooling, internal merchant intelligence dashboards (MAD — Merchant Advisor Dashboard), and ad-hoc data science scripts.

## Dependency Health

- **PostgreSQL**: AIDG function checks connection liveness on every request via a `SELECT 1` ping; reconnects automatically if the connection is dead. InferPDS API connects on-demand per request.
- **Salesforce**: Authentication is attempted at request time; failures are logged and execution continues without CRM persistence where safe to do so.
- **Vertex AI / OpenAI**: No health pre-check; failures surface as HTTP 500 errors with structured error payloads.
- **BigQuery**: PDS Priority function authenticates via service account JSON file on disk or `GOOGLE_APPLICATION_CREDENTIALS_JSON` environment variable; falls back to application default credentials for local testing.
- **Apify**: No health check; missing token returns a structured error in the response payload rather than raising an exception.
