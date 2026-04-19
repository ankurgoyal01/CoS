---
service: "s2s"
title: "Teradata Customer Info Job"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "teradata-customer-info-job"
flow_type: scheduled
trigger: "Quartz scheduler fires customer info job or manual POST /jobs/edw/customerInfo"
participants:
  - "continuumS2sService"
  - "continuumS2sTeradata"
  - "continuumS2sPostgres"
architecture_ref: "dynamic-s2s-event-dispatch"
---

# Teradata Customer Info Job

## Summary

This scheduled batch job backfills hashed customer PII data from Groupon's Teradata Enterprise Data Warehouse (EDW) into the S2S operational Postgres database. The backfilled data — primarily hashed email and phone values — is used by the Partner Event Dispatch flow to enrich partner conversion payloads with customer data for advanced matching. A related AES retry job processes records that require re-processing with AES-keyed transformations.

## Trigger

- **Type**: schedule (also: manual HTTP trigger via `/jobs/edw/customerInfo` and `/jobs/edw/aesRetry`)
- **Source**: Quartz Scheduler within `continuumS2sService`; `/jobs/edw/customerInfo` POST for manual runs
- **Frequency**: Scheduled (interval configured in Quartz; specific cron not visible in architecture model)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| S2S Service — Quartz Scheduler | Fires the scheduled job | `continuumS2sService_quartzScheduler` |
| S2S Service — Job Resource | Accepts manual job trigger via HTTP | `continuumS2sService_jobResource` |
| S2S Service — Service Factory | Provides domain services for job execution | `continuumS2sService_serviceFactory` |
| S2S Service — Processor Factory | Starts batch processors for job execution | `continuumS2sService_processorFactory` |
| S2S Service — Customer Info Service | Orchestrates customer info fetch and cache | `continuumS2sService_customerInfoService` |
| S2S Service — Partner Click ID Cache | Stores hashed partner identifiers | `continuumS2sService_partnerClickIdCacheService` |
| S2S Service — DAO Factory | Creates DAOs for Teradata and Postgres access | `continuumS2sService_daoFactory` |
| Teradata EDW | Source of customer info and AES retry data | `continuumS2sTeradata` |
| S2S Postgres | Destination for backfilled customer info and click IDs | `continuumS2sPostgres` |

## Steps

1. **Fire scheduled trigger**: Quartz Scheduler fires the customer info job at the configured interval. Alternatively, the `/jobs/edw/customerInfo` Job Resource endpoint accepts a manual POST trigger.
   - From: `continuumS2sService_quartzScheduler` (or `continuumS2sService_jobResource`)
   - To: Job execution context via `continuumS2sService_serviceFactory` and `continuumS2sService_processorFactory`
   - Protocol: Quartz internal / HTTP

2. **Initialize job services and DAOs**: Service Factory and DAO Factory create Customer Info Service with Postgres and Teradata DAOs ready for batch execution.
   - From: `continuumS2sService_serviceFactory`
   - To: `continuumS2sService_daoFactory` → DAO instances for `continuumS2sTeradata` and `continuumS2sPostgres`
   - Protocol: JDBI/JDBC internal

3. **Query customer info from Teradata EDW**: Customer Info Service queries Teradata EDW via JDBC for customer records requiring backfill. Retrieves hashed email, hashed phone, and associated customer identifiers.
   - From: `continuumS2sService_customerInfoService`
   - To: `continuumS2sTeradata`
   - Protocol: JDBC (Teradata JDBC 17.20)

4. **Write enriched customer info to Postgres**: Hashed customer PII records are written to `continuumS2sPostgres` via JDBI, making them available for partner event enrichment in real-time event processing.
   - From: `continuumS2sService_customerInfoService`
   - To: `continuumS2sPostgres`
   - Protocol: JDBI/Postgres

5. **Store hashed partner identifiers**: Partner click ID Cache stores hashed partner identifiers from the customer info batch into Postgres for attribution lookups during event processing.
   - From: `continuumS2sService_customerInfoService`
   - To: `continuumS2sService_partnerClickIdCacheService` → `continuumS2sPostgres`
   - Protocol: JDBI/Postgres

6. **AES retry sub-flow** (triggered by `/jobs/edw/aesRetry`): A related Quartz job queries Teradata for AES retry records and replays them through the processing pipeline. Follows the same DAO and service initialization pattern.
   - From: `continuumS2sService_quartzScheduler` / `continuumS2sService_jobResource`
   - To: `continuumS2sTeradata` → `continuumS2sService_customerInfoService` → `continuumS2sPostgres`
   - Protocol: JDBC / JDBI

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Teradata EDW unavailable | JDBC connection failure logged; job fails gracefully | Customer info not refreshed for this run; retried on next schedule or manual trigger |
| Postgres write failure | JDBI exception logged; partial batch may be written | Incomplete backfill; stale customer info used until next successful run |
| Job timeout | Quartz job timeout configuration applies | Job killed; manual trigger via `/jobs/edw/customerInfo` required to resume |
| Partial Teradata result | Job processes available records | Partial backfill; subsequent runs cover remaining records |

## Sequence Diagram

```
continuumS2sService_quartzScheduler    -> continuumS2sService_serviceFactory    : Fire customer info job
continuumS2sService_serviceFactory     -> continuumS2sService_daoFactory        : Create Teradata + Postgres DAOs
continuumS2sService_serviceFactory     -> continuumS2sService_customerInfoService : Initialize with DAOs
continuumS2sService_customerInfoService -> continuumS2sTeradata                  : JDBC query customer info
continuumS2sTeradata                   --> continuumS2sService_customerInfoService : Customer records (hashed PII)
continuumS2sService_customerInfoService -> continuumS2sPostgres                  : JDBI write customer info
continuumS2sService_customerInfoService -> continuumS2sService_partnerClickIdCacheService : Store hashed partner identifiers
continuumS2sService_partnerClickIdCacheService -> continuumS2sPostgres           : JDBI write click IDs
```

## Related

- Architecture dynamic view: `dynamic-s2s-event-dispatch`
- Related flows: [Partner Event Dispatch](partner-event-dispatch.md), [Janus Consent Filter Pipeline](janus-consent-filter-pipeline.md)
