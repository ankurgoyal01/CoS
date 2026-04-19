---
service: "ai-reporting"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

AI Reporting uses the JTier Message Bus (JMS-based) via `continuumAiReportingMessageBus` for asynchronous event processing. The service both consumes inbound domain events (Salesforce CRM opportunities, Deal Catalog pause/inactive signals) and publishes outbound events (Salesforce account/wallet sync notifications). All messaging is mediated through the `continuumAiReportingService_messageBusConsumers` component for inbound and `continuumAiReportingService_salesforceClient` for outbound.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| Salesforce sync topic (JTier MBus) | `SalesforceSyncEvent` | Campaign state change or wallet update requiring CRM reflection | merchant account ID, wallet balance delta, campaign status |

### SalesforceSyncEvent Detail

- **Topic**: Salesforce sync topic via `continuumAiReportingMessageBus`
- **Trigger**: Campaign lifecycle state change (create, pause, deactivate) or wallet top-up/refund that must be reflected in Salesforce CRM
- **Payload**: merchant account ID, wallet balance delta, campaign status, timestamp
- **Consumers**: Salesforce CRM integration layer (`salesForce`)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Salesforce opportunities topic (JTier MBus) | `SalesforceOpportunityEvent` | `continuumAiReportingService_messageBusConsumers` -> `continuumAiReportingService_merchantPaymentsService` | Updates wallet balances and persists opportunity data to MySQL |
| Deal Catalog pause/inactive topic (JTier MBus) | `DealPauseEvent` | `continuumAiReportingService_messageBusConsumers` -> `continuumAiReportingService_sponsoredCampaignService` | Pauses associated Sponsored Listing campaigns and triggers CitrusAd deactivation |

### SalesforceOpportunityEvent Detail

- **Topic**: Salesforce opportunities topic via `continuumAiReportingMessageBus`
- **Handler**: `continuumAiReportingService_messageBusConsumers` routes to `continuumAiReportingService_merchantPaymentsService` for wallet ledger update
- **Idempotency**: Persisted JMS payloads to MySQL via `continuumAiReportingService_mysqlRepositories` provide replay protection
- **Error handling**: JTier MBus retry semantics; failed messages are retried per broker configuration
- **Processing order**: unordered

### DealPauseEvent Detail

- **Topic**: Deal Catalog pause/inactive topic via `continuumAiReportingMessageBus`
- **Handler**: `continuumAiReportingService_messageBusConsumers` routes to `continuumAiReportingService_sponsoredCampaignService` for campaign pause cascade
- **Idempotency**: Campaign state is checked before pause; duplicate events are safe to re-process
- **Error handling**: JTier MBus retry semantics; persistent failure triggers Slack alert via `continuumAiReportingService_slackNotifier`
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found for explicit DLQ configuration in the available DSL inventory. Consult the JTier Message Bus platform configuration or the service owner (ads-eng@groupon.com) for DLQ details.
