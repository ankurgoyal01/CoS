---
service: "AIGO-ContentServices"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 3
---

# Integrations

## Overview

AIGO-ContentServices integrates with three external systems (OpenAI, Salesforce, and merchant websites) and three internal services that are part of the same platform (the four containers communicate with each other over HTTPS/JSON within the Kubernetes cluster). All external integrations are outbound HTTP calls initiated by the backend Python services.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| OpenAI API | rest (HTTPS) | LLM completions for content generation steps and web scraper AI agents | yes | `openAi` (stub) |
| Salesforce | rest (HTTPS) | Bulk query jobs to retrieve deal and merchant data | yes | `salesForce` (stub) |
| Merchant Websites | http (HTTPS/HTTP) | Web scraping of merchant domain pages to extract USPs | no | `merchantWebsites` (stub) |

### OpenAI API Detail

- **Protocol**: HTTPS REST
- **Base URL / SDK**: `openai` Python SDK; `OpenAI(api_key=os.getenv('OPENAI_API_KEY'))`
- **Auth**: API key via `OPENAI_API_KEY` environment variable
- **Purpose**: Used by `continuumContentGeneratorService` for multi-step deal copy generation (model default: `gpt-4o-mini`) and by `continuumWebScraperService` for link filtering, text cleaning, USP extraction, quality gating, and duplicate management AI agents
- **Failure mode**: HTTPException 500 propagated to caller; no retry or circuit breaker implemented
- **Circuit breaker**: No

### Salesforce Detail

- **Protocol**: HTTPS REST (Salesforce Bulk API v2)
- **Base URL / SDK**: `SF_INSTANCE_URL` env var (e.g., `https://groupon-dev.my.salesforce.com`); accessed via `requests` library
- **Auth**: OAuth login via `salesforce_login()` function; access token injected into bulk API calls
- **Purpose**: `cgSalesforceIntegration` creates bulk query jobs to retrieve deal data (merchant name, website, discount, sales points, description, options, conditions); results stored as CSV and served as JSON to the frontend
- **Failure mode**: HTTPException 401 on auth failure; 408 on polling timeout; 404 if no results found
- **Circuit breaker**: No

### Merchant Websites Detail

- **Protocol**: HTTPS/HTTP (headless Chromium via Selenium)
- **Base URL / SDK**: Dynamic — merchant domain URLs submitted at scrape time via `start_url` parameter
- **Auth**: None (public pages)
- **Purpose**: `wsCrawlerEngine` fetches merchant web pages; `wsScraperOrchestrator` filters links and extracts USPs using LLM agents
- **Failure mode**: Failed scrapes are skipped and logged (`None` result check); scraper continues to next link
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumPromptDatabaseService` | HTTPS/JSON | `continuumWebScraperService` queries `/agents/query` at crawl start to load AI agent configurations | `continuumPromptDatabaseService` |
| `continuumContentGeneratorService` | HTTPS/JSON | `continuumFrontendContentGenerator` POSTs to `/generate` and calls Salesforce endpoints | `continuumContentGeneratorService` |
| `continuumWebScraperService` | HTTPS/JSON | `continuumFrontendContentGenerator` POSTs to `/crawl` | `continuumWebScraperService` |

**Internal service base URLs (staging)**:
- Generator: `https://aigo-contentservices--generator.staging.service.us-central1.gcp.groupondev.com`
- Scraper: `https://aigo-contentservices--scraper.staging.service.us-central1.gcp.groupondev.com`
- Prompt DB: `https://aigo-contentservices--promptdb.staging.service.us-central1.gcp.groupondev.com` (also `http://aigo-contentservices--promptdb.staging.service` for scraper internal calls)

## Consumed By

> Upstream consumers are tracked in the central architecture model. The primary consumer is internal editorial/content operations staff via the `continuumFrontendContentGenerator` web UI.

## Dependency Health

- All backend services implement a `GET /grpn/healthcheck` endpoint returning `{"status": "OK"}`, configured as both readiness and liveness probes in Kubernetes deployment manifests.
- No circuit breaker patterns, retries, or health-check-based fallbacks are implemented for external dependencies (OpenAI, Salesforce).
- The Salesforce polling flow (`/salesforce/poll-job`) has a configurable retry loop with `max_attempts` (default 6), `interval` (default 10s), and `initial_wait` (default 10s) parameters.
