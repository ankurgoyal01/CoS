---
service: "lead-gen"
title: "Lead Enrichment"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "lead-enrichment"
flow_type: batch
trigger: "n8n trigger after scraping completes or manual API call to /api/leads/enrich"
participants:
  - "leadGenWorkflows"
  - "leadGenService"
  - "inferPDS"
  - "merchantQuality"
  - "leadGenDb"
architecture_ref: "components-continuum-leadgen-service"
---

# Lead Enrichment

## Summary

The Lead Enrichment flow takes scraped leads and augments them with business intelligence from two AIDG services: PDS (Probabilistic Data Service) inference for business categorization and predictive attributes, and merchant quality scoring for a composite quality assessment. The combined enrichment data is used to compute a final lead score that determines whether a lead qualifies for outreach. This flow runs after scraping completes and processes leads in batches with configurable concurrency.

## Trigger

- **Type**: schedule or api-call
- **Source**: n8n workflow triggered after a successful scraping run completes, or manual `POST /api/leads/enrich` with optional lead filters
- **Frequency**: After each scraping run (daily) plus on-demand via API

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LeadGen Workflows | Triggers enrichment job after scraping completes | `leadGenWorkflows` |
| LeadGen Service | Orchestrates enrichment calls, computes final score, persists results | `leadGenService` |
| InferPDS | Provides PDS inference enrichment data | `inferPDS` |
| Merchant Quality | Provides merchant quality score | `merchantQuality` |
| LeadGen DB | Stores enrichment results and updated lead status | `leadGenDb` |

## Steps

1. **Workflow triggers enrichment job**: n8n workflow detects scraping completion and calls the LeadGen Service enrichment endpoint with a batch of lead IDs or filter criteria
   - From: `leadGenWorkflows`
   - To: `leadGenService`
   - Protocol: Internal (HTTP)

2. **Service loads unenriched leads**: LeadGen Service queries the database for leads in "scraped" status that have not yet been enriched
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (SELECT)

3. **Service calls PDS inference**: For each lead in the batch, LeadGen Service sends business identifiers (name, address, category) to the inferPDS service and receives predictive business attributes
   - From: `leadGenService`
   - To: `inferPDS`
   - Protocol: REST

4. **Service calls merchant quality scoring**: For each lead, LeadGen Service sends business identifiers and PDS data to the merchantQuality service and receives a composite quality score
   - From: `leadGenService`
   - To: `merchantQuality`
   - Protocol: REST

5. **Service computes final lead score**: LeadGen Service combines PDS attributes and quality score into a final lead score, applying configurable weighting and threshold rules to determine outreach eligibility
   - From: `leadGenService`
   - To: `leadGenService`
   - Protocol: Internal computation

6. **Service persists enrichment results**: Enrichment data, quality score, and final lead score are written to the `lead_enrichment` table; lead status is updated to "enriched" or "qualified" based on score threshold
   - From: `leadGenService`
   - To: `leadGenDb`
   - Protocol: JDBC (INSERT/UPDATE)

7. **Workflow logs completion**: n8n workflow records enrichment batch metrics and execution status
   - From: `leadGenWorkflows`
   - To: `leadGenDb`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| InferPDS unavailable | Retry with backoff; if prolonged, skip PDS enrichment via feature flag | Lead enriched with quality score only; final score degraded |
| MerchantQuality unavailable | Retry with backoff; if prolonged, skip quality enrichment via feature flag | Lead enriched with PDS data only; final score degraded |
| Both enrichment services unavailable | Enrichment batch fails; workflow retries on next schedule | Leads remain in "scraped" status; no enrichment applied |
| Partial batch failure (some leads fail enrichment) | Failed leads remain in "scraped" status; successful leads proceed | Partial enrichment; failed leads retried in next batch |
| Database write failure | Transaction rolled back for affected batch | Enrichment results lost; batch retried |
| Enrichment returns unexpected data format | Validation rejects malformed response; lead skipped | Lead remains unenriched; error logged for investigation |

## Sequence Diagram

```
leadGenWorkflows -> leadGenService: POST /api/leads/enrich (batch params)
leadGenService -> leadGenDb: Load unenriched leads (SELECT)
leadGenDb --> leadGenService: Lead records
leadGenService -> inferPDS: Enrich with PDS (REST, per lead)
inferPDS --> leadGenService: PDS inference data
leadGenService -> merchantQuality: Enrich with quality score (REST, per lead)
merchantQuality --> leadGenService: Quality score data
leadGenService -> leadGenService: Compute final lead score
leadGenService -> leadGenDb: Persist enrichment results (INSERT/UPDATE)
leadGenDb --> leadGenService: Confirmation
leadGenService --> leadGenWorkflows: Enrichment result (count, status)
leadGenWorkflows -> leadGenDb: Log workflow completion (SQL)
```

## Related

- Architecture dynamic view: not yet defined -- see `components-continuum-leadgen-service`
- Related flows: [Lead Scraping Pipeline](lead-scraping-pipeline.md) (upstream), [Outreach Campaign](outreach-campaign.md) (downstream for qualified leads)
- See [Integrations](../integrations.md) for InferPDS and Merchant Quality integration details
- See [Data Stores](../data-stores.md) for `lead_enrichment` table schema
