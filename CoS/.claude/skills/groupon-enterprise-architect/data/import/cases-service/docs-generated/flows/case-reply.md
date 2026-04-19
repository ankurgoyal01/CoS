---
service: "cases-service"
title: "Case Reply"
generated: "2026-03-03"
type: flow
flow_name: "case-reply"
flow_type: synchronous
trigger: "Merchant posts a reply message to an existing open support case"
participants:
  - "merchantSupportClient"
  - "continuumMerchantCaseService"
  - "cases_apiResources"
  - "cases_domainServices"
  - "cases_integrationClients"
  - "continuumM3MerchantService"
  - "continuumUsersService"
  - "salesForce"
  - "rocketmanEmailApi"
architecture_ref: "dynamic-cases-case-flow"
---

# Case Reply

## Summary

When a merchant posts a reply to an existing support case, MCS creates a new `EmailMessage` record in Salesforce associated with the parent case, then sends a transactional email notification via Rocketman to inform the Groupon support agent of the new reply. The `X-User-ID` header identifies the replying user; locale is passed as a query parameter to support locale-appropriate email templates.

## Trigger

- **Type**: api-call
- **Source**: Merchant Center frontend (`merchantSupportClient`) via `POST /v1/merchants/{merchantuuid}/cases/{caseNum}/reply`
- **Frequency**: On-demand per merchant reply action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center frontend | Initiator — submits reply body | `merchantSupportClient` |
| API Resources | Receives and validates request; extracts `X-User-ID` header | `cases_apiResources` |
| Case Domain Services | Orchestrates user resolution, Salesforce reply creation, and email dispatch | `cases_domainServices` |
| Integration Clients | Calls Users, Salesforce, and Rocketman | `cases_integrationClients` |
| M3 Merchant Service | Provides Salesforce account context for the merchant | `continuumM3MerchantService` |
| Users Service | Resolves the replying user's display name and email | `continuumUsersService` |
| Salesforce CRM | Persists the new EmailMessage linked to the parent case | `salesForce` |
| Rocketman Email API | Dispatches transactional reply notification to support team | `rocketmanEmailApi` |

## Steps

1. **Receive reply request**: Merchant Center sends `POST /v1/merchants/{merchantuuid}/cases/{caseNum}/reply` with `CaseReplyRequest` body (`replyBody`), `X-User-ID` header (UUID), and optional `locale` query parameter.
   - From: `merchantSupportClient`
   - To: `cases_apiResources`
   - Protocol: REST

2. **Authenticate**: API Resources validates `X-Api-Key` (write role required).
   - From: `cases_apiResources`
   - To: internal auth
   - Protocol: direct

3. **Resolve user**: Domain Services calls Users Service with the `X-User-ID` to retrieve the user's profile.
   - From: `cases_integrationClients`
   - To: `continuumUsersService`
   - Protocol: REST

4. **Resolve merchant account**: Domain Services calls M3 to retrieve the Salesforce account ID.
   - From: `cases_integrationClients`
   - To: `continuumM3MerchantService`
   - Protocol: REST

5. **Create EmailMessage in Salesforce**: Integration Clients creates a new `EmailMessage` record in Salesforce with the reply body, linked to the parent case identified by `caseNum`.
   - From: `cases_integrationClients`
   - To: `salesForce`
   - Protocol: HTTPS/REST

6. **Send transactional email**: Domain Services dispatches a transactional notification email via Rocketman to the Groupon support agent, including locale-appropriate template selection.
   - From: `cases_integrationClients`
   - To: `rocketmanEmailApi`
   - Protocol: REST

7. **Return response**: API Resources returns confirmation to Merchant Center.
   - From: `cases_apiResources`
   - To: `merchantSupportClient`
   - Protocol: REST (HTTP 200)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Users Service unavailable | Fail fast if user context is required | HTTP error to caller |
| Salesforce create EmailMessage fails | Fail fast | HTTP error; reply not saved |
| Rocketman unavailable | Non-blocking — email failure logged | Reply saved in Salesforce; no email to support agent |
| `shiftInvalidEmailCountries` check | Email handling for GB and IE uses alternative recipient logic | Reply saved; email routing adjusted |

## Sequence Diagram

```
MerchantCenter -> cases_apiResources: POST /v1/merchants/{uuid}/cases/{caseNum}/reply {replyBody}
cases_apiResources -> cases_domainServices: reply case request
cases_domainServices -> cases_integrationClients: resolve user
cases_integrationClients -> UsersService: GET /users/{X-User-ID}
UsersService --> cases_integrationClients: user profile
cases_domainServices -> cases_integrationClients: resolve merchant account
cases_integrationClients -> M3MerchantService: GET merchant
M3MerchantService --> cases_integrationClients: accountId
cases_integrationClients -> Salesforce: POST EmailMessage (ParentId=caseId, TextBody=replyBody)
Salesforce --> cases_integrationClients: emailMessageId
cases_integrationClients -> Rocketman: POST transactional email (case reply notification)
Rocketman --> cases_integrationClients: sent
cases_apiResources --> MerchantCenter: HTTP 200
```

## Related

- Architecture dynamic view: `dynamic-cases-case-flow`
- Related flows: [Case Creation](case-creation.md), [Case Retrieval](case-retrieval.md)
