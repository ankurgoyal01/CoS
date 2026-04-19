---
service: "gcp-aiaas-cloud-functions"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for GCP AIaaS Cloud Functions.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [AI Deal Structure Generation](ai-deal-structure-generation.md) | synchronous | API call with `pds_cat_id`, `city`, `area_tier`, `account_id` | Generates a structured deal from PDS category and scraped merchant context using OpenAI |
| [Deal Revenue Scoring](deal-revenue-scoring.md) | synchronous | API call with deal title, content, and PDS | Extracts deal features, calls Vertex AI for revenue prediction, and returns a labeled score with summary |
| [Merchant Potential Scoring via Google Scraper](merchant-potential-scoring.md) | synchronous | API call with `accountId` or merchant URL/name/city | Scrapes Google merchant data via Apify, extracts features, predicts potential category, and updates Salesforce |
| [InferPDS Service Extraction](inferpds-service-extraction.md) | synchronous | API call with `accountId` or URL to `POST /extract-services` | Scrapes merchant website, extracts offered services using OpenAI, matches against PDS taxonomy, persists results |
| [PDS Priority Query](pds-priority-query.md) | synchronous | API call with one or more filter parameters | Queries BigQuery supply dataset for prioritized PDS records matching the given filters |
| [Social Link Discovery](social-link-discovery.md) | synchronous | API call with `merchantUrl` | Crawls merchant website to discover social media links; optionally enriches Instagram profiles via Apify |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The InferPDS Service Extraction flow is documented as a cross-service dynamic view in the architecture DSL:

- `dynamic-infer-pds-extraction-flow` — spans `continuumAiaasInferPdsApiService`, Salesforce, Apify, OpenAI, and `continuumAiaasPostgres`

The AIDG deal generation flow implicitly depends on the InferPDS extraction flow having previously populated `continuumAiaasPostgres` with scraped merchant content. These two flows together form the complete merchant-to-deal pipeline.
