---
service: "gcp-aiaas-cloud-functions"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Merchant Intelligence / AI-assisted Deal Operations"
platform: "GCP (Continuum AIaaS)"
team: "AIaaS / Merchant Advisor"
status: active
tech_stack:
  language: "Python"
  language_version: "3.11"
  framework: "Flask / FastAPI"
  framework_version: "Flask 3.0.2 / FastAPI 0.104+"
  runtime: "GCP Cloud Functions gen2 / GCP Cloud Run"
  runtime_version: "functions-framework 3.x / uvicorn"
  build_tool: "pip / Docker"
  package_manager: "pip"
---

# GCP AIaaS Cloud Functions Overview

## Purpose

GCP AIaaS Cloud Functions is a suite of Python-based serverless functions and containerized Cloud Run services that provides AI-powered merchant intelligence for Groupon's supply and deal operations. The platform ingests merchant data (from Salesforce CRM, Google Places, and scraped web content) and applies large language models, embedding-based matching, and ML inference to automate deal structure generation, merchant potential scoring, and PDS (Product and Deal Service) taxonomy classification. It exists to reduce manual merchant analyst effort and improve deal quality at scale.

## Scope

### In scope
- AI-generated deal structure creation from merchant context and category inputs (`aidg` function)
- Deal revenue scoring and label prediction using Vertex AI ML models (`deal_score` function)
- Google Places and review scraping with merchant potential classification (`google_scraper` function)
- Service extraction and PDS taxonomy matching from merchant websites via OpenAI embeddings (`inferpds_cloud_run_api`, `mad_inferpds_cloud_run_api`)
- Legacy PDS inference via scraping and GPT prompts (`infer_pds_v3` function)
- PDS priority record retrieval from BigQuery supply datasets (`pds_priority` function)
- Social media link discovery and Instagram enrichment from merchant websites (`social_link_scraper` function)
- LangSmith-based AI trace publishing and feedback loops for prompt quality management

### Out of scope
- Deal publishing or activation (handled by downstream Continuum commerce systems)
- Merchant onboarding workflows (handled by Salesforce CRM and sales tooling)
- Customer-facing deal recommendation (handled by separate recommendation services)
- Billing and payment processing

## Domain Context

- **Business domain**: Merchant Intelligence / AI-assisted Deal Operations
- **Platform**: Continuum AIaaS on GCP
- **Upstream consumers**: Salesforce merchant advisor tooling, internal merchant intelligence dashboards, and manual API calls by merchant advisors and data scientists
- **Downstream dependencies**: OpenAI Chat and Embeddings APIs, Vertex AI prediction endpoints, Salesforce CRM API, Apify web scraping actors, BigQuery supply datasets, PostgreSQL AIaaS database, LangSmith tracing platform, TinyURL API

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Advisor / Sales Rep | Triggers deal generation and merchant scoring workflows via Salesforce tooling |
| Data Scientist / ML Engineer | Maintains and evaluates ML models hosted on Vertex AI; reviews LangSmith traces |
| AIaaS Platform Team | Owns and operates the Cloud Functions and Cloud Run services |
| Supply Operations | Consumes PDS priority data for deal sourcing decisions |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.11 | `inferpds_cloud_run_api/Dockerfile` (playwright:v1.40.0-jammy base) |
| Framework (Functions) | Flask | 3.0.2 | `aidg/src/requirements.txt` |
| Framework (Cloud Run) | FastAPI | >=0.104.0 | `inferpds_cloud_run_api/requirements.txt` |
| ASGI server | uvicorn | >=0.24.0 | `inferpds_cloud_run_api/requirements.txt` |
| Runtime (Functions) | GCP Cloud Functions gen2 (functions-framework) | 3.x | `deal_score/src/requirements.txt`, `google_scraper/src/requirements.txt` |
| Runtime (Cloud Run) | GCP Cloud Run | n/a | `inferpds_cloud_run_api/Dockerfile` |
| Build tool | pip + Docker | n/a | `inferpds_cloud_run_api/Dockerfile`, `mad_inferpds_cloud_run_api/Dockerfile` |
| Package manager | pip | n/a | `requirements.txt` files across all functions |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `openai` | 1.72.0 – 1.77.0 | ai-client | Chat completions and embeddings for deal generation, service extraction, sentiment classification |
| `langsmith` | 0.4.x | observability | Distributed tracing and prompt management for OpenAI calls |
| `langchain` / `langchain-core` | 0.2+ / 0.3.x | ai-framework | LangChain integration for InferPDS orchestration |
| `fastapi` | >=0.104.0 | http-framework | REST API framework for Cloud Run services |
| `flask` | 2.x – 3.0.2 | http-framework | HTTP handler framework for Cloud Functions |
| `pydantic` | >=2.5.0 | validation | Request/response schema validation in FastAPI services |
| `simple-salesforce` | 1.12.6 | crm-client | Salesforce REST API client for reading and updating account records |
| `google-cloud-aiplatform` | 1.91.0 | ml-client | Vertex AI prediction endpoint calls for merchant potential and deal revenue scoring |
| `google-cloud-bigquery` | 3.x | db-client | BigQuery queries for PDS priority datasets |
| `psycopg2-binary` | 2.9.9 | db-client | PostgreSQL adapter for AIaaS scraped-data and services database |
| `playwright` | 1.40.0 – 1.50.0 | browser-automation | Headless Chromium page scraping for merchant website extraction |
| `beautifulsoup4` | 4.12.x | html-parsing | HTML parsing for merchant page content and link extraction |
| `apify-client` | 0.6.0 – 1.7.1 | scraping-client | Apify actor integration for Google Places data and Instagram enrichment |
| `sentence-transformers` | 3.0.0 – 4.1.0 | ml | Sentence embedding models used in service matching pipelines |
| `scikit-learn` | 1.3.0 – 1.6.1 | ml | Cosine similarity, LightGBM feature preparation, and classification utilities |
| `google-cloud-secret-manager` | 2.20.0 | secrets | GCP Secret Manager access for credentials in Cloud Functions |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
