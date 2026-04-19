---
service: "cases-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

MCS uses Groupon's internal message bus (mbus, JMS/STOMP protocol) exclusively as a **consumer**. It subscribes to six Salesforce-originated topics to receive real-time updates about cases, case events, opportunities, notifications, and merchant accounts. These events drive asynchronous case state updates, unread count refreshes, and merchant notifications. No evidence of MCS publishing events to the message bus was found in the codebase.

## Published Events

> No evidence found in codebase. MCS does not publish events to the message bus.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.salesforce.case.create` | Case Created | `cases_notificationProcessing` | Updates Redis unread count; triggers merchant notification via `mxNotificationService` |
| `jms.topic.salesforce.case.update` | Case Updated | `cases_notificationProcessing` | Updates Redis unread count; triggers merchant notification |
| `jms.topic.salesforce.caseevent.create` | Case Event Created | `cases_notificationProcessing` | Processes case event notifications; triggers downstream notification (excludes types `CASE_EVENT_REMINDER_1`, `CASE_EVENT_REMINDER_2`) |
| `jms.topic.salesforce.opportunity.detailed_update` | Opportunity Updated | `cases_notificationProcessing` | Processes opportunity state changes for merchant case context |
| `jms.topic.salesforce.mcnotifications.create` | Merchant Center Notification Created | `cases_notificationProcessing` | Dispatches merchant-facing notifications via `mxNotificationService` |
| `jms.topic.salesforce.account.update` | Account Updated | `cases_notificationProcessing` | Processes Salesforce account updates for merchant account state |

### `jms.topic.salesforce.case.create` Detail

- **Topic**: `jms.topic.salesforce.case.create`
- **Handler**: `cases_notificationProcessing` component — message bus consumer registered at startup
- **Idempotency**: Durable subscription with `subscriptionId: mcs-staging-us` (staging) / `mcs-prod-*` (production); message broker ensures at-least-once delivery per subscription
- **Error handling**: Logged via Steno ops log on consumer error; no DLQ evidence found in codebase
- **Processing order**: Unordered (topic subscription)

### `jms.topic.salesforce.case.update` Detail

- **Topic**: `jms.topic.salesforce.case.update`
- **Handler**: `cases_notificationProcessing` — processes update events and reflects changes in Redis count cache
- **Idempotency**: Durable subscription
- **Error handling**: Errors logged; Redis counter refresh is best-effort
- **Processing order**: Unordered

### `jms.topic.salesforce.caseevent.create` Detail

- **Topic**: `jms.topic.salesforce.caseevent.create`
- **Handler**: `cases_notificationProcessing` — dispatches case event notifications, filtering out `CASE_EVENT_REMINDER_1` and `CASE_EVENT_REMINDER_2` types as configured in `casesConfig.excludedWebNotificationTypes`
- **Idempotency**: Non-durable in development; durable in staging/production
- **Error handling**: Errors logged via Steno
- **Processing order**: Unordered

### `jms.topic.salesforce.opportunity.detailed_update` Detail

- **Topic**: `jms.topic.salesforce.opportunity.detailed_update`
- **Handler**: `cases_notificationProcessing` — processes opportunity update events for merchant context
- **Idempotency**: Non-durable subscription
- **Error handling**: Errors logged via Steno
- **Processing order**: Unordered

### `jms.topic.salesforce.mcnotifications.create` Detail

- **Topic**: `jms.topic.salesforce.mcnotifications.create`
- **Handler**: `cases_notificationProcessing` — dispatches to `mxNotificationService`
- **Idempotency**: Durable subscription
- **Error handling**: Errors logged via `NotsErrorLogData` / `NotsNotificationLogData`
- **Processing order**: Unordered

### `jms.topic.salesforce.account.update` Detail

- **Topic**: `jms.topic.salesforce.account.update`
- **Handler**: `cases_notificationProcessing` — processes Salesforce account state changes
- **Idempotency**: Durable subscription
- **Error handling**: Errors logged via Steno
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found in codebase of configured dead-letter queues. Error handling relies on Steno logging.
