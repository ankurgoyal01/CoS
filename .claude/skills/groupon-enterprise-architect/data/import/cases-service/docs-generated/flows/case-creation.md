---
service: "cases-service"
title: "Case Creation"
generated: "2026-03-03"
type: flow
flow_name: "case-creation"
flow_type: synchronous
trigger: "Merchant submits a new support case from the Merchant Center portal"
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
  - "mxNotificationService"
architecture_ref: "dynamic-cases-case-flow"
---

# Case Creation

## Summary

When a merchant submits a new support case from the Merchant Center, MCS receives the request, resolves the merchant's Salesforce account ID via M3, optionally resolves the user context via the Users Service, constructs a Salesforce Case object based on a pre-configured prototype for the case type, creates the case in Salesforce, and then triggers a transactional confirmation email via Rocketman and a push notification via the MX Notification Service.

MCS supports several case types, each using a different Salesforce `RecordTypeId` prototype: standard support cases (`POST /v1/merchants/{merchantuuid}/cases`), feedback cases (`POST /v1/merchants/{merchantuuid}/feedback`), callback cases (`POST /v1/merchants/{merchantuuid}/callbackcase`), and DAC7/RRDP completion cases (`POST /v1/merchants/{merchantuuid}/rrdpcase`).

## Trigger

- **Type**: api-call
- **Source**: Merchant Center frontend (`merchantSupportClient`) via `POST /v1/merchants/{merchantuuid}/cases` (or feedback, callbackcase, rrdpcase variant)
- **Frequency**: On-demand per merchant action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center frontend | Initiator — sends case creation request | `merchantSupportClient` |
| API Resources | Receives HTTP request, validates input, dispatches to domain services | `cases_apiResources` |
| Case Domain Services | Orchestrates merchant resolution, prototype selection, Salesforce call, and notification triggers | `cases_domainServices` |
| Integration Clients | Makes outbound calls to M3, Users, Salesforce, Rocketman, and Nots | `cases_integrationClients` |
| M3 Merchant Service | Provides Salesforce account ID for the merchant UUID | `continuumM3MerchantService` |
| Users Service | Provides user details for case ownership assignment | `continuumUsersService` |
| Salesforce CRM | Persists the new Case object | `salesForce` |
| Rocketman Email API | Sends transactional confirmation email | `rocketmanEmailApi` |
| MX Notification Service | Dispatches web/push notification | `mxNotificationService` |

## Steps

1. **Receive case creation request**: Merchant Center sends `POST /v1/merchants/{merchantuuid}/cases` with `CaseCreationRequest` body (subject, body, deal UUID, category, userId).
   - From: `merchantSupportClient`
   - To: `cases_apiResources`
   - Protocol: REST

2. **Validate and route**: API Resources validates the `X-Api-Key` header against the client ID role map and passes the request to Case Domain Services.
   - From: `cases_apiResources`
   - To: `cases_domainServices`
   - Protocol: direct (in-process)

3. **Resolve merchant Salesforce account**: Domain Services calls M3 Merchant Service to retrieve the Salesforce account ID associated with the `merchantuuid`.
   - From: `cases_integrationClients`
   - To: `continuumM3MerchantService`
   - Protocol: REST

4. **Resolve user context** (optional): Domain Services calls Users Service to retrieve user details for case owner assignment.
   - From: `cases_integrationClients`
   - To: `continuumUsersService`
   - Protocol: REST

5. **Build Salesforce Case object**: Domain Services selects the appropriate case prototype from `casesConfig.prototypes` (modelCase, modelCallBackCase, modelDAC7Case, etc.) and merges request fields.
   - From: `cases_domainServices`
   - To: internal (in-process)
   - Protocol: direct

6. **Create case in Salesforce**: Integration Clients posts the Case object to the Salesforce REST API.
   - From: `cases_integrationClients`
   - To: `salesForce`
   - Protocol: HTTPS/REST

7. **Send confirmation email**: Domain Services calls Rocketman with the case details and recipient address to dispatch a transactional email.
   - From: `cases_integrationClients`
   - To: `rocketmanEmailApi`
   - Protocol: REST

8. **Dispatch push notification**: Domain Services calls MX Notification Service to push a web notification to the merchant.
   - From: `cases_integrationClients`
   - To: `mxNotificationService`
   - Protocol: REST

9. **Return response**: API Resources returns the created case details (Salesforce case number, status) to the Merchant Center.
   - From: `cases_apiResources`
   - To: `merchantSupportClient`
   - Protocol: REST (HTTP 200/201)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| M3 returns error | Fail fast — cannot resolve Salesforce account | HTTP error returned to caller |
| Salesforce create fails | Fail fast — no case created | HTTP error returned to caller |
| Rocketman unavailable | Non-blocking — email failure logged, case still created | Case created; no confirmation email sent |
| Nots unavailable | Non-blocking — notification failure logged, case still created | Case created; no push notification sent |
| Invalid `X-Api-Key` | Rejected at API Resources layer | HTTP 401/403 |

## Sequence Diagram

```
MerchantCenter  -> cases_apiResources: POST /v1/merchants/{uuid}/cases {subject, body, userId}
cases_apiResources -> cases_domainServices: create case request
cases_domainServices -> cases_integrationClients: resolve merchant account
cases_integrationClients -> M3MerchantService: GET merchant account
M3MerchantService --> cases_integrationClients: Salesforce accountId
cases_domainServices -> cases_integrationClients: resolve user (optional)
cases_integrationClients -> UsersService: GET user details
UsersService --> cases_integrationClients: user profile
cases_domainServices -> cases_integrationClients: create Salesforce case
cases_integrationClients -> Salesforce: POST /services/data/vXX/sobjects/Case
Salesforce --> cases_integrationClients: case id, caseNumber
cases_domainServices -> cases_integrationClients: send email
cases_integrationClients -> Rocketman: POST transactional email
cases_domainServices -> cases_integrationClients: send notification
cases_integrationClients -> MXNotificationService: POST notification
cases_apiResources --> MerchantCenter: HTTP 200 {caseNumber, status}
```

## Related

- Architecture dynamic view: `dynamic-cases-case-flow`
- Related flows: [Case Reply](case-reply.md), [Message Bus Case Event Processing](message-bus-case-event-processing.md)
