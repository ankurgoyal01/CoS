---
service: "lead-gen"
title: "Lead Scraping Pipeline"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "lead-scraping-pipeline"
flow_type: scheduled
trigger: "n8n scheduled trigger or manual API call to /api/leads/scrape"
participants:
  - "leadGenWorkflows"
  - "leadGenService"
  - "apify"
  - "leadGenDb"
architecture_ref: "components-continuum-leadgen-service"
---

# Lead Scraping Pipeline

## Summary

The Lead Scraping Pipeline is the entry point of the lead generation funnel. It uses Apify actors to scrape potential merchant leads from web sources (primarily Google Places-backed data), receives the structured results, deduplicates them against existing records in the database, and persists new lead records for downstream enrichment. This flow runs on a scheduled cadence via n8n and can also be triggered manually through the API.

## Trigger

- **Type**: schedule or api-call
- **Source**: n8n cron schedule (daily) or manual `POST /api/leads/scrape` with region/category parameters
- **Frequency**: Daily (scheduled) plus on-demand via API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LeadGen Workflows | Schedules and triggers the scraping job | `leadGenWorkflows` |
| LeadGen Service | Orchestrates Apify call, processes results, deduplicates, and persists | `leadGenService` |
| Apify | Executes web scraping actors and returns structured lead data | `apify` |
| LeadGen DB | Stores scraped and deduplicated lead records | `leadGenDb` |

## Steps

1. **Workflow triggers scrape job**: n8n workflow fires on schedule or receives a webhook trigger and calls the LeadGen Service scrape endpoint
   - From: `leadGenWorkflows`
   - To: `leadGenService`
   - Protocol: Internal (HTTP)

2. **Service configures and launches Apify actor**: LeadGen Service constructs Apify actor parameters (region, category, batch size) and invokes the Apify Actor Run API
   - From: `leadGenService`
   - To: `apify`
   - Protocol: API (REST)

3. **Apify executes scraping and returns results**: Apify actor scrapes web sources (Google Places and other directories), extracts business data (name, address, phone, email, website), and returns structured results
   - From: `apify`
   - To: `leadGenService`
   - Protocol: API (REST callback or polling)

4. **Service deduplicates results**: LeadGen Service compares scraped leads against existing records in the database using business name, address, and phone as deduplication keys
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (SELECT queries)

5. **Service persists new leads**: New (non-duplicate) leads are bulk-inserted into the `leads` table with status "scraped"
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (INSERT)

6. **Workflow logs completion**: n8n workflow records execution status and metrics to the database
   - From: `leadGenWorkflows`
   - To: `leadGenDb`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Apify actor fails to start | Retry with backoff; alert if max retries exceeded | Scraping halted; no new leads for this batch |
| Apify returns empty results | Log warning; mark workflow run as "empty result" | Pipeline proceeds but no new leads added |
| Apify returns malformed data | Validation rejects invalid records; valid records proceed | Partial batch ingested; errors logged for investigation |
| Deduplication query fails (DB unavailable) | Workflow fails and retries on next schedule | Entire batch deferred to next run |
| Bulk insert fails | Transaction rolled back; workflow marked as failed | No partial inserts; full batch retried |
| Apify API token expired | Auth error returned; alert triggered | Scraping halted until token is rotated |

## Sequence Diagram

```
leadGenWorkflows -> leadGenService: POST /api/leads/scrape (region, category)
leadGenService -> apify: Start actor run (params)
apify --> leadGenService: Scraping results (structured lead data)
leadGenService -> leadGenDb: Query existing leads for dedup (SELECT)
leadGenDb --> leadGenService: Existing lead records
leadGenService -> leadGenDb: Bulk insert new leads (INSERT)
leadGenDb --> leadGenService: Insert confirmation
leadGenService --> leadGenWorkflows: Scrape job result (count, status)
leadGenWorkflows -> leadGenDb: Log workflow completion (SQL)
```

## Related

- Architecture dynamic view: not yet defined -- see `components-continuum-leadgen-service`
- Related flows: [Lead Enrichment](lead-enrichment.md) (next step in pipeline)
- See [Integrations](../integrations.md) for Apify integration details
- See [Data Stores](../data-stores.md) for `leads` table schema
