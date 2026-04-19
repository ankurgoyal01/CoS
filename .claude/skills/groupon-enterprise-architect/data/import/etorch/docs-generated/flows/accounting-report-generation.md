---
service: "etorch"
title: "Accounting Report Generation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "accounting-report-generation"
flow_type: scheduled
trigger: "Quartz scheduler in continuumEtorchWorker (periodic) or merchant GET request to eTorch App"
participants:
  - "continuumEtorchApp"
  - "continuumEtorchWorker"
  - "etorchWorkerScheduler"
  - "continuumAccountingService"
  - "mxMerchantApiExternal_b545"
architecture_ref: "dynamic-etorchAccountingReport"
---

# Accounting Report Generation

## Summary

This flow covers two related paths for accounting data: a scheduled worker path where `continuumEtorchWorker` periodically calls `continuumAccountingService` to generate accounting reports for hotel merchants, and a synchronous merchant-facing path where `continuumEtorchApp` serves accounting statements and payment records on demand via `GET /getaways/v2/extranet/hotels/{uuid}/accounting/statements` and `GET /getaways/v2/extranet/hotels/{uuid}/accounting/payments`. In both paths, Accounting Service is the authoritative data source.

## Trigger

- **Type**: schedule (worker path) or api-call (merchant-facing path)
- **Source**: Quartz scheduler in `continuumEtorchWorker` (worker path); hotel operator HTTP request (merchant-facing path)
- **Frequency**: Periodic schedule configured via Quartz for worker jobs; on-demand per merchant request for the API path

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| eTorch App | Exposes accounting endpoints to merchants; coordinates data retrieval | `continuumEtorchApp` |
| eTorch Worker | Runs scheduled accounting report generation jobs | `continuumEtorchWorker` |
| Job Scheduler | Triggers accounting report job handlers via Quartz | `etorchWorkerScheduler` |
| Accounting Service | Authoritative source for hotel accounting statements and payments | `continuumAccountingService` |
| MX Merchant API | Validates merchant identity before serving accounting data | `mxMerchantApiExternal_b545` |

## Steps

### Merchant-Facing Path (synchronous)

1. **Receives merchant request**: Hotel operator sends `GET /getaways/v2/extranet/hotels/{uuid}/accounting/statements` or `/payments` to eTorch App.
   - From: `Merchant / Extranet portal`
   - To: `etorchAppControllers`
   - Protocol: REST (HTTPS)

2. **Validates request**: Extranet Controllers authenticate the API key and confirm the hotel UUID format.
   - From: `etorchAppControllers`
   - To: `etorchAppOrchestration`
   - Protocol: Direct (in-process)

3. **Verifies merchant identity**: Orchestration calls MX Merchant API to confirm the merchant account mapped to the hotel UUID.
   - From: `continuumEtorchApp`
   - To: `mxMerchantApiExternal_b545`
   - Protocol: REST (HTTP)

4. **Retrieves accounting data**: Orchestration calls Accounting Service to fetch statements or payments for the hotel.
   - From: `continuumEtorchApp`
   - To: `continuumAccountingService`
   - Protocol: REST (HTTP)

5. **Returns accounting data to merchant**: eTorch assembles the response and returns it to the hotel operator.
   - From: `etorchAppControllers`
   - To: `Merchant / Extranet portal`
   - Protocol: REST (HTTPS)

### Scheduled Worker Path (batch)

1. **Scheduler fires**: Quartz fires the accounting report job on the configured periodic schedule.
   - From: `etorchWorkerScheduler`
   - To: `etorchWorkerJobs`
   - Protocol: Direct (in-process)

2. **Requests report generation**: Job handler calls Accounting Service to trigger or retrieve a periodic accounting report covering hotel merchants.
   - From: `continuumEtorchWorker`
   - To: `continuumAccountingService`
   - Protocol: REST (HTTP)

3. **Records or distributes results**: Job handler processes the returned report data (stores locally or forwards as needed by the job implementation).
   - From: `etorchWorkerJobs`
   - To: `eTorch DB` or downstream consumers
   - Protocol: JDBC / REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Accounting Service unavailable (merchant path) | HTTP error from `etorchAppClients` | `GET /accounting/statements` or `/payments` returns HTTP 500; merchant cannot view accounting data; check `ACCOUNTING_SERVICE_BASE_URL` |
| MX Merchant API unavailable | HTTP error propagated | Merchant identity unverifiable; request returns HTTP 500 |
| Unknown hotel UUID | 404 from orchestration | HTTP 404 returned to merchant |
| Accounting Service unavailable (worker path) | Quartz job fails; failure logged | Scheduled report not generated; check `continuumEtorchWorker` logs; alert: `getaways-eng@groupon.com` |
| Quartz scheduler not running | Worker process not started | Scheduled reports cease; verify `continuumEtorchWorker` deployment |

## Sequence Diagram

```
Merchant -> etorchAppControllers: GET /getaways/v2/extranet/hotels/{uuid}/accounting/statements
etorchAppControllers -> etorchAppOrchestration: validate and route
etorchAppOrchestration -> mxMerchantApiExternal_b545: GET merchant identity
mxMerchantApiExternal_b545 --> etorchAppOrchestration: merchant account
etorchAppOrchestration -> continuumAccountingService: GET statements for hotel UUID
continuumAccountingService --> etorchAppOrchestration: accounting statements
etorchAppOrchestration --> etorchAppControllers: assembled response
etorchAppControllers --> Merchant: HTTP 200 OK (statements payload)

note over etorchWorkerScheduler: Scheduled worker path
etorchWorkerScheduler -> etorchWorkerJobs: trigger accounting report job
etorchWorkerJobs -> continuumAccountingService: POST/GET generate accounting report
continuumAccountingService --> etorchWorkerJobs: report data
etorchWorkerJobs -> etorchWorkerJobs: record/distribute report results
```

## Related

- Architecture dynamic view: `dynamic-etorchAccountingReport`
- Related flows: [Hotel Data Management](hotel-data-management.md), [Deal Update Batch Job](deal-update-batch-job.md)
- [API Surface](../api-surface.md) — `GET /getaways/v2/extranet/hotels/{uuid}/accounting/statements` and `/payments` endpoint definitions
- [Integrations](../integrations.md) — Accounting Service integration detail
- [Configuration](../configuration.md) — `ACCOUNTING_SERVICE_BASE_URL`
- [Runbook](../runbook.md) — troubleshooting accounting endpoint errors
