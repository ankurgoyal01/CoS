---
service: "ingestion-service"
title: "Ticket Escalation (Salesforce Case Creation)"
generated: "2026-03-03"
type: flow
flow_name: "ticket-escalation"
flow_type: synchronous
trigger: "POST /odis/api/v1/salesforce/escalate/ticket/create from Zingtree or GSO tooling"
participants:
  - "continuumIngestionService"
  - "lazloApi"
  - "extZingtree_0f159531"
  - "extCaapApi_85f2db0d"
  - "salesForce"
  - "continuumIngestionServiceMysql"
architecture_ref: "dynamic-ticketEscalationFlow"
---

# Ticket Escalation (Salesforce Case Creation)

## Summary

This flow handles the creation of a Salesforce customer support case (ticket) when a customer escalation is triggered by the Zingtree chatbot or another GSO tool. The ingestion-service receives a rich set of customer, order, deal, and voucher context fields, optionally enriches the payload by fetching deal/merchant data from Lazlo and session transcripts from Zingtree, and then creates a Salesforce case via the Composite API. If Salesforce returns an error, the full request is persisted to MySQL for asynchronous retry.

## Trigger

- **Type**: API call
- **Source**: Zingtree chatbot (webhook at conversation end) or GSO internal tooling
- **Frequency**: On demand — each customer support escalation event
- **Endpoint**: `POST /odis/api/v1/salesforce/escalate/ticket/create`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Zingtree / GSO caller | Initiates the ticket creation request with customer and order context | `extZingtree_0f159531` (external caller) |
| Ingestion Service | Orchestrates the flow; validates auth; enriches context; calls Salesforce | `continuumIngestionService` |
| Lazlo API | Provides deal and merchant details for context enrichment | `lazloApi` |
| CAAP API | Provides customer attributes and order information if requested | `extCaapApi_85f2db0d` |
| Salesforce | Receives and stores the new case, email message, attachments, and tags | `salesForce` |
| Ingestion Service MySQL | Stores failed requests for retry; stores SF OAuth token | `continuumIngestionServiceMysql` |

## Steps

1. **Receives escalation request**: The caller posts to `POST /odis/api/v1/salesforce/escalate/ticket/create` with form-data fields including required `country`, `locale`, `caseRecordType_id`, and `user_email`, plus optional order, deal, voucher, and customer context fields.
   - From: Zingtree / GSO caller
   - To: `continuumIngestionService` (`ingestionService_apiResources`)
   - Protocol: HTTPS/REST

2. **Authenticates caller**: The Auth component validates the `X-API-KEY` header and `client_id` query parameter against the client credential store in MySQL.
   - From: `ingestionService_apiResources`
   - To: `authAndJwt` → `ingestionService_persistenceLayer` → `continuumIngestionServiceMysql`
   - Protocol: JDBI/MySQL

3. **Resolves Salesforce OAuth token**: Before calling Salesforce, the service reads a cached OAuth token from MySQL (`SfTokenDBI`). If absent or expired, it performs the Salesforce client credentials OAuth flow and stores the new token.
   - From: `coreServices`
   - To: `continuumIngestionServiceMysql` (token read); optionally `salesForce` (OAuth token endpoint)
   - Protocol: JDBI; HTTPS/REST

4. **Loads deal/merchant context (conditional)**: If a `deal_uuid` or `merchant_uuid` is provided, the service calls the Lazlo API to fetch deal and merchant details for enriching the Salesforce case description.
   - From: `continuumIngestionService`
   - To: `lazloApi`
   - Protocol: HTTPS/REST

5. **Fetches Zingtree session transcript (conditional)**: If a `session_id` is provided, the service calls the Zingtree API to retrieve the session transcript to include in the case description. If Zingtree is unavailable, a default description string is used.
   - From: `continuumIngestionService`
   - To: `extZingtree_0f159531`
   - Protocol: HTTPS/REST

6. **Builds Salesforce Composite request**: The `SFEscalatingTicketService` assembles a Salesforce Composite API request body containing:
   - A `Case` object creation (subject, origin, status, reason, country, locale, customer email, voucher details, tags, assignment rule)
   - An `EmailMessage` object linking the email body to the case
   - Optionally a `ContentVersion` + `ContentDocumentLink` for attachments (from `Attachment` URL in request)
   - Case tags

7. **Creates Salesforce case via Composite API**: Posts the assembled payload to `/services/data/v56.0/composite/sobjects` on Salesforce.
   - From: `continuumIngestionService`
   - To: `salesForce`
   - Protocol: HTTPS/REST (Salesforce Composite API v56.0)

8. **Returns result to caller**: On success (HTTP 200), returns confirmation to the caller. On Salesforce error (HTTP 500), persists the full request payload to the MySQL job queue and returns `500 "Error creating a ticket! It has been queued for a retry."`.
   - From: `continuumIngestionService`
   - To: Zingtree / GSO caller
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required field (`country`, `locale`, `caseRecordType_id`, `user_email`) | Validation rejection | `400 Bad Request` returned to caller |
| Invalid or missing API credentials | Auth filter rejection | `401 Unauthorized` returned |
| Salesforce API error during case creation | Request serialized to MySQL job queue via `SfTicketCreationJobDBI` | `500` returned to caller; `SfCreateTicketFailuresJob` retries asynchronously |
| Zingtree API unavailable | Default description string `"<Description not provided>"` substituted | Flow continues; case created with default description |
| Salesforce OAuth token expired | Service re-authenticates and refreshes token in MySQL | Transparent to caller; adds latency |

## Sequence Diagram

```
Caller -> IngestionService: POST /odis/api/v1/salesforce/escalate/ticket/create
IngestionService -> MySQL: Validate client_id credentials
MySQL --> IngestionService: Credentials valid
IngestionService -> MySQL: Read SF OAuth token
MySQL --> IngestionService: Token (or empty if expired)
IngestionService -> Salesforce: OAuth token request (if expired)
Salesforce --> IngestionService: New access token
IngestionService -> MySQL: Store new token
IngestionService -> LazloAPI: Fetch deal/merchant details (if deal_uuid provided)
LazloAPI --> IngestionService: Deal/merchant data
IngestionService -> Zingtree: Fetch session transcript (if session_id provided)
Zingtree --> IngestionService: Transcript data (or error -> default description)
IngestionService -> Salesforce: POST /services/data/v56.0/composite/sobjects (Case + EmailMessage + Attachment)
Salesforce --> IngestionService: 200 OK (case created) OR error
IngestionService -> MySQL: Persist failed request (on Salesforce error only)
IngestionService --> Caller: 200 OK OR 500 "queued for retry"
```

## Related

- Architecture dynamic view: `dynamic-ticketEscalationFlow`
- Related flows: [Failed Ticket Retry Job](failed-ticket-retry.md)
- See also: [API Surface](../api-surface.md) — `POST /odis/api/v1/salesforce/escalate/ticket/create`
