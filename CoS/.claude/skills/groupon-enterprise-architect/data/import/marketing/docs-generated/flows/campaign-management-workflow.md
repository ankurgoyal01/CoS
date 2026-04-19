---
service: "marketing"
title: "Campaign Management Workflow"
generated: "2026-03-03"
type: flow
flow_name: "campaign-management-workflow"
flow_type: synchronous
trigger: "Administrator action"
participants:
  - "administrator"
  - "continuumMarketingPlatform"
  - "continuumMarketingPlatformDb"
  - "messageBus"
architecture_ref: ""
---

# Campaign Management Workflow

## Summary

Administrators create and manage marketing campaigns through the Marketing & Delivery Platform's administrative interface. This workflow covers the full campaign lifecycle from creation through configuration, activation, and monitoring. Campaign data is persisted to the Marketing Platform Database, and campaign lifecycle events are published to the Message Bus for downstream consumption.

## Trigger

- **Type**: user-action
- **Source**: Administrator (internal operations staff)
- **Frequency**: On demand (as campaigns are created and managed)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrator | Creates and manages marketing campaigns | `administrator` |
| Marketing & Delivery Platform | Processes campaign CRUD operations and orchestration | `continuumMarketingPlatform` |
| Campaign Management | Handles campaign lifecycle logic | `marketingPlatform_campaignManagement` |
| Subscriptions | Manages targeting and subscription rules | `marketingPlatform_subscriptions` |
| Marketing Platform Database | Persists campaign data | `continuumMarketingPlatformDb` |
| Message Bus | Receives campaign lifecycle events | `messageBus` |

## Steps

1. **Create campaign**: Administrator submits campaign configuration via HTTPS.
   - From: `administrator`
   - To: `continuumMarketingPlatform`
   - Protocol: HTTPS

2. **Persist campaign**: Campaign Management component validates and persists campaign data.
   - From: `continuumMarketingPlatform`
   - To: `continuumMarketingPlatformDb`
   - Protocol: JDBC (inferred)

3. **Configure targeting**: Administrator configures audience targeting and subscription rules.
   - From: `administrator`
   - To: `continuumMarketingPlatform`
   - Protocol: HTTPS

4. **Activate campaign**: Administrator activates campaign for delivery.
   - From: `administrator`
   - To: `continuumMarketingPlatform`
   - Protocol: HTTPS

5. **Publish campaign event**: Campaign Management publishes activation event to Message Bus.
   - From: `marketingPlatform_campaignManagement`
   - To: `messageBus`
   - Protocol: Async

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid campaign configuration | > No evidence found in codebase. | Campaign creation rejected |
| Database write failure | > No evidence found in codebase. | Campaign not persisted |
| Message Bus publishing failure | > No evidence found in codebase. | Campaign event not propagated to downstream systems |

## Sequence Diagram

```
administrator -> continuumMarketingPlatform: Create campaign (HTTPS)
continuumMarketingPlatform -> continuumMarketingPlatformDb: Persist campaign data (JDBC)
administrator -> continuumMarketingPlatform: Configure targeting (HTTPS)
administrator -> continuumMarketingPlatform: Activate campaign (HTTPS)
continuumMarketingPlatform -> messageBus: Publish campaign lifecycle event (Async)
```

## Related

- Architecture dynamic view: `dynamic-continuum-marketing`
- Related flows: [Campaign Notification Flow](campaign-notification-flow.md), [Order Confirmation Notification](order-confirmation-notification.md)
