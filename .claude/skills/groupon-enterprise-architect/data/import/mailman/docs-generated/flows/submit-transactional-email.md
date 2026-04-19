---
service: "mailman"
title: "Submit Transactional Email"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "submit-transactional-email"
flow_type: synchronous
trigger: "HTTP POST to /mailman/mail"
participants:
  - "continuumMailmanApiController"
  - "continuumMailmanWorkflowEngine"
  - "continuumMailmanOutboundClients"
  - "continuumMailmanMessageBusIntegration"
  - "mailmanPostgres"
  - "messageBus"
architecture_ref: "dynamic-mail-processing-flow"
---

# Submit Transactional Email

## Summary

This flow handles the API-driven path for submitting a new transactional email request. A caller `POST`s a notification request to `/mailman/mail`; the API controller validates and persists the request, the workflow engine resolves the appropriate mail processor and fetches all required domain context from downstream services, and the enriched payload is published to MBus for Rocketman to deliver.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum service or operator calling `POST /mailman/mail`
- **Frequency**: Per-request (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API caller (internal service) | Initiates the request | — |
| `continuumMailmanApiController` | Receives, validates, and forwards the request | `continuumMailmanApiController` |
| `continuumMailmanWorkflowEngine` | Resolves mail processor; coordinates context enrichment | `continuumMailmanWorkflowEngine` |
| `continuumMailmanOutboundClients` | Fetches domain context from downstream services | `continuumMailmanOutboundClients` |
| `continuumMailmanMessageBusIntegration` | Publishes enriched payload to MBus | `continuumMailmanMessageBusIntegration` |
| `mailmanPostgres` | Persists request state and deduplication record | `mailmanPostgres` |
| `messageBus` | Receives enriched `TransactionalEmailRequest` for Rocketman | `messageBus` |

## Steps

1. **Receives email submission request**: Caller sends `POST /mailman/mail` with notification type and identifiers.
   - From: API caller
   - To: `continuumMailmanApiController`
   - Protocol: REST/HTTP/JSON

2. **Validates and writes request state**: Controller validates the payload, writes initial request state to `mailmanPostgres`, and checks deduplication records.
   - From: `continuumMailmanApiController`
   - To: `mailmanPostgres`
   - Protocol: JDBC

3. **Submits to workflow engine**: Controller forwards the validated request to the workflow engine.
   - From: `continuumMailmanApiController`
   - To: `continuumMailmanWorkflowEngine`
   - Protocol: In-process call

4. **Resolves mail processor**: Workflow engine determines the notification type and selects the appropriate mail processor via `MailProcessorResolver`.
   - From: `continuumMailmanWorkflowEngine`
   - To: `continuumMailmanWorkflowEngine` (internal resolution)
   - Protocol: In-process call

5. **Fetches domain context**: Workflow engine instructs outbound clients to retrieve required context from downstream services (order details, user profile, deal metadata, merchant data, inventory, relevance, etc.) as required by notification type.
   - From: `continuumMailmanWorkflowEngine`
   - To: `continuumMailmanOutboundClients`
   - Protocol: In-process call

6. **Calls downstream context services**: Outbound clients make HTTP/JSON calls to applicable services (`continuumOrdersService`, `continuumUsersService`, `continuumDealCatalogService`, `continuumUniversalMerchantApi`, etc.).
   - From: `continuumMailmanOutboundClients`
   - To: Context services (Orders, Users, Deal Catalog, Merchant, etc.)
   - Protocol: HTTP/JSON (Retrofit)

7. **Publishes enriched payload to MBus**: Workflow engine passes the enriched notification payload to the message bus integration, which publishes `TransactionalEmailRequest` to MBus.
   - From: `continuumMailmanMessageBusIntegration`
   - To: `messageBus`
   - Protocol: MBus/JMS

8. **Updates request state**: Final request state (published) written to `mailmanPostgres`.
   - From: `continuumMailmanWorkflowEngine`
   - To: `mailmanPostgres`
   - Protocol: JDBC

9. **Returns HTTP response**: Controller returns success response to caller.
   - From: `continuumMailmanApiController`
   - To: API caller
   - Protocol: REST/HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate request detected | Deduplication check fails fast on `mailmanPostgres` lookup | Request rejected with duplicate response; no processing occurs |
| Downstream context service unavailable | Outbound client call fails | Request state marked as failed in `mailmanPostgres`; retry payload written for Quartz scheduler |
| MBus publish failure | Message bus integration publish call fails | Request state marked as failed; retry payload persisted to `mailmanPostgres` |
| Validation failure | Controller returns error response | Request not persisted; caller receives 4xx response |

## Sequence Diagram

```
Caller -> continuumMailmanApiController: POST /mailman/mail
continuumMailmanApiController -> mailmanPostgres: Write request state + dedup check
continuumMailmanApiController -> continuumMailmanWorkflowEngine: Submit validated request
continuumMailmanWorkflowEngine -> continuumMailmanOutboundClients: Fetch domain context
continuumMailmanOutboundClients -> continuumOrdersService: Load order context
continuumMailmanOutboundClients -> continuumUsersService: Load user context
continuumMailmanOutboundClients -> continuumDealCatalogService: Load deal/product metadata
continuumMailmanOutboundClients -> continuumUniversalMerchantApi: Load merchant context
continuumMailmanOutboundClients --> continuumMailmanWorkflowEngine: Return enriched context
continuumMailmanWorkflowEngine -> continuumMailmanMessageBusIntegration: Publish enriched payload
continuumMailmanMessageBusIntegration -> messageBus: Publish TransactionalEmailRequest
continuumMailmanWorkflowEngine -> mailmanPostgres: Update request state (published)
continuumMailmanApiController --> Caller: HTTP 200 OK
```

## Related

- Architecture dynamic view: `dynamic-mail-processing-flow`
- Related flows: [MBus Message Consumption](mbus-message-consumption.md), [Deduplication Check](deduplication-check.md), [Manual Retry](manual-retry.md)
