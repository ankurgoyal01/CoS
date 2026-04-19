---
service: "mailman"
title: "MBus Message Consumption"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "mbus-message-consumption"
flow_type: event-driven
trigger: "Message arrives on MailmanQueue (MBus/JMS)"
participants:
  - "messageBus"
  - "continuumMailmanMessageBusIntegration"
  - "continuumMailmanWorkflowEngine"
  - "continuumMailmanOutboundClients"
  - "mailmanPostgres"
architecture_ref: "dynamic-mail-processing-flow"
---

# MBus Message Consumption

## Summary

This flow covers the asynchronous path where a transactional email request arrives as a JMS message on `MailmanQueue`. The `continuumMailmanMessageBusIntegration` component listens on the queue, deduplicates the message, dispatches it to the workflow engine for context enrichment, and publishes the enriched `TransactionalEmailRequest` back to MBus for Rocketman. Failed messages are routed to the DLQ and persisted for retry.

## Trigger

- **Type**: event
- **Source**: MBus message arriving on `MailmanQueue`
- **Frequency**: Per-message (on-demand, continuous listener)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `messageBus` | Source of inbound transactional email request messages | `messageBus` |
| `continuumMailmanMessageBusIntegration` | Listens on `MailmanQueue`; dispatches to workflow engine; publishes enriched payload | `continuumMailmanMessageBusIntegration` |
| `continuumMailmanWorkflowEngine` | Orchestrates context enrichment and mail processing | `continuumMailmanWorkflowEngine` |
| `continuumMailmanOutboundClients` | Fetches domain context from downstream HTTP services | `continuumMailmanOutboundClients` |
| `mailmanPostgres` | Stores request state, deduplication records, and retry payloads | `mailmanPostgres` |

## Steps

1. **Receives queue message**: JMS listener in `continuumMailmanMessageBusIntegration` receives a transactional email request message from `MailmanQueue`.
   - From: `messageBus`
   - To: `continuumMailmanMessageBusIntegration`
   - Protocol: MBus/JMS

2. **Performs deduplication check**: Message integration reads `mailmanPostgres` to check whether this request has already been processed.
   - From: `continuumMailmanMessageBusIntegration`
   - To: `mailmanPostgres`
   - Protocol: JDBC

3. **Writes initial request state**: If not a duplicate, the request payload is persisted to `mailmanPostgres` as an in-flight request.
   - From: `continuumMailmanMessageBusIntegration`
   - To: `mailmanPostgres`
   - Protocol: JDBC

4. **Dispatches to workflow engine**: Message integration forwards the message to `continuumMailmanWorkflowEngine` for processing.
   - From: `continuumMailmanMessageBusIntegration`
   - To: `continuumMailmanWorkflowEngine`
   - Protocol: In-process call

5. **Resolves mail processor**: Workflow engine identifies the notification type and selects the appropriate processor.
   - From: `continuumMailmanWorkflowEngine`
   - To: `continuumMailmanWorkflowEngine` (internal resolution)
   - Protocol: In-process call

6. **Fetches domain context**: Workflow engine requests context from outbound clients; clients call applicable downstream services (Orders, Users, Deal Catalog, Relevance API, Merchant, etc.).
   - From: `continuumMailmanWorkflowEngine`
   - To: `continuumMailmanOutboundClients`
   - Protocol: In-process call

7. **Calls downstream context services**: Outbound clients make parallel or sequential HTTP/JSON calls to applicable Continuum services.
   - From: `continuumMailmanOutboundClients`
   - To: `continuumOrdersService`, `continuumUsersService`, `continuumDealCatalogService`, `continuumRelevanceApi`, `continuumUniversalMerchantApi` (and others as required)
   - Protocol: HTTP/JSON (Retrofit)

8. **Publishes enriched payload to MBus**: Enriched `TransactionalEmailRequest` published back to `messageBus` for Rocketman.
   - From: `continuumMailmanMessageBusIntegration`
   - To: `messageBus`
   - Protocol: MBus/JMS

9. **Updates request state to published**: Final request state written to `mailmanPostgres`.
   - From: `continuumMailmanWorkflowEngine`
   - To: `mailmanPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate message detected | Deduplication check finds existing record in `mailmanPostgres` | Message acknowledged and discarded; no reprocessing |
| Context service call fails | Outbound client call throws exception | Request state updated to failed; retry payload written to `mailmanPostgres`; JMS message may be NACKed |
| Message routed to DLQ | JMS DLQ listener receives failed message | DLQ listener persists payload to `mailmanPostgres` retry table for Quartz-based retry |
| MBus publish failure | Publish call to MBus fails | Request state updated to failed; retry payload written to `mailmanPostgres` |

## Sequence Diagram

```
messageBus -> continuumMailmanMessageBusIntegration: Deliver MailmanQueue message
continuumMailmanMessageBusIntegration -> mailmanPostgres: Deduplication check
continuumMailmanMessageBusIntegration -> mailmanPostgres: Write request state (in-flight)
continuumMailmanMessageBusIntegration -> continuumMailmanWorkflowEngine: Dispatch message
continuumMailmanWorkflowEngine -> continuumMailmanOutboundClients: Fetch domain context
continuumMailmanOutboundClients -> continuumOrdersService: Load order context
continuumMailmanOutboundClients -> continuumUsersService: Load user context
continuumMailmanOutboundClients -> continuumDealCatalogService: Load deal/product metadata
continuumMailmanOutboundClients -> continuumRelevanceApi: Load recommendation context
continuumMailmanOutboundClients -> continuumUniversalMerchantApi: Load merchant context
continuumMailmanOutboundClients --> continuumMailmanWorkflowEngine: Return enriched context
continuumMailmanWorkflowEngine -> continuumMailmanMessageBusIntegration: Publish downstream notification payload
continuumMailmanMessageBusIntegration -> messageBus: Publish TransactionalEmailRequest
continuumMailmanWorkflowEngine -> mailmanPostgres: Update request state (published)
```

## Related

- Architecture dynamic view: `dynamic-mail-processing-flow`
- Related flows: [Submit Transactional Email](submit-transactional-email.md), [Scheduled Retry Batch](scheduled-retry-batch.md), [Manual Retry](manual-retry.md)
