---
service: "wishlist-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Wishlist Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Add Wishlist Item](add-wishlist-item.md) | synchronous | API POST request from GAPI/mobile app | User adds a deal/option to a named wishlist list |
| [Get Wishlist Lists](get-wishlist-lists.md) | synchronous | API GET request from GAPI/mobile app | User retrieves all wishlist lists with item counts and metadata |
| [Order Purchase Mark](order-purchase-mark.md) | asynchronous | MBus `ItemPurchases` event from Orders service | Marks wishlist items as purchased after an order transaction |
| [Background Item Expiry Notification](background-expiry-notification.md) | scheduled | Quartz scheduler (UserDequeueJob every 2 seconds) | Processes expiring wishlist items and dispatches email notifications |
| [User Bucket Enqueue Dequeue](user-bucket-enqueue-dequeue.md) | scheduled | Quartz scheduler (UserEnqueueJob every 5s, UserDequeueJob every 2s) | Periodically enqueues users into Redis bucket queue and dequeues for background processing |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Add Wishlist Item** involves `continuumWishlistService` writing to `continuumWishlistPostgresRw` and reading enriched deal data from `continuumDealCatalogService`.
- **Order Purchase Mark** spans `messageBus` (MBus `ItemPurchases` topic), `continuumWishlistService`, `continuumOrdersService`, `continuumDealCatalogService`, and `continuumWishlistPostgresRw`.
- **Background Expiry Notification** involves `continuumWishlistService` reading from `continuumWishlistPostgresRo`, fetching from `continuumDealCatalogService` and `continuumVoucherInventoryService`, and publishing to `messageBus` (`WishlistMailman` topic) which triggers `continuumEmailService`.
