---
service: "cases-service"
title: "Case Retrieval"
generated: "2026-03-03"
type: flow
flow_name: "case-retrieval"
flow_type: synchronous
trigger: "Merchant opens the support inbox or views a specific case in Merchant Center"
participants:
  - "merchantSupportClient"
  - "continuumMerchantCaseService"
  - "cases_apiResources"
  - "cases_domainServices"
  - "cases_integrationClients"
  - "cases_knowledgeAndCache"
  - "continuumM3MerchantService"
  - "salesForce"
  - "continuumMerchantCaseRedis"
architecture_ref: "dynamic-cases-case-flow"
---

# Case Retrieval

## Summary

When the Merchant Center loads a merchant's support inbox, MCS fetches the paginated list of cases from Salesforce and returns unread counts from Redis. For a single case view, MCS retrieves the full case detail including email message thread from Salesforce. Redis caches unread counts to avoid hitting Salesforce on every page load. The `updateCaseRead` PUT endpoint marks a case as read and updates the Redis count accordingly.

## Trigger

- **Type**: api-call
- **Source**: Merchant Center frontend (`merchantSupportClient`) via `GET /v1/merchants/{merchantuuid}/cases` or `GET /v1/merchants/{merchantuuid}/cases/{caseNum}`
- **Frequency**: Per merchant inbox load or case view

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center frontend | Initiator — requests case list or single case | `merchantSupportClient` |
| API Resources | Receives HTTP request, authenticates, routes | `cases_apiResources` |
| Case Domain Services | Orchestrates Salesforce query and Redis count lookup | `cases_domainServices` |
| Integration Clients | Calls M3 for account resolution and Salesforce for case data | `cases_integrationClients` |
| Knowledge and Cache Management | Reads/writes unread counts in Redis | `cases_knowledgeAndCache` |
| M3 Merchant Service | Provides Salesforce account ID | `continuumM3MerchantService` |
| Salesforce CRM | Source of case records and email message threads | `salesForce` |
| Merchant Cases Redis | Stores and returns cached unread case counts | `continuumMerchantCaseRedis` |

## Steps

1. **Receive list request**: Merchant Center sends `GET /v1/merchants/{merchantuuid}/cases` with optional `page`, `perPage`, `startDate`, `endDate`, `sort`, `status` query parameters.
   - From: `merchantSupportClient`
   - To: `cases_apiResources`
   - Protocol: REST

2. **Authenticate**: API Resources validates `X-Api-Key` against the client ID role map (read role required).
   - From: `cases_apiResources`
   - To: internal auth
   - Protocol: direct

3. **Resolve merchant Salesforce account**: Domain Services retrieves Salesforce `AccountId` for the merchant UUID via M3.
   - From: `cases_integrationClients`
   - To: `continuumM3MerchantService`
   - Protocol: REST

4. **Query Salesforce for cases**: Integration Clients issues a SOQL query to Salesforce filtered by `AccountId`, date range, status, and `RecordTypeId`. Applies pagination (`page`, `perPage`).
   - From: `cases_integrationClients`
   - To: `salesForce`
   - Protocol: HTTPS/REST (Salesforce SOQL query API)

5. **Resolve unread count**: Knowledge and Cache Management reads the unread case count from Redis for the merchant.
   - From: `cases_knowledgeAndCache`
   - To: `continuumMerchantCaseRedis`
   - Protocol: Redis

6. **Return response**: API Resources assembles the case list with unread count and returns to Merchant Center.
   - From: `cases_apiResources`
   - To: `merchantSupportClient`
   - Protocol: REST (HTTP 200)

### Single Case View

For `GET /v1/merchants/{merchantuuid}/cases/{caseNum}`:
1. API Resources routes to Case Domain Services with the `caseNum` path parameter.
2. Domain Services resolves merchant account via M3.
3. Integration Clients queries Salesforce for the specific case by `CaseNumber` including nested `EmailMessages` and email thread.
4. Domain Services marks referenced email messages as viewed if applicable.
5. Response includes case detail with full email thread.

### Mark as Read

For `PUT /v1/merchants/{merchantuuid}/cases/{caseNum}/read`:
1. Domain Services updates the case read status in Salesforce.
2. Knowledge and Cache Management decrements the Redis unread count for the merchant.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| M3 returns error | Fail fast | HTTP error returned; no cases shown |
| Salesforce query fails | Fail fast | HTTP error returned; empty inbox displayed |
| Redis unavailable | Graceful degradation | Cases returned without unread count |
| Case not found in Salesforce | Return 404 | HTTP 404 to caller |

## Sequence Diagram

```
MerchantCenter -> cases_apiResources: GET /v1/merchants/{uuid}/cases?page=1&perPage=20
cases_apiResources -> cases_domainServices: retrieve cases
cases_domainServices -> cases_integrationClients: resolve merchant account
cases_integrationClients -> M3MerchantService: GET merchant
M3MerchantService --> cases_integrationClients: accountId
cases_integrationClients -> Salesforce: SOQL SELECT cases WHERE AccountId=... LIMIT 20 OFFSET 0
Salesforce --> cases_integrationClients: case records
cases_domainServices -> cases_knowledgeAndCache: get unread count
cases_knowledgeAndCache -> Redis: GET unread:{merchantUuid}
Redis --> cases_knowledgeAndCache: count
cases_apiResources --> MerchantCenter: HTTP 200 {cases: [...], unreadCount: N}
```

## Related

- Architecture dynamic view: `dynamic-cases-case-flow`
- Related flows: [Case Creation](case-creation.md), [Message Bus Case Event Processing](message-bus-case-event-processing.md)
