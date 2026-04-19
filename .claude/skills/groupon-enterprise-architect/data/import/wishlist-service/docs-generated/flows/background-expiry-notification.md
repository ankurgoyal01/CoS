---
service: "wishlist-service"
title: "Background Item Expiry Notification"
generated: "2026-03-03"
type: flow
flow_name: "background-expiry-notification"
flow_type: scheduled
trigger: "Quartz UserDequeueJob fires every 2 seconds on the worker component"
participants:
  - "wishlistBackgroundJobs"
  - "wishlistPersistenceLayer"
  - "continuumWishlistPostgresRo"
  - "wishlistExternalClients"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
  - "wishlistMessagingIntegration"
  - "messageBus"
  - "continuumEmailService"
architecture_ref: "components-wishlist-service"
---

# Background Item Expiry Notification

## Summary

The Wishlist Service runs a background processing pipeline on the worker component that identifies users with wishlisted items approaching expiry or recently added, and dispatches email notifications via MBus. The pipeline is driven by two Quartz jobs: `UserEnqueueJob` periodically loads eligible users into a Redis queue, and `UserDequeueJob` dequeues users and fans them through a chain of processing tasks — including the `EmailNotifyExpiryAndNewTask` that publishes a notification event to the `WishlistMailman` MBus topic for Mailman to dispatch.

## Trigger

- **Type**: schedule
- **Source**: Quartz `UserDequeueJob` (cron `0/2 * * ? * * *`) — fires every 2 seconds on the worker component when `ENABLE_JOBS=true`
- **Frequency**: Every 2 seconds (dequeue); every 5 seconds (enqueue)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Background Job Pipeline | Runs UserEnqueueJob and UserDequeueJob; chains processing tasks per user | `wishlistBackgroundJobs` |
| Persistence Layer | Reads user list/item data and updates item metadata (channel, expiry) | `wishlistPersistenceLayer` |
| Wishlist Postgres RO | Serves read queries for user lists and items | `continuumWishlistPostgresRo` |
| External Service Clients | Fetches deal metadata and inventory expiry data | `wishlistExternalClients` |
| Deal Catalog Service | Returns deal metadata by deal ID or option ID | `continuumDealCatalogService` |
| Voucher Inventory Service | Returns expiry dates and inventory status per vertical | `continuumVoucherInventoryService` |
| Message Bus Integration | Publishes wishlist mail notification events to MBus | `wishlistMessagingIntegration` |
| MBus | Delivers published notification events to Mailman | `messageBus` |
| Email Service (Mailman) | Renders and dispatches notification emails to users | `continuumEmailService` |

## Steps

1. **Enqueue users (UserEnqueueJob, every 5 seconds)**: The `UserEnqueueJob` claims a free user bucket from PostgreSQL (rotating bucket numbers), loads all active user IDs for that bucket, filters out users with no wishlist activity in the past 12 months, and pushes the remaining user IDs into the Redis queue.
   - From: `wishlistBackgroundJobs`
   - To: `wishlistPersistenceLayer` → `continuumWishlistPostgresRo` (fetch users) and `continuumWishlistRedisCluster` (push queue)
   - Protocol: JDBC + Redis

2. **Dequeue user batch (UserDequeueJob, every 2 seconds)**: The `UserDequeueJob` pops a batch of user IDs from the Redis queue and iterates over them, dispatching each user ID to registered `UserProcessingTask` implementations.
   - From: `wishlistBackgroundJobs`
   - To: `continuumWishlistRedisCluster` (pop user IDs)
   - Protocol: Redis

3. **Run channel update task (ChannelUpdateTask)**: For each user, loads wishlist items lacking a `channelId`, fetches the deal's channel from the Taxonomy Service and Voucher Inventory Service, and updates the item's `channelId` in PostgreSQL.
   - From: `wishlistBackgroundJobs`
   - To: `wishlistExternalClients` → taxonomy/inventory services; `wishlistPersistenceLayer` → `continuumWishlistPostgresRw`
   - Protocol: HTTP + JDBC

4. **Run expiry update task (ExpiryUpdateTask)**: For each user, loads wishlist items lacking an `expires` timestamp, fetches the deal's expiry from the Voucher Inventory Service (per vertical — getaways, goods, VIS, gLive, CLO, TPIS), and updates the item's `expires` field in PostgreSQL.
   - From: `wishlistBackgroundJobs`
   - To: `wishlistExternalClients` → `continuumVoucherInventoryService`; `wishlistPersistenceLayer` → `continuumWishlistPostgresRw`
   - Protocol: HTTP + JDBC

5. **Run list item processing (ListItemProcessingTask)**: For each user, runs the item processor pipeline: applies `FilteredItems` logic to identify items within the expiry/created notification windows, then executes `EmailNotifyExpiryAndNewTask`.
   - From: `wishlistBackgroundJobs` → `wishlistApplicationServices`
   - To: `wishlistPersistenceLayer` → `continuumWishlistPostgresRo` (read items)
   - Protocol: JDBC

6. **Fetch deal metadata for qualifying items**: External Service Clients fetch deal metadata from the Deal Catalog Service for each deal ID of qualifying items.
   - From: `wishlistExternalClients`
   - To: `continuumDealCatalogService`: `GET /deal/{dealId}?clientId=edc279c643e5b7bb-Wishlist`
   - Protocol: HTTP

7. **Publish email notification event**: `EmailNotifyExpiryAndNewTask` publishes a `MailmanRequest` message to the `WishlistMailman` MBus destination. The message contains the user UUID, lists of expiring deal UUIDs, and recently-added deal UUIDs.
   - From: `wishlistMessagingIntegration`
   - To: `messageBus` (topic `jms.topic.WishlistMailman`)
   - Protocol: MBus (STOMP)

8. **Update notification state**: After publishing, the service records the email notification timestamp for the user to enforce the `minTimeSinceLastNotification` suppression window.
   - From: `wishlistPersistenceLayer`
   - To: `continuumWishlistPostgresRw`
   - Protocol: JDBC

9. **Mailman dispatches email**: Mailman (or a dedicated consumer of the `WishlistMailman` topic) picks up the notification event, fetches localized templates from the Localize service, renders the email, and sends it to the user.
   - From: `messageBus`
   - To: `continuumEmailService`
   - Protocol: MBus (STOMP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unavailable | Exception logged; item skipped for this processing cycle | No notification sent; item reprocessed next cycle |
| Voucher Inventory Service unavailable | Exception logged; expiry not updated | Item's `expires` field remains null; skipped by expiry filter |
| MBus publish failure | Exception logged via Steno | Notification not sent; item reprocessed next cycle if conditions still met |
| User processing task exception | Exception caught per-user in `UserDequeueJob`; exception counter incremented | Other users in batch continue processing |
| `backgroundProcessingConfig.enabled=false` | Job triggers are disabled in YAML | No processing occurs (controlled via env config) |

## Sequence Diagram

```
[Quartz Scheduler] -> wishlistBackgroundJobs: UserEnqueueJob fires (every 5s)
wishlistBackgroundJobs -> continuumWishlistPostgresRo: fetch users for free bucket
continuumWishlistPostgresRo --> wishlistBackgroundJobs: List<userId>
wishlistBackgroundJobs -> continuumWishlistRedisCluster: LPUSH userId batch

[Quartz Scheduler] -> wishlistBackgroundJobs: UserDequeueJob fires (every 2s)
wishlistBackgroundJobs -> continuumWishlistRedisCluster: RPOP userId batch
continuumWishlistRedisCluster --> wishlistBackgroundJobs: Set<userId>

wishlistBackgroundJobs -> wishlistPersistenceLayer: loadItems(userId)
wishlistPersistenceLayer -> continuumWishlistPostgresRo: SELECT items WHERE consumerId=...
continuumWishlistPostgresRo --> wishlistPersistenceLayer: List<Item>

wishlistBackgroundJobs -> wishlistExternalClients: fetchDealMetadata(dealId)
wishlistExternalClients -> continuumDealCatalogService: GET /deal/{dealId}
continuumDealCatalogService --> wishlistExternalClients: DealMetadata

wishlistBackgroundJobs -> wishlistExternalClients: fetchInventory(dealId, vertical)
wishlistExternalClients -> continuumVoucherInventoryService: GET /inventory/v1/products/{dealId}
continuumVoucherInventoryService --> wishlistExternalClients: InventoryData

wishlistBackgroundJobs -> wishlistMessagingIntegration: publishNotification(userId, expiringDeals, newDeals)
wishlistMessagingIntegration -> messageBus: PUBLISH WishlistMailman topic
messageBus -> continuumEmailService: deliver notification event
continuumEmailService --> messageBus: ACK

wishlistBackgroundJobs -> continuumWishlistPostgresRw: UPDATE user SET notifyEmail=now()
```

## Related

- Architecture component view: `components-wishlist-service`
- Related flows: [User Bucket Enqueue Dequeue](user-bucket-enqueue-dequeue.md), [Order Purchase Mark](order-purchase-mark.md)
