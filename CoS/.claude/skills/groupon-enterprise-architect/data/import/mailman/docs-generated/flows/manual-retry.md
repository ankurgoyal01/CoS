---
service: "mailman"
title: "Manual Retry"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "manual-retry"
flow_type: synchronous
trigger: "HTTP POST to /mailman/retry"
participants:
  - "continuumMailmanApiController"
  - "continuumMailmanWorkflowEngine"
  - "continuumMailmanOutboundClients"
  - "continuumMailmanMessageBusIntegration"
  - "mailmanPostgres"
  - "messageBus"
architecture_ref: "dynamic-mail-processing-flow"
---

# Manual Retry

## Summary

This flow allows an operator or internal system to manually trigger retry of a previously failed transactional email request. The API controller receives the retry request, loads the original payload from `mailmanPostgres`, re-submits it to the workflow engine for fresh context enrichment, and publishes the enriched payload to MBus. This path is complementary to the automated [Scheduled Retry Batch](scheduled-retry-batch.md) flow.

## Trigger

- **Type**: api-call
- **Source**: Operator or internal system calling `POST /mailman/retry`
- **Frequency**: On-demand (manual)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / internal caller | Initiates the retry request | — |
| `continuumMailmanApiController` | Receives retry request and coordinates re-submission | `continuumMailmanApiController` |
| `continuumMailmanWorkflowEngine` | Re-processes the request with fresh context enrichment | `continuumMailmanWorkflowEngine` |
| `continuumMailmanOutboundClients` | Fetches current domain context from downstream services | `continuumMailmanOutboundClients` |
| `continuumMailmanMessageBusIntegration` | Publishes enriched payload to MBus | `continuumMailmanMessageBusIntegration` |
| `mailmanPostgres` | Source of retry payload; updated with retry attempt state | `mailmanPostgres` |
| `messageBus` | Receives enriched `TransactionalEmailRequest` for Rocketman | `messageBus` |

## Steps

1. **Receives retry request**: Operator sends `POST /mailman/retry` with the request identifier or retry record reference.
   - From: Operator / internal caller
   - To: `continuumMailmanApiController`
   - Protocol: REST/HTTP/JSON

2. **Loads retry payload**: Controller retrieves the original failed request payload from the retry table in `mailmanPostgres`.
   - From: `continuumMailmanApiController`
   - To: `mailmanPostgres`
   - Protocol: JDBC

3. **Increments retry attempt count**: Retry record in `mailmanPostgres` is updated to record this retry attempt.
   - From: `continuumMailmanApiController`
   - To: `mailmanPostgres`
   - Protocol: JDBC

4. **Submits to workflow engine**: Controller forwards the payload to `continuumMailmanWorkflowEngine` for re-processing.
   - From: `continuumMailmanApiController`
   - To: `continuumMailmanWorkflowEngine`
   - Protocol: In-process call

5. **Re-fetches domain context**: Workflow engine calls outbound clients to retrieve fresh, current context from downstream services.
   - From: `continuumMailmanWorkflowEngine`
   - To: `continuumMailmanOutboundClients`
   - Protocol: In-process call

6. **Calls downstream context services**: Outbound clients make HTTP/JSON calls to applicable services.
   - From: `continuumMailmanOutboundClients`
   - To: Applicable context services (Orders, Users, Deal Catalog, Merchant, etc.)
   - Protocol: HTTP/JSON (Retrofit)

7. **Publishes enriched payload to MBus**: Enriched `TransactionalEmailRequest` published to MBus for Rocketman.
   - From: `continuumMailmanMessageBusIntegration`
   - To: `messageBus`
   - Protocol: MBus/JMS

8. **Marks retry as resolved**: Request state in `mailmanPostgres` updated to published/resolved.
   - From: `continuumMailmanWorkflowEngine`
   - To: `mailmanPostgres`
   - Protocol: JDBC

9. **Returns HTTP response**: Controller returns success response.
   - From: `continuumMailmanApiController`
   - To: Operator / internal caller
   - Protocol: REST/HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Retry record not found | Controller returns 4xx error | No processing occurs; caller informed of missing record |
| Context service unavailable during retry | Outbound client fails | Retry attempt count incremented; payload remains in `mailmanPostgres` retry table |
| MBus publish fails during retry | Publish call fails | Retry state preserved in `mailmanPostgres`; retry record remains eligible for future attempts |

## Sequence Diagram

```
Operator -> continuumMailmanApiController: POST /mailman/retry
continuumMailmanApiController -> mailmanPostgres: Load retry payload
continuumMailmanApiController -> mailmanPostgres: Increment retry attempt count
continuumMailmanApiController -> continuumMailmanWorkflowEngine: Re-submit request
continuumMailmanWorkflowEngine -> continuumMailmanOutboundClients: Fetch fresh domain context
continuumMailmanOutboundClients -> continuumOrdersService: Load order context
continuumMailmanOutboundClients -> continuumUsersService: Load user context
continuumMailmanOutboundClients --> continuumMailmanWorkflowEngine: Return enriched context
continuumMailmanWorkflowEngine -> continuumMailmanMessageBusIntegration: Publish enriched payload
continuumMailmanMessageBusIntegration -> messageBus: Publish TransactionalEmailRequest
continuumMailmanWorkflowEngine -> mailmanPostgres: Update state to published
continuumMailmanApiController --> Operator: HTTP 200 OK
```

## Related

- Architecture dynamic view: `dynamic-mail-processing-flow`
- Related flows: [Scheduled Retry Batch](scheduled-retry-batch.md), [Submit Transactional Email](submit-transactional-email.md), [MBus Message Consumption](mbus-message-consumption.md)
