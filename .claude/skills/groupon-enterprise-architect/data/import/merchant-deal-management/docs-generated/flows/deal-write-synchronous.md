---
service: "merchant-deal-management"
title: "Synchronous Deal Write"
generated: "2026-03-03"
type: flow
flow_name: "deal-write-synchronous"
flow_type: synchronous
trigger: "Inbound HTTP request to the Deal Management API for deal creation or update"
participants:
  - "continuumDealManagementApi"
  - "dmapiHttpApi"
  - "dmapiValidationAndMapping"
  - "dmapiWriteOrchestrator"
  - "dmapiRemoteClientGateway"
  - "dmapiAsyncDispatch"
  - "continuumDealManagementApiMySql"
  - "continuumDealManagementApiRedis"
architecture_ref: "components-dmapi-dmapiHttpApi"
---

# Synchronous Deal Write

## Summary

The Synchronous Deal Write flow covers the path from an inbound HTTP deal write request through validation, write orchestration, downstream service calls, and job enqueue. The API validates the incoming payload, maps it to domain models, orchestrates calls to downstream Continuum services (pricing, taxonomy, geo, merchant, inventory, appointments), persists the write request to MySQL, and optionally enqueues an async Resque job for work that should not block the HTTP response. The caller receives a synchronous HTTP response once the API-side work is complete.

## Trigger

- **Type**: api-call
- **Source**: Internal tooling, merchant-facing portal, or operator workflow submitting a deal creation or update request
- **Frequency**: On-demand, per request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API Layer | Receives and routes the inbound request | `dmapiHttpApi` |
| Validation and Mapping | Validates payload schema and maps params to domain model | `dmapiValidationAndMapping` |
| Write Orchestration | Coordinates the write across internal and remote services | `dmapiWriteOrchestrator` |
| Remote Client Gateway | Calls downstream Continuum service HTTP endpoints | `dmapiRemoteClientGateway` |
| Async Dispatch | Enqueues long-running work as Resque jobs | `dmapiAsyncDispatch` |
| Deal Management API MySQL | Stores the write request record | `continuumDealManagementApiMySql` |
| Deal Management API Redis | Enforces rate limiting; receives Resque job | `continuumDealManagementApiRedis` |

## Steps

1. **Receive request**: Inbound HTTP request arrives at the API.
   - From: External caller (internal tool or merchant surface)
   - To: `dmapiHttpApi`
   - Protocol: REST/HTTP

2. **Validate and map**: Payload is validated against schema rules and mapped to internal domain models.
   - From: `dmapiHttpApi`
   - To: `dmapiValidationAndMapping`
   - Protocol: direct (in-process)

3. **Orchestrate write**: Write orchestrator coordinates the write flow across downstream services.
   - From: `dmapiHttpApi`
   - To: `dmapiWriteOrchestrator`
   - Protocol: direct (in-process)

4. **Call downstream services**: Remote Client Gateway calls relevant downstream Continuum services (pricing, taxonomy, geo, merchant, inventory, appointments) and persists the write request.
   - From: `dmapiWriteOrchestrator`
   - To: `dmapiRemoteClientGateway` and `continuumDealManagementApiMySql`
   - Protocol: HTTP/JSON (downstream services); ActiveRecord/MySQL (persistence)

5. **Enqueue async work** (if required): Async Dispatch enqueues a Resque job in Redis for work that should be processed asynchronously (e.g., deal catalog update, Salesforce sync).
   - From: `dmapiWriteOrchestrator`
   - To: `dmapiAsyncDispatch` → `continuumDealManagementApiRedis`
   - Protocol: Resque/Redis

6. **Return response**: HTTP response returned to caller indicating success or failure.
   - From: `dmapiHttpApi`
   - To: External caller
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure | Return HTTP 4xx with validation errors | Request rejected; no downstream calls made |
| Rate limit exceeded | Redis rate-limit check blocks request | HTTP 429 returned; no write performed |
| Downstream service unavailable | Faraday client error in `dmapiRemoteClientGateway` | Depends on service; may return HTTP 5xx or enqueue for retry |
| MySQL write failure | ActiveRecord exception | HTTP 5xx returned; write request not persisted |
| Redis unavailable | Resque enqueue failure | May fall back to synchronous processing or return error depending on configuration |

## Sequence Diagram

```
Caller -> dmapiHttpApi: POST /deals (HTTP/JSON)
dmapiHttpApi -> dmapiValidationAndMapping: Validate and map payload
dmapiValidationAndMapping --> dmapiHttpApi: Domain model or validation error
dmapiHttpApi -> dmapiWriteOrchestrator: Orchestrate write
dmapiWriteOrchestrator -> dmapiRemoteClientGateway: Call downstream services (pricing, geo, merchant, inventory, etc.)
dmapiRemoteClientGateway --> dmapiWriteOrchestrator: Service responses
dmapiWriteOrchestrator -> continuumDealManagementApiMySql: Persist write request (ActiveRecord)
dmapiWriteOrchestrator -> dmapiAsyncDispatch: Enqueue async job (if needed)
dmapiAsyncDispatch -> continuumDealManagementApiRedis: Resque.enqueue
dmapiHttpApi --> Caller: HTTP 200/201/4xx/5xx
```

## Related

- Architecture dynamic view: `components-dmapi-dmapiHttpApi`
- Related flows: [Async Write Dispatch](async-write-dispatch.md), [Worker Write Execution](worker-write-execution.md)
