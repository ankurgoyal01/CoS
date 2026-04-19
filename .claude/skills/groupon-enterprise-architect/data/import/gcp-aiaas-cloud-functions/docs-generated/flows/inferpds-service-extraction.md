---
service: "gcp-aiaas-cloud-functions"
title: "InferPDS Service Extraction"
generated: "2026-03-03"
type: flow
flow_name: "inferpds-service-extraction"
flow_type: synchronous
trigger: "HTTP POST to /extract-services with accountId or merchant URL"
participants:
  - "continuumAiaasInferPdsApiService"
  - "salesForce"
  - "apify"
  - "openAi"
  - "continuumAiaasPostgres"
  - "continuumAiaasLangSmith"
architecture_ref: "dynamic-infer-pds-extraction-flow"
---

# InferPDS Service Extraction

## Summary

The InferPDS Service Extraction flow is the core merchant intelligence pipeline. It scrapes a merchant's website to discover the services they offer, uses OpenAI embeddings to match those services against Groupon's PDS (Product and Deal Service) taxonomy, and persists the results to PostgreSQL and Salesforce. The flow also publishes AI execution traces to LangSmith for observability and prompt quality management. On repeat calls for the same account, the flow reads cached results from PostgreSQL before triggering a fresh scrape.

## Trigger

- **Type**: api-call
- **Source**: Internal merchant advisor tooling or Salesforce integration calling `POST /extract-services` on the InferPDS Cloud Run API
- **Frequency**: On-demand (per merchant taxonomy assignment request); can be forced fresh with `forceNewScraping=true`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| InferPDS Cloud Run API | Entry point; validates request, routes to extraction orchestrator | `continuumAiaasInferPdsApiService` |
| HTTP Endpoints | Exposes FastAPI routes, handles authentication | `continuumAiaasInferPdsApiService_inferPdsApiHttpEndpoints` |
| Extraction Orchestrator | Coordinates scraping mode selection, parsing, and service extraction | `continuumAiaasInferPdsApiService_inferPdsExtractionOrchestrator` |
| Matching Engine | Resolves extracted services against PDS taxonomy via embeddings | `continuumAiaasInferPdsApiService_inferPdsMatchingEngine` |
| Persistence Adapter | Reads and writes PostgreSQL; updates Salesforce | `continuumAiaasInferPdsApiService_inferPdsPersistenceAdapter` |
| Salesforce CRM | Source of account seed data (URL, PDS); target for taxonomy write-back | `salesForce` |
| Apify | Scrapes merchant website pages when Playwright is not sufficient | `apify` |
| OpenAI | Extracts services from page text; computes embeddings for matching | `openAi` |
| AIaaS PostgreSQL Database | Caches scraped pages and matched service records | `continuumAiaasPostgres` |
| LangSmith | Receives AI execution traces for observability and prompt management | `continuumAiaasLangSmith` |

## Steps

1. **Receive extraction request**: HTTP Endpoints receive `POST /extract-services` with `accountId` or `url` in the request body.
   - From: Caller
   - To: `continuumAiaasInferPdsApiService`
   - Protocol: HTTPS REST (FastAPI)

2. **Read account seed data from Salesforce**: If `accountId` is provided, the Persistence Adapter reads the merchant's website URL and existing taxonomy metadata from Salesforce.
   - From: `continuumAiaasInferPdsApiService_inferPdsExtractionOrchestrator`
   - To: `salesForce`
   - Protocol: HTTPS REST (simple-salesforce)

3. **Check PostgreSQL cache**: The Persistence Adapter queries `aidg.inferpds_services` and `aidg.inferpds_scraped_data` for existing records for the account. Returns cached results if found (unless `forceNewScraping=true` or `forceNewMatching=true`).
   - From: `continuumAiaasInferPdsApiService_inferPdsPersistenceAdapter`
   - To: `continuumAiaasPostgres`
   - Protocol: PostgreSQL (psycopg2)

4. **Scrape merchant website**: If no cached data, the Extraction Orchestrator uses Playwright (headless Chromium) to fetch up to `maxPagesToScrape` (default 8) pages from the merchant website. Falls back to Apify actors for difficult pages.
   - From: `continuumAiaasInferPdsApiService_inferPdsExtractionOrchestrator`
   - To: `apify` (conditional)
   - Protocol: HTTPS REST (apify-client)

5. **Extract services from page content**: The Extraction Orchestrator sends scraped page text to OpenAI Chat Completions (model `gpt-4.1-mini-2025-04-14` by default) with extraction prompts managed by LangSmith. Extracts service names, prices, descriptions, and categories.
   - From: `continuumAiaasInferPdsApiService_inferPdsExtractionOrchestrator`
   - To: `openAi`
   - Protocol: HTTPS REST (openai SDK, wrapped with LangSmith `wrap_openai`)

6. **Publish execution trace**: LangSmith receives the trace of the OpenAI call including inputs, outputs, latency, and metadata for the `InferPDS-Production` project.
   - From: `continuumAiaasInferPdsApiService_inferPdsExtractionOrchestrator`
   - To: `continuumAiaasLangSmith`
   - Protocol: HTTPS REST (langsmith SDK)

7. **Match services against PDS taxonomy**: The Matching Engine computes OpenAI embeddings for each extracted service and compares them against the PDS taxonomy using cosine similarity. Services scoring above `similarityThreshold` (default 0.25) are matched.
   - From: `continuumAiaasInferPdsApiService_inferPdsMatchingEngine`
   - To: `openAi`
   - Protocol: HTTPS REST (OpenAI Embeddings API)

8. **Persist scraped pages and matched services**: The Persistence Adapter writes scraped page records to `aidg.inferpds_scraped_data` and matched service records (with taxonomy IDs, similarity scores) to `aidg.inferpds_services`.
   - From: `continuumAiaasInferPdsApiService_inferPdsPersistenceAdapter`
   - To: `continuumAiaasPostgres`
   - Protocol: PostgreSQL (psycopg2)

9. **Update Salesforce account taxonomy metadata**: Matched taxonomy service IDs and summary data are written back to the merchant's Salesforce account record.
   - From: `continuumAiaasInferPdsApiService_inferPdsPersistenceAdapter`
   - To: `salesForce`
   - Protocol: HTTPS REST (simple-salesforce)

10. **Return extraction response**: The service returns `pds`, `newServices`, `existingServices`, `scrapedData`, and `summary` arrays with HTTP 200.
    - From: `continuumAiaasInferPdsApiService`
    - To: Caller
    - Protocol: HTTPS REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No `accountId` and no `url` | Return `400 INFERPDS_MISSING_INPUT` | Structured error response |
| PostgreSQL unavailable | Log warning; proceed with fresh scraping | Scraping runs without cache lookup; results may not be persisted |
| Playwright scraping fails | Fall back to Apify actor; log failure | Extraction may have reduced page coverage |
| OpenAI extraction fails | Log error; return empty services arrays | Empty `pds`, `newServices` in response |
| Salesforce update fails | Log warning; continue | Taxonomy metadata not written to CRM; local results still returned |
| Unexpected exception | Return `500 INFERPDS_INTERNAL_ERROR` | Full error response with `scrapedData` always included |

## Sequence Diagram

```
Caller -> InferPdsAPI: POST /extract-services {accountId: X}
InferPdsAPI -> Salesforce: Read account URL and existing taxonomy metadata
Salesforce --> InferPdsAPI: Account seed data
InferPdsAPI -> PostgreSQL: Check aidg.inferpds_services and aidg.inferpds_scraped_data
PostgreSQL --> InferPdsAPI: Cached services and scraped pages (or empty)
InferPdsAPI -> Playwright: Fetch merchant website pages (up to maxPagesToScrape)
Playwright --> InferPdsAPI: Page HTML content
InferPdsAPI -> Apify: Scrape difficult pages (conditional)
Apify --> InferPdsAPI: Page content
InferPdsAPI -> OpenAI: Extract services from page text (Chat Completions)
OpenAI --> InferPdsAPI: Extracted service list
InferPdsAPI -> LangSmith: Publish execution trace
InferPdsAPI -> OpenAI: Compute embeddings for extracted services
OpenAI --> InferPdsAPI: Embedding vectors
InferPdsAPI -> InferPdsAPI: Cosine similarity match against PDS taxonomy
InferPdsAPI -> PostgreSQL: Write inferpds_scraped_data and inferpds_services
PostgreSQL --> InferPdsAPI: Write confirmation
InferPdsAPI -> Salesforce: Update account taxonomy metadata
Salesforce --> InferPdsAPI: Update confirmation
InferPdsAPI --> Caller: 200 {pds, newServices, existingServices, scrapedData, summary}
```

## Related

- Architecture dynamic view: `dynamic-infer-pds-extraction-flow`
- Related flows: [AI Deal Structure Generation](ai-deal-structure-generation.md) (downstream consumer of PostgreSQL scrape data)
