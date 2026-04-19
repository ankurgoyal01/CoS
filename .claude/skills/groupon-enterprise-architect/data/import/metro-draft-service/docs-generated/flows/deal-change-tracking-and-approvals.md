---
service: "metro-draft-service"
title: "Deal Change Tracking and Approvals"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-change-tracking-and-approvals"
flow_type: synchronous
trigger: "HTTP POST or PUT /api/mcm/* — caller submits a merchandising change to a live deal"
participants:
  - "continuumMetroDraftService_mcmResource"
  - "continuumMetroDraftService_mcmServiceHelper"
  - "continuumMetroDraftService_mcmChangeDao"
  - "continuumMetroDraftService_dmapiClient"
  - "continuumMetroDraftService_marketingDealClient"
  - "continuumMetroDraftMcmPostgres"
  - "continuumDealManagementService"
  - "continuumMarketingDealService"
architecture_ref: "components-continuum-metro-draft-service"
---

# Deal Change Tracking and Approvals

## Summary

When a merchandising change is submitted to a live deal — such as an update to pricing, description, or product options — Metro Draft Service captures the change via the MCM (Merchandising Change Management) flow. MCM Resource delegates to MCM Service Helper, which logs the change set to the MCM PostgreSQL database, notifies DMAPI about the change action, and updates the Marketing Deal Service. This provides a full audit trail of who changed what, when, and whether the change was approved or rejected.

## Trigger

- **Type**: api-call
- **Source**: Metro internal tooling or merchandising operations calling `POST /api/mcm/*` or `PUT /api/mcm/*`
- **Frequency**: On demand — per merchandising change submission to a live deal

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MCM Resource | Receives MCM HTTP request; delegates to MCM Service Helper | `continuumMetroDraftService_mcmResource` |
| MCM Service Helper | Core MCM logic: validates, persists change sets, notifies downstream | `continuumMetroDraftService_mcmServiceHelper` |
| MCM Change DAO | Persists merchandising change sets to MCM database | `continuumMetroDraftService_mcmChangeDao` |
| Deal Management Client | Notifies DMAPI about the merchandising change action | `continuumMetroDraftService_dmapiClient` |
| Marketing Deal Client | Updates the merchandising deal view in MDS | `continuumMetroDraftService_marketingDealClient` |
| MCM Postgres | Stores change sets and approval state | `continuumMetroDraftMcmPostgres` |
| Deal Management Service (DMAPI) | Receives change notification to update the deal pipeline | `continuumDealManagementService` |
| Marketing Deal Service (MDS) | Receives updated merchandising deal data | `continuumMarketingDealService` |

## Steps

1. **Receive MCM change request**: MCM Resource receives `POST` or `PUT /api/mcm/*` with the change payload.
   - From: Caller (Metro merchandising operations)
   - To: `continuumMetroDraftService_mcmResource`
   - Protocol: REST HTTP

2. **Validate and process change**: MCM Resource delegates to MCM Service Helper with the change payload.
   - From: `continuumMetroDraftService_mcmResource`
   - To: `continuumMetroDraftService_mcmServiceHelper`
   - Protocol: Internal call

3. **Persist change set**: MCM Service Helper calls MCM Change DAO to write the change set record.
   - From: `continuumMetroDraftService_mcmServiceHelper` -> `continuumMetroDraftService_mcmChangeDao`
   - To: `continuumMetroDraftMcmPostgres`
   - Protocol: JDBI/PostgreSQL

4. **Notify DMAPI**: MCM Service Helper calls Deal Management Client to notify DMAPI about the change action so the deal pipeline is updated.
   - From: `continuumMetroDraftService_mcmServiceHelper` -> `continuumMetroDraftService_dmapiClient`
   - To: `continuumDealManagementService`
   - Protocol: HTTP/Retrofit

5. **Update Marketing Deal Service**: MCM Service Helper calls Marketing Deal Client to sync the updated merchandising data.
   - From: `continuumMetroDraftService_mcmServiceHelper` -> `continuumMetroDraftService_marketingDealClient`
   - To: `continuumMarketingDealService`
   - Protocol: HTTP/Retrofit

6. **Return MCM result**: MCM Resource returns the change set ID and current approval state to the caller.
   - From: `continuumMetroDraftService_mcmResource`
   - To: Caller
   - Protocol: REST HTTP 200 OK / 201 Created

### Approval Read Path (GET /api/mcm/*)

1. **Receive MCM query**: MCM Resource receives `GET /api/mcm/*` to fetch change logs or approval state.
   - From: Caller
   - To: `continuumMetroDraftService_mcmResource`
   - Protocol: REST HTTP

2. **Read change sets**: MCM Resource reads change sets from MCM Change DAO.
   - From: `continuumMetroDraftService_mcmResource` -> `continuumMetroDraftService_mcmChangeDao`
   - To: `continuumMetroDraftMcmPostgres`
   - Protocol: JDBI

3. **Return change log**: MCM Resource returns the change log and approval states to the caller.
   - From: `continuumMetroDraftService_mcmResource`
   - To: Caller
   - Protocol: REST HTTP 200 OK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MCM database write failure | JDBI exception propagates; transaction rolled back | 500 returned; change not persisted; no downstream notifications sent |
| DMAPI notification failure | MCM Service Helper logs error; change set already persisted | Change logged in MCM DB but pipeline not updated; requires manual retry or re-submit |
| MDS update failure | Logged; MCM DB change persisted | Merchandising view in MDS may be stale; requires investigation |
| Invalid change payload | MCM Resource returns 400 | Change rejected; no state written |

## Sequence Diagram

```
Caller -> McmResource: POST /api/mcm/* (change payload)
McmResource -> McmServiceHelper: processChange(payload)
McmServiceHelper -> McmChangeDao: persistChangeSet(change)
McmChangeDao -> McmPostgres: INSERT change_set
McmPostgres --> McmChangeDao: ok
McmServiceHelper -> DmapiClient: notifyChangeAction(dealId, changeId)
DmapiClient -> DealManagementService: update deal with change
DealManagementService --> DmapiClient: ok
McmServiceHelper -> MarketingDealClient: updateMerchandisingDeal(dealId, change)
MarketingDealClient -> MarketingDealService: sync updated data
MarketingDealService --> MarketingDealClient: ok
McmServiceHelper --> McmResource: change set ID + approval state
McmResource --> Caller: 201 Created { changeSetId, status }
```

## Related

- Architecture dynamic view: `components-continuum-metro-draft-service`
- Related flows: [Deal Publishing Orchestration](deal-publishing-orchestration.md), [Merchant Deal Draft Creation](merchant-deal-draft-creation.md)
