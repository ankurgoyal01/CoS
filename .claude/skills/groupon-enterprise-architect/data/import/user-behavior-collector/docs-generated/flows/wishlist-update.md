---
service: "user-behavior-collector"
title: "Wishlist Update"
generated: "2026-03-03"
type: flow
flow_name: "wishlist-update"
flow_type: scheduled
trigger: "Daily cron (update_wishlist) at 04:00 UTC (NA only)"
participants:
  - "continuumUserBehaviorCollectorJob"
  - "continuumDealViewNotificationDb"
  - "continuumWishlistService"
architecture_ref: "continuumUserBehaviorCollectorJob-components"
---

# Wishlist Update

## Summary

The Wishlist Update flow reads consumer IDs from the `deal_view_notification` database for consumers who have viewed deals, queries the Wishlist Service to retrieve each consumer's default wishlist, and persists updated wishlist item flags back to the database. This flow runs as a separate cron job (`update_wishlist`) in NA and keeps the local wishlist snapshot synchronized with the canonical Wishlist Service, enabling wishlist-based audience segmentation and triggered notifications.

## Trigger

- **Type**: schedule
- **Source**: System cron at `/etc/cron.d/user-behavior-collector`; runs the `update_wishlist` script
- **Frequency**: Daily — NA production: 04:00 UTC (EMEA: no evidence of separate wishlist cron for EMEA)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Job Orchestrator | Invoked with `-updateWishlistOnly`; triggers wishlist update step | `continuumUserBehaviorCollectorJob` |
| Wishlist Updater | Reads consumer IDs from DB; queries Wishlist Service; writes updates back to DB | `continuumUserBehaviorCollectorJob` (wishlistUpdater component) |
| Deal View Notification DB | Source of consumer IDs; target for wishlist flag writes | `continuumDealViewNotificationDb` |
| Wishlist Service | Provides current per-consumer wishlist items | `continuumWishlistService` |

## Steps

1. **Read consumer IDs from DB**: Wishlist Updater calls `getDealViewConsumerIdsForWishList()` on `AppDataConnection` to retrieve UUIDs of consumers who have deal-view records in `continuumDealViewNotificationDb`
   - From: `continuumUserBehaviorCollectorJob` (wishlistUpdater)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC

2. **Query Wishlist Service per consumer**: For each consumer UUID, calls `GET wishlists/v1/lists/query?consumerId=<uuid>&listName=default&sort=created` via `WishlistServiceClient.getWishlistDeals()`
   - From: `continuumUserBehaviorCollectorJob` (wishlistUpdater)
   - To: `continuumWishlistService`
   - Protocol: REST (OkHttp, SSL)

3. **Parse wishlist response**: Deserializes `GetWishlistDealResponse` JSON; extracts list of `dealId` UUIDs from `data.items`

4. **Persist wishlist flags to DB**: Writes updated wishlist item records per consumer back to `continuumDealViewNotificationDb` via Data Access Layer batch updates
   - From: `continuumUserBehaviorCollectorJob` (wishlistUpdater)
   - To: `continuumDealViewNotificationDb`
   - Protocol: JDBC (batch commit)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Wishlist Service returns non-200 | Logs at WARN with status, response body, URL, and headers; metrics counter incremented | Returns empty list; wishlist not updated for that consumer |
| Wishlist Service call throws exception | Catches all exceptions; logs at INFO level | Returns empty list; processing continues for next consumer |
| Consumer address connection error | Logged as INFO: "Error happened while calling wishlist service: Cannot assign requested address" | Consumer skipped |
| DB batch commit error | Exception would propagate; job fails | PagerDuty alert; rerun with `-updateWishlistOnly` |

## Sequence Diagram

```
CronScheduler -> JobOrchestrator: Invoke update_wishlist script (-updateWishlistOnly)
JobOrchestrator -> WishlistUpdater: Trigger wishlist update
WishlistUpdater -> DealViewNotificationDb: getDealViewConsumerIdsForWishList()
DealViewNotificationDb --> WishlistUpdater: List<UUID> consumerIds
loop for each consumerId
  WishlistUpdater -> WishlistService: GET wishlists/v1/lists/query?consumerId=<uuid>&listName=default&sort=created
  WishlistService --> WishlistUpdater: GetWishlistDealResponse (list of dealId UUIDs) or error
  WishlistUpdater -> WishlistUpdater: Extract wishlist deal IDs
  WishlistUpdater -> DataAccessLayer: Write wishlist flags to DB (batch)
  DataAccessLayer -> DealViewNotificationDb: Batch commit wishlist updates
end
WishlistUpdater --> JobOrchestrator: Done
```

## Related

- Architecture dynamic view: `continuumUserBehaviorCollectorJob-components`
- Related flows: [Spark Event Ingestion](spark-event-ingestion.md), [Audience Publishing](audience-publishing.md)
