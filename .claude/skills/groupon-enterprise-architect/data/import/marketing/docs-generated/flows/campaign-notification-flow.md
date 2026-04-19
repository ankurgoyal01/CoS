---
service: "marketing"
title: "Campaign Notification Flow"
generated: "2026-03-03"
type: flow
flow_name: "campaign-notification-flow"
flow_type: asynchronous
trigger: "Campaign activation or scheduled delivery"
participants:
  - "continuumMarketingPlatform"
  - "messageBus"
architecture_ref: "dynamic-continuum-marketing"
---

# Campaign Notification Flow

## Summary

The Marketing & Delivery Platform publishes campaign lifecycle events, subscription change events, and delivery logs to the shared Message Bus. This flow is triggered when campaigns are activated or scheduled for delivery. The Campaign Management component orchestrates campaign events, the Subscriptions component manages routing rules, and the Kafka Logging component handles structured event logging.

## Trigger

- **Type**: schedule / system-action
- **Source**: Campaign activation, scheduled delivery trigger, or subscription change
- **Frequency**: On demand (per campaign activation or schedule)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Marketing & Delivery Platform | Publishes campaign events, subscriptions, and logs | `continuumMarketingPlatform` |
| Campaign Management | Orchestrates campaign lifecycle and publishes campaign events | `marketingPlatform_campaignManagement` |
| Subscriptions | Manages subscription routing rules | `marketingPlatform_subscriptions` |
| Kafka Logging | Logs delivery events to Kafka | `marketingPlatform_kafkaLogging` |
| Message Bus | Receives and distributes campaign events to downstream consumers | `messageBus` |

## Steps

1. **Campaign activation**: Campaign Management component triggers campaign for delivery based on schedule or manual activation.
   - From: `marketingPlatform_campaignManagement`
   - To: `messageBus`
   - Protocol: Async (Message Bus)

2. **Subscription routing**: Subscriptions component applies routing rules to determine target audience and channel preferences.
   - From: `marketingPlatform_subscriptions`
   - To: `messageBus`
   - Protocol: Async (Message Bus)

3. **Event logging**: Kafka Logging component publishes delivery metrics and event logs.
   - From: `marketingPlatform_kafkaLogging`
   - To: `messageBus`
   - Protocol: Async (Kafka)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message Bus unavailable | > No evidence found in codebase. | Campaign events may be delayed or lost |
| Kafka broker failure | > No evidence found in codebase. | Delivery logs may be delayed |

## Sequence Diagram

```
marketingPlatform_campaignManagement -> messageBus: Publish campaign events
marketingPlatform_subscriptions -> messageBus: Routing rules
marketingPlatform_kafkaLogging -> messageBus: Log delivery
```

## Related

- Architecture dynamic view: `dynamic-continuum-marketing`
- Related flows: [Order Confirmation Notification](order-confirmation-notification.md), [Campaign Management Workflow](campaign-management-workflow.md)
- Central data pipeline view: `dynamic-continuum-data-pipeline`
