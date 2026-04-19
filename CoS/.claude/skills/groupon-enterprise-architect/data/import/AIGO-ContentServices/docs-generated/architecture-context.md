---
service: "AIGO-ContentServices"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumFrontendContentGenerator"
    - "continuumContentGeneratorService"
    - "continuumWebScraperService"
    - "continuumPromptDatabaseService"
    - "continuumPromptDatabasePostgres"
---

# Architecture Context

## System Context

AIGO-ContentServices is a sub-system of the `continuumSystem` (Continuum Platform). It provides internal editorial tooling for AI-assisted deal copy production. Content operations teams access the system through a Next.js web UI; the UI delegates all computation to three Python FastAPI backend services. The platform depends on three external systems: OpenAI (LLM completions), Salesforce (deal and merchant data via bulk query), and public merchant websites (scraping targets).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Frontend Content Generator | `continuumFrontendContentGenerator` | WebApp | TypeScript, Next.js | 14.2.16 | Next.js web UI for deal selection, scraping triggers, generation setup, and content review |
| Content Generator Service | `continuumContentGeneratorService` | Backend | Python, FastAPI | Python 3.12 | FastAPI service that runs multi-step LLM content generation and Salesforce retrieval flows |
| Web Scraper Service | `continuumWebScraperService` | Backend | Python, FastAPI | Python 3.12 | FastAPI and CLI scraper that crawls merchant pages and extracts USPs with LLM assistance |
| Prompt Database Service | `continuumPromptDatabaseService` | Backend | Python, FastAPI | Python 3.12 | FastAPI service exposing prompt agent configurations and editorial guideline APIs |
| Prompt Database PostgreSQL | `continuumPromptDatabasePostgres` | Database | PostgreSQL | latest | Stores agent configurations and editorial guideline data (L1, L2, TG tiers) |

## Components by Container

### Frontend Content Generator (`continuumFrontendContentGenerator`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `fgUi` — Generation UI | React/Next.js user interface for deal selection, generation setup, and review | TypeScript, React |
| `fgApiClient` — API Client Layer | Client-side fetch and Next.js route proxy integration to backend services | Next.js rewrites, fetch |

### Content Generator Service (`continuumContentGeneratorService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `cgGenerationApi` — Generation API | FastAPI endpoints for generation and Salesforce orchestration | Python, FastAPI |
| `cgGenerationOrchestrator` — Generation Orchestrator | Coordinates multi-step content flow, concurrent section processing, and cost tracking | Python, asyncio |
| `cgLlmClient` — LLM Client | Constructs prompts incorporating Salesforce data, scraper USPs, and guidelines; invokes OpenAI API | OpenAI SDK |
| `cgSalesforceIntegration` — Salesforce Integration | Handles Salesforce auth, bulk query job creation, polling, result processing, and CSV storage | Python, requests |

### Web Scraper Service (`continuumWebScraperService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `wsScraperApi` — Scraper API | FastAPI endpoint for crawl execution requests | Python, FastAPI |
| `wsScraperOrchestrator` — Scraper Orchestrator | Controls crawl loop, AI-driven link filtering, content quality gating, and USP aggregation | Python |
| `wsCrawlerEngine` — Crawler Engine | Web crawling and page content extraction using headless Chromium | Selenium, BeautifulSoup |

### Prompt Database Service (`continuumPromptDatabaseService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `pdAgentsApi` — Agents API | CRUD and query endpoints for AI agent configurations (name, version, role, prompt, response_class) | Python, FastAPI |
| `pdGuidelinesApi` — Guidelines API | Endpoints for L1, L2 (by category / PDS), and TG (by taxonomy group / PDS) editorial guideline retrieval | Python, FastAPI |
| `pdPromptRepository` — Prompt Repository | Data access layer and SQLAlchemy table definitions for agents, L1, L2, and TG guidelines | Python, SQLAlchemy |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumFrontendContentGenerator` | `continuumContentGeneratorService` | Calls content generation and Salesforce endpoints | HTTPS/JSON |
| `continuumFrontendContentGenerator` | `continuumPromptDatabaseService` | Calls agents and guidelines endpoints | HTTPS/JSON |
| `continuumFrontendContentGenerator` | `continuumWebScraperService` | Calls crawl endpoint | HTTPS/JSON |
| `continuumWebScraperService` | `continuumPromptDatabaseService` | Retrieves prompt agent configuration for scraper workflows | HTTPS/JSON |
| `continuumPromptDatabaseService` | `continuumPromptDatabasePostgres` | Stores and retrieves agent/guideline data | PostgreSQL (SQLAlchemy) |
| `continuumContentGeneratorService` | `openAi` | Uses LLM completions for generation tasks | HTTPS API |
| `continuumWebScraperService` | `openAi` | Uses LLM completions for crawl page selection and USP extraction | HTTPS API |
| `continuumContentGeneratorService` | `salesForce` | Retrieves deal information via bulk query jobs | HTTPS API |
| `continuumWebScraperService` | `merchantWebsites` | Crawls merchant web pages to collect source content | HTTPS |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (Content Generator): `components-continuumContentGeneratorService`
- Component (Frontend): `components-continuumFrontendContentGenerator`
- Component (Web Scraper): `components-continuumWebScraperService`
- Component (Prompt Database): `components-continuumPromptDatabaseService`
