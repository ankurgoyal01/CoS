---
service: "deal-service"
title: "Deal Notification Publish"
generated: "2026-03-02"
type: flow
flow_name: "deal-notification-publish"
flow_type: asynchronous
trigger: "Deal active status changes or deal expires during processing"
participants:
  - "continuumDealService"
  - "continuumDealServiceRedisLocal"
architecture_ref: "dynamic-deal-notification-publish"
---

# Deal Notification Publish

## Summary

When deal-service detects that a deal's active status has changed (active toggled or deal expired) during the per-deal processing cycle, the `notificationPublisher` component constructs a JSON notification payload and pushes it onto the `{event_notification}.message` Redis list. Downstream notification consumers poll this list to deliver deal change alerts. This flow is a sub-step of the [Deal State Update and Inventory Publish](deal-state-update-and-inventory-publish.md) flow.

## Trigger

- **Type**: event
- **Source**: Deal active status change or expiry detected during deal processing
- **Frequency**: Once per deal where an active status change is observed; occurs within the per-deal processing cycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Service Worker (`notificationPublisher`) | Constructs and publishes the notification payload | `continuumDealService` |
| Deal Service Redis (Local) | Receives the notification via `{event_notification}.message` list | `continuumDealServiceRedisLocal` |

## Steps

1. **Detects active status change**: During deal processing, `processDeal` compares the previous and current `active` status of the deal. If the status has changed or the deal has expired, it triggers the notification path.
   - From: `processDeal` component
   - To: `notificationPublisher` component
   - Protocol: in-process

2. **Constructs notification payload**: `notificationPublisher` assembles the JSON notification:
   ```json
   {
     "dealPermalink": "<permalink>",
     "dealUuid": "<uuid>",
     "country": "<country code>",
     "type": "genericChange",
     "changedFields": ["active"]
   }
   ```
   - From: `continuumDealService` (in-process)
   - Protocol: in-process

3. **Publishes to Redis list**: Pushes the serialized JSON payload to the `{event_notification}.message` Redis list (LPUSH or RPUSH).
   - From: `continuumDealService`
   - To: `continuumDealServiceRedisLocal`
   - Protocol: Redis (LPUSH / RPUSH on `{event_notification}.message`)

4. **Downstream consumers receive notification**: External notification consumers poll or block on the Redis list and process the notification payload.
   - From: `continuumDealServiceRedisLocal`
   - To: downstream notification consumers (outside deal-service scope)
   - Protocol: Redis (BRPOP / RPOP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable when publishing | Push fails; error logged via Lumber | Notification not delivered; deal state was already persisted to Postgres/MongoDB; notification loss is accepted |
| Downstream consumer not polling | Notification accumulates in Redis list | Eventually consumed when consumer resumes; Redis list has no TTL evidence |

## Sequence Diagram

```
processDeal -> processDeal: detect active status change
processDeal -> notificationPublisher: trigger notification (dealPermalink, dealUuid, country)
notificationPublisher -> notificationPublisher: construct JSON payload
notificationPublisher -> RedisLocal: LPUSH {event_notification}.message <payload>
RedisLocal --> notificationPublisher: OK
--- (downstream, outside deal-service) ---
NotificationConsumer -> RedisLocal: BRPOP {event_notification}.message
RedisLocal --> NotificationConsumer: payload
```

## Related

- Architecture dynamic view: `dynamic-deal-notification-publish`
- Related flows: [Deal State Update and Inventory Publish](deal-state-update-and-inventory-publish.md), [Deal Processing Cycle](deal-processing-cycle.md)
