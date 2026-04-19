---
service: "coffee-to-go"
title: "Data Ingestion from CRM and External Sources"
generated: "2026-03-03"
type: flow
flow_name: "data-ingestion-crm"
flow_type: batch
trigger: "Scheduled n8n workflows"
participants:
  - "coffeeWorkflows"
  - "salesForce"
  - "edw"
  - "deepScoutS3"
  - "coffeeDb"
---

# Data Ingestion from CRM and External Sources

## Summary

n8n ETL/ELT workflows run on a schedule to pull data from three external sources: Salesforce CRM (merchant accounts and sales opportunities), the Enterprise Data Warehouse (reviews and historical deal data), and DeepScout S3 (daily competitor export mapped to Groupon taxonomy). The workflows enrich and transform the data, then bulk-write it into the Coffee DB core tables. Job progress and status are tracked in the `job_metadata` table.

## Trigger

- **Type**: schedule
- **Source**: n8n workflow scheduler
- **Frequency**: Periodic (daily, inferred from the "daily competitor export" description)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| n8n Workflows | Orchestrates data extraction, transformation, and loading | `coffeeWorkflows` |
| Salesforce | Source of merchant account and opportunity data | `salesForce` |
| Enterprise Data Warehouse (EDW) | Source of reviews and historical deal data | `edw` |
| DeepScout S3 | Source of daily competitor data export | `deepScoutS3` |
| Coffee DB | Destination for all ingested and enriched data | `coffeeDb` |

## Steps

1. **n8n workflow triggers on schedule**: The n8n orchestrator starts the data ingestion workflow at the configured schedule.
   - From: `coffeeWorkflows` (scheduler)
   - To: `coffeeWorkflows` (workflow engine)
   - Protocol: Internal

2. **Pull accounts and opportunities from Salesforce**: The workflow calls the Salesforce REST API to fetch merchant account records and sales opportunity data.
   - From: `coffeeWorkflows`
   - To: `salesForce`
   - Protocol: REST API

3. **Pull reviews and historical deals from EDW**: The workflow executes batch queries against the Enterprise Data Warehouse to retrieve review data and historical deal performance metrics.
   - From: `coffeeWorkflows`
   - To: `edw`
   - Protocol: Batch

4. **Read competitor export from DeepScout S3**: The workflow reads the daily competitor data file from an S3 bucket. This data is pre-mapped to Groupon's taxonomy structure using S3 credentials.
   - From: `coffeeWorkflows`
   - To: `deepScoutS3`
   - Protocol: AWS S3

5. **Transform and enrich data**: The workflow transforms raw data into the Coffee DB schema, enriching records with computed fields, taxonomy mappings, and geographic data.
   - From: `coffeeWorkflows`
   - To: `coffeeWorkflows` (internal transformation)
   - Protocol: Internal

6. **Bulk write to Coffee DB**: The workflow bulk-inserts or upserts enriched data into the core tables: `accounts`, `opportunities`, `deal_details`, `redemption_locations`, `prospects`, `reviews`, and `account_reviews`.
   - From: `coffeeWorkflows`
   - To: `coffeeDb`
   - Protocol: SQL/Bulk

7. **Update job metadata**: The workflow records its execution status and progress in the `job_metadata` table for monitoring.
   - From: `coffeeWorkflows`
   - To: `coffeeDb` (job_metadata table)
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable | n8n workflow error handling (retry/skip) | Data becomes stale; existing data remains queryable |
| EDW batch query failure | n8n workflow error handling | Review and historical data not updated |
| S3 read failure | n8n workflow error handling | Competitor data not updated |
| Database write failure | n8n workflow error handling; job_metadata records failure | Partial ingestion; next run will attempt again |

## Sequence Diagram

```
n8nScheduler -> CoffeeWorkflows: Trigger ingestion
CoffeeWorkflows -> Salesforce: GET accounts + opportunities (REST API)
Salesforce --> CoffeeWorkflows: Account and opportunity data
CoffeeWorkflows -> EDW: Batch query reviews + historical deals
EDW --> CoffeeWorkflows: Review and deal data
CoffeeWorkflows -> DeepScoutS3: Read competitor export (S3)
DeepScoutS3 --> CoffeeWorkflows: Competitor data file
CoffeeWorkflows -> CoffeeWorkflows: Transform + enrich
CoffeeWorkflows -> CoffeeDb: Bulk INSERT/UPSERT into core tables
CoffeeDb --> CoffeeWorkflows: OK
CoffeeWorkflows -> CoffeeDb: Update job_metadata
```

## Related

- Related flows: [Materialized View Refresh](materialized-view-refresh.md), [Deal Search](deal-search.md)
