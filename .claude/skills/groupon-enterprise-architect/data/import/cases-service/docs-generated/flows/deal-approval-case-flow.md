---
service: "cases-service"
title: "Deal Approval Case Flow"
generated: "2026-03-03"
type: flow
flow_name: "deal-approval-case-flow"
flow_type: synchronous
trigger: "Merchant submits or tracks a deal edit requiring Groupon approval"
participants:
  - "merchantSupportClient"
  - "continuumMerchantCaseService"
  - "cases_apiResources"
  - "cases_domainServices"
  - "cases_integrationClients"
  - "continuumM3MerchantService"
  - "continuumDealCatalogService"
  - "salesForce"
architecture_ref: "dynamic-cases-case-flow"
---

# Deal Approval Case Flow

## Summary

When a merchant submits a deal edit that requires Groupon approval, MCS creates a dedicated deal-approval case in Salesforce using the `modelEditDealCase` prototype (RecordTypeId `012c0000000Ar2VAAS`, Issue_Category: "Deal Edit", Issue_Details: "MC Self Service"). The case is linked to both the merchant account and the deal UUID. Groupon staff can then retrieve or update the case status via the same API. This flow is used by the Merchant Center deal editing workflow.

## Trigger

- **Type**: api-call
- **Source**: Merchant Center frontend (`merchantSupportClient`) via `POST /v1/merchants/{merchantuuid}/deals/{dealuuid}/edits`
- **Frequency**: On-demand when a merchant submits a deal edit requiring approval

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center frontend | Initiator — submits deal edit summary | `merchantSupportClient` |
| API Resources | Receives HTTP request, routes to domain services | `cases_apiResources` |
| Case Domain Services | Orchestrates account/deal resolution and Salesforce case creation | `cases_domainServices` |
| Integration Clients | Calls M3, Deal Catalog, and Salesforce | `cases_integrationClients` |
| M3 Merchant Service | Provides Salesforce account ID for the merchant | `continuumM3MerchantService` |
| Deal Catalog Service | Provides deal metadata (title, attributes) for the case | `continuumDealCatalogService` |
| Salesforce CRM | Persists the deal-edit approval Case object | `salesForce` |

## Steps

### Case Creation

1. **Receive deal-edit case request**: Merchant Center sends `POST /v1/merchants/{merchantuuid}/deals/{dealuuid}/edits` with `CaseCreateRequest` body containing `editSummary`, `dealTitle`, `email`, `issueCategory`, `issueSubCategory`, `name`, `userType`, `caseRaisedBy`, `mdmChangeId`.
   - From: `merchantSupportClient`
   - To: `cases_apiResources`
   - Protocol: REST

2. **Resolve merchant account**: Domain Services calls M3 to retrieve the Salesforce account ID.
   - From: `cases_integrationClients`
   - To: `continuumM3MerchantService`
   - Protocol: REST

3. **Retrieve deal metadata**: Domain Services calls Deal Catalog Service with the `dealuuid` to get deal title and attributes used to populate the case subject.
   - From: `cases_integrationClients`
   - To: `continuumDealCatalogService`
   - Protocol: REST

4. **Build deal-edit case**: Domain Services applies the `modelEditDealCase` prototype (`RecordTypeId: 012c0000000Ar2VAAS`, `Issue_Category__c: Deal Edit`, `Issue_Details__c: MC Self Service`, `Status: New`, `Origin: US Merchant Support`) and merges the request's `editSummary`.
   - From: `cases_domainServices`
   - To: internal (in-process)
   - Protocol: direct

5. **Create case in Salesforce**: Integration Clients POSTs the Case object to Salesforce.
   - From: `cases_integrationClients`
   - To: `salesForce`
   - Protocol: HTTPS/REST

6. **Return case ID**: API Resources returns the Salesforce case ID to Merchant Center.
   - From: `cases_apiResources`
   - To: `merchantSupportClient`
   - Protocol: REST (HTTP 200)

### Case Retrieval

For `GET /v1/merchants/{merchantuuid}/deals/{dealuuid}/edits/{caseId}`:
1. Domain Services resolves merchant account via M3.
2. Integration Clients queries Salesforce for the specific case by ID.
3. Response includes current case status and any resolution details.

### Case Status Update

For `PUT /v1/merchants/{merchantuuid}/deals/{dealuuid}/edits/{caseId}` with `UpdateCaseRequest` (`status: CLOSED`, `reason`):
1. Domain Services validates the status transition (only `CLOSED` accepted per schema).
2. Integration Clients updates the Salesforce Case record status.
3. Response confirms the updated case state.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| M3 returns error | Fail fast | HTTP error; case not created |
| Deal Catalog unavailable | Fail fast (deal title required for case subject) | HTTP error; case not created |
| Salesforce create fails | Fail fast | HTTP error |
| Invalid status in update request | Rejected at API layer (only CLOSED is valid) | HTTP 400 |

## Sequence Diagram

```
MerchantCenter -> cases_apiResources: POST /v1/merchants/{uuid}/deals/{dealUuid}/edits {editSummary}
cases_apiResources -> cases_domainServices: create deal approval case
cases_domainServices -> cases_integrationClients: resolve merchant account
cases_integrationClients -> M3MerchantService: GET merchant
M3MerchantService --> cases_integrationClients: accountId
cases_integrationClients -> DealCatalogService: GET deal/{dealUuid}
DealCatalogService --> cases_integrationClients: deal title, attributes
cases_domainServices -> cases_integrationClients: create Salesforce case (modelEditDealCase prototype)
cases_integrationClients -> Salesforce: POST Case {RecordTypeId: 012c0000000Ar2VAAS, editSummary, accountId}
Salesforce --> cases_integrationClients: caseId
cases_apiResources --> MerchantCenter: HTTP 200 {caseId}
```

## Related

- Architecture dynamic view: `dynamic-cases-case-flow`
- Related flows: [Case Creation](case-creation.md), [Case Retrieval](case-retrieval.md)
