---
service: "ingestion-jtier"
title: "Deal State Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-state-management"
flow_type: synchronous
trigger: "Operator or automated tooling calls PUT /deals/v1/pause, PUT /deals/v1/unpause, PUT /deals/v1/addAdditionalPlace, or PUT /partner/v1/pause"
participants:
  - "continuumIngestionJtierService"
  - "continuumIngestionJtierPostgres"
  - "continuumDealManagementApi"
architecture_ref: "dynamic-ingestion-jtier-deal-state"
---

# Deal State Management

## Summary

The deal state management flow handles lifecycle transitions for deals and partners managed by ingestion-jtier. Operators or automated pipelines call the REST API to pause individual deals, unpause them, associate additional places with a deal, or pause an entire partner (pausing all their deals). State changes are applied both locally in PostgreSQL and propagated to the Deal Management API for catalog enforcement.

## Trigger

- **Type**: api-call
- **Source**: Operator tooling, Jenkins pipeline, or internal automation calling the ingestion-jtier REST API
- **Frequency**: On-demand; event-driven by business or operational needs (e.g., partner SLA breach, supply quality issue)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ingestion JTier Service | Receives state change request; validates; propagates to internal systems | `continuumIngestionJtierService` |
| Ingestion PostgreSQL | Records the state transition for deals and partners | `continuumIngestionJtierPostgres` |
| Deal Management API | Enforces the state transition in the live deal catalog | `continuumDealManagementApi` |

## Steps

### Pause Deal(s) — `PUT /deals/v1/pause`

1. **Receive pause request**: `ingestionApiResources` receives the PUT request with deal IDs to pause.
   - From: API caller
   - To: `continuumIngestionJtierService`
   - Protocol: HTTP/REST

2. **Validate deal IDs**: `ingestionPipeline` confirms the deal IDs exist in the `offers` or `availability` tables in PostgreSQL.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

3. **Send pause to Deal Management API**: `ingestionClientGateway` calls Deal Management API to set deal status to PAUSED.
   - From: `continuumIngestionJtierService`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP/REST

4. **Persist paused state**: `ingestionPersistence` updates the offer/deal state in PostgreSQL to reflect PAUSED status.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

5. **Return response**: `ingestionApiResources` returns 200 OK with confirmation payload.
   - From: `continuumIngestionJtierService`
   - To: API caller
   - Protocol: HTTP/REST

### Unpause Deal(s) — `PUT /deals/v1/unpause`

Same structure as pause, but Deal Management API is called to restore ACTIVE status. PostgreSQL is updated to ACTIVE.

### Add Additional Place — `PUT /deals/v1/addAdditionalPlace`

1. **Receive request**: `ingestionApiResources` receives deal ID and place details.
2. **Validate**: Confirm deal exists in PostgreSQL.
3. **Submit to Deal Management API**: `ingestionClientGateway` adds the location to the deal.
4. **Update PostgreSQL**: Record the additional place association.
5. **Return response**: 200 OK.

### Pause Partner — `PUT /partner/v1/pause`

1. **Receive pause request**: `ingestionApiResources` receives the partner ID to pause.
   - From: API caller
   - To: `continuumIngestionJtierService`
   - Protocol: HTTP/REST

2. **Read all active deals for partner**: `ingestionPersistence` queries PostgreSQL for all ACTIVE offers/deals belonging to the partner.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

3. **Bulk pause deals in Deal Management API**: `ingestionClientGateway` submits pause requests for all active deals to Deal Management API.
   - From: `continuumIngestionJtierService`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP/REST

4. **Update partner status in PostgreSQL**: `ingestionPersistence` sets the partner record status to PAUSED and updates all associated offer records.
   - From: `continuumIngestionJtierService`
   - To: `continuumIngestionJtierPostgres`
   - Protocol: JDBI / PostgreSQL

5. **Return response**: `ingestionApiResources` returns 200 OK.
   - From: `continuumIngestionJtierService`
   - To: API caller
   - Protocol: HTTP/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal ID not found in PostgreSQL | Return 404 to caller | No state change applied |
| Deal Management API error on pause/unpause | Return 502/503 to caller; PostgreSQL not updated | State change not applied; caller may retry |
| Partial failure on partner pause (some deals fail) | Log failures; continue for remaining deals | Partial pause; operator must investigate and retry for failed deals |

## Sequence Diagram

```
apiCaller -> ingestionApiResources: PUT /deals/v1/pause {dealIds}
ingestionApiResources -> continuumIngestionJtierPostgres: validate deal IDs
continuumIngestionJtierPostgres --> ingestionApiResources: deal records
ingestionApiResources -> continuumDealManagementApi: PUT pause deals
continuumDealManagementApi --> ingestionApiResources: 200 OK
ingestionApiResources -> continuumIngestionJtierPostgres: update status=PAUSED
ingestionApiResources --> apiCaller: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-ingestion-jtier-deal-state`
- Related flows: [Offer to Deal Creation](offer-to-deal-creation.md), [Deal Deletion Processing](deal-deletion-processing.md)
