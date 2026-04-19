---
service: "AIGO-ContentServices"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for AIGO-ContentServices.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Multi-Step Content Generation](multi-step-content-generation.md) | synchronous | User submits generation request via frontend UI | Frontend collects deal and guideline data, POSTs to `/generate`; generator orchestrates multi-step LLM flow producing deal copy sections |
| [Merchant Web Scraping](merchant-web-scraping.md) | synchronous | User triggers scrape for a merchant URL in frontend | Frontend POSTs to `/crawl`; scraper crawls merchant domain with Chromium, applies AI agents to extract and rank USPs |
| [Salesforce Deal Data Refresh](salesforce-deal-data-refresh.md) | synchronous | User or operator calls Salesforce poll endpoint | Generator launches a Salesforce bulk query job, polls for completion, saves results as CSV, and serves them as JSON |
| [Prompt and Guideline Retrieval](prompt-and-guideline-retrieval.md) | synchronous | Frontend or scraper fetches agents/guidelines before generation | Frontend fetches L1/L2/TG guidelines; scraper fetches agent configurations; both use Prompt Database Service REST API backed by PostgreSQL |
| [Agent Configuration Management](agent-configuration-management.md) | synchronous | AIGO engineer creates/updates/queries agent records via API | CRUD operations on agent configurations (name, version, role, prompt, response_class) in Prompt Database Service |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in AIGO-ContentServices are cross-service by nature:

- **Multi-Step Content Generation** spans `continuumFrontendContentGenerator` → `continuumContentGeneratorService` → OpenAI API + Salesforce. See [Multi-Step Content Generation](multi-step-content-generation.md).
- **Merchant Web Scraping** spans `continuumFrontendContentGenerator` → `continuumWebScraperService` → `continuumPromptDatabaseService` → OpenAI API + merchant websites. See [Merchant Web Scraping](merchant-web-scraping.md).
- **Salesforce Deal Data Refresh** is contained within `continuumContentGeneratorService` → Salesforce. See [Salesforce Deal Data Refresh](salesforce-deal-data-refresh.md).
