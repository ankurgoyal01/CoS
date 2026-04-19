---
service: "AIGO-ContentServices"
title: Overview
generated: "2026-03-03"
type: overview
domain: "AI Content Generation / Editorial Tooling"
platform: "Continuum"
team: "AIGO"
status: active
tech_stack:
  language: "Python / TypeScript"
  language_version: "3.12 / 5"
  framework: "FastAPI / Next.js"
  framework_version: "latest / 14.2.16"
  runtime: "CPython / Node.js"
  runtime_version: "3.12 / 20"
  build_tool: "Docker"
  package_manager: "pip / npm"
---

# AIGO-ContentServices Overview

## Purpose

AIGO-ContentServices is an internal AI-powered content generation platform that enables Groupon editorial teams to produce deal copy for merchant listings. It orchestrates multi-step LLM generation workflows fed by Salesforce deal data and merchant website scraping, while persisting AI agent configurations and editorial guidelines in a managed database.

## Scope

### In scope
- Multi-step LLM-driven generation of deal content sections (gallery title, API title, nutshell, introduction, what we offer, why you should grab the offer)
- Salesforce bulk-query integration for retrieving deal and merchant data
- AI-assisted web scraping of merchant domains to extract unique selling points (USPs)
- Prompt and editorial guideline management via a PostgreSQL-backed service (L1, L2, and taxonomy-group guideline tiers)
- Next.js web UI for deal selection, scrape triggering, content review, and generation settings
- Cost tracking per LLM generation step and globally per request

### Out of scope
- Publishing generated content directly to Groupon consumer-facing systems (content is reviewed by editors before publishing)
- Deal creation or modification in Salesforce (read-only integration)
- Consumer-facing search or deal browsing

## Domain Context

- **Business domain**: AI Content Generation / Editorial Tooling
- **Platform**: Continuum (GCP, Kubernetes via Raptor deploy)
- **Upstream consumers**: Internal editorial/content operations teams using the `continuumFrontendContentGenerator` UI
- **Downstream dependencies**: OpenAI API (LLM completions), Salesforce (deal data), merchant websites (scraping), PostgreSQL (guideline/agent storage)

## Stakeholders

| Role | Description |
|------|-------------|
| Editorial / Content Operations | Primary users of the frontend UI; review and publish generated deal copy |
| AIGO Engineering | Owners of the platform; responsible for LLM agent tuning and service operations |
| Merchant Partnerships | Indirect stakeholder; merchant data sourced from Salesforce feeds this platform |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (backend) | Python | 3.12 | `service_content_generator/Dockerfile`, `service_web_scraper/Dockerfile`, README |
| Language (frontend) | TypeScript | ^5 | `frontend-content-generator/package.json` |
| Framework (backend) | FastAPI | latest | `service_content_generator/requirements.txt` |
| Framework (frontend) | Next.js | ^14.2.16 | `frontend-content-generator/package.json` |
| Runtime (backend) | CPython | 3.12-slim (Docker) | `service_content_generator/Dockerfile` |
| Runtime (frontend) | Node.js | 20 | `frontend-content-generator/package.json` (`@types/node: ^20`) |
| Build tool | Docker | — | `Jenkinsfile`, per-service `Dockerfile` files |
| Package manager (backend) | pip | — | `requirements.txt` files |
| Package manager (frontend) | npm | — | `frontend-content-generator/package-lock.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `fastapi` | latest | http-framework | REST API framework for all three Python backend services |
| `uvicorn` | latest | http-framework | ASGI server running FastAPI applications |
| `openai` | latest | llm-client | OpenAI API SDK used for LLM completions in content generator and web scraper |
| `sqlalchemy` | latest | orm | ORM and data access layer for Prompt Database Service |
| `alembic` | latest | db-client | Database migration management for PostgreSQL schema |
| `psycopg2-binary` | latest | db-client | PostgreSQL driver for SQLAlchemy sessions |
| `pydantic` | latest | validation | Request/response schema validation and dynamic response model creation |
| `selenium` | latest | scraping | Chromium driver automation for web crawling in the scraper service |
| `beautifulsoup4` | latest | scraping | HTML parsing and content extraction in the scraper service |
| `pandas` | latest | data-processing | CSV parsing and data manipulation for Salesforce result processing |
| `simple-salesforce` | latest | integration | Salesforce API client (deprecated `/deals` endpoint) |
| `requests` | latest | http-client | HTTP client for Salesforce bulk query API and inter-service calls |
| `next` | ^14.2.16 | ui-framework | Server-side rendering and API routing for the frontend application |
| `@radix-ui/*` | ^1.x | ui-framework | Accessible UI component primitives (accordion, dialog, tabs, select, etc.) |
| `tiktoken` | latest | llm-client | Token counting for scraper LLM cost estimation |
