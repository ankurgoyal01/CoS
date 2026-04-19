---
service: "wishlist-service"
title: "Order Purchase Mark"
generated: "2026-03-03"
type: flow
flow_name: "order-purchase-mark"
flow_type: asynchronous
trigger: "MBus ItemPurchases event from Orders service after order transaction completes"
participants:
  - "messageBus"
  - "wishlistMessagingIntegration"
  - "wishlistApplicationServices"
  - "wishlistExternalClients"
  - "continuumOrdersService"
  - "continuumDealCatalogService"
  - "wishlistPersistenceLayer"
  - "continuumWishlistPostgresRw"
architecture_ref: "components-wishlist-service"
---

# Order Purchase Mark

## Summary

When a user completes a purchase on Groupon, the Orders service publishes an order transaction event to the `jms.topic.Orders.Transactions` MBus topic. The Wishlist Service worker consumes this event and marks any matching wishlist items as purchased or gifted by setting a timestamp on the item record in PostgreSQL. This enables the wishlist UI to reflect which deals have already been bought.

## Trigger

- **Type**: event
- **Source**: MBus topic `jms.topic.Orders.Transactions` (published by the Orders service on transaction completion)
- **Frequency**: Per order transaction — event-driven

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBus | Delivers the order transaction event to the durable subscriber | `messageBus` |
| Message Bus Integration | Consumes the event from the `ItemPurchases` destination | `wishlistMessagingIntegration` |
| Application Services | Orchestrates the item-purchase update logic | `wishlistApplicationServices` |
| External Service Clients | Fetches full order details and deal-to-option mappings | `wishlistExternalClients` |
| Orders Service | Returns full order details (items, status, creation date) | `continuumOrdersService` |
| Deal Catalog Service | Maps option IDs to deal IDs | `continuumDealCatalogService` |
| Persistence Layer | Updates purchased/gifted timestamp on matching wishlist items | `wishlistPersistenceLayer` |
| Wishlist Postgres RW | Stores the purchase state update | `continuumWishlistPostgresRw` |

## Steps

1. **Receive order transaction event**: MBus delivers the serialized order transaction message to the `ItemPurchases` durable subscriber (subscription ID `engagement-list_manager-production`) on the worker component.
   - From: `messageBus`
   - To: `wishlistMessagingIntegration` (`ItemPurchasesProcessor`)
   - Protocol: MBus (STOMP)

2. **Deserialize event**: The `ItemPurchasesProcessor` deserializes the order transaction message and extracts the `orderId`, `consumerId`, and item references.
   - From: `wishlistMessagingIntegration`
   - To: `wishlistApplicationServices`
   - Protocol: direct

3. **Fetch full order details**: Application Services instructs External Service Clients to fetch the full order record from the Orders Service using `orderId` and `consumerId`. Only items with status `"collected"` are processed.
   - From: `wishlistApplicationServices` → `wishlistExternalClients`
   - To: `continuumOrdersService`: `GET /orders/{orderId}?clientId=wishlist`
   - Protocol: HTTP

4. **Map option IDs to deal IDs**: For each purchased item's `optionId`, External Service Clients look up the corresponding `dealId` via the Deal Catalog Service.
   - From: `wishlistExternalClients`
   - To: `continuumDealCatalogService`: `GET /deal?optionId=<uuid>&clientId=edc279c643e5b7bb-Wishlist`
   - Protocol: HTTP

5. **Find matching wishlist items**: Persistence Layer queries the read-write PostgreSQL for wishlist items belonging to the `consumerId` that match the resolved `dealId` and are not yet marked as purchased.
   - From: `wishlistApplicationServices`
   - To: `wishlistPersistenceLayer` → `continuumWishlistPostgresRw`
   - Protocol: JDBC

6. **Update purchased/gifted timestamp**: Persistence Layer sets the `purchased` or `gifted` timestamp on each matching wishlist item record.
   - From: `wishlistPersistenceLayer`
   - To: `continuumWishlistPostgresRw`
   - Protocol: JDBC

7. **Acknowledge message**: `ItemPurchasesProcessor` acknowledges (ACKs) the MBus message after successful processing.
   - From: `wishlistMessagingIntegration`
   - To: `messageBus`
   - Protocol: MBus (STOMP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Orders Service unavailable | Exception logged via Steno; message NACKed | Message redelivered by MBus; retry on next delivery |
| Deal Catalog mapping fails | Exception logged; processing skipped for that option | Wishlist item not marked purchased for that option |
| PostgreSQL write failure | Exception logged; message NACKed | Message redelivered; retry on next delivery |
| Duplicate event delivery | No explicit idempotency guard; duplicate timestamp update is benign | Purchased timestamp overwritten with same or later value |

## Sequence Diagram

```
messageBus -> wishlistMessagingIntegration: MBus event (ItemPurchases) orderId, consumerId
wishlistMessagingIntegration -> wishlistApplicationServices: processOrderTransaction(orderId, consumerId)
wishlistApplicationServices -> wishlistExternalClients: fetchOrder(orderId, consumerId)
wishlistExternalClients -> continuumOrdersService: GET /orders/{orderId}?clientId=wishlist
continuumOrdersService --> wishlistExternalClients: Order { items: [...] }
wishlistExternalClients --> wishlistApplicationServices: Order
wishlistApplicationServices -> wishlistExternalClients: lookupDeal(optionId) [per item]
wishlistExternalClients -> continuumDealCatalogService: GET /deal?optionId=<uuid>
continuumDealCatalogService --> wishlistExternalClients: dealId
wishlistExternalClients --> wishlistApplicationServices: dealId
wishlistApplicationServices -> wishlistPersistenceLayer: findItems(consumerId, dealId)
wishlistPersistenceLayer -> continuumWishlistPostgresRw: SELECT items WHERE consumerId=... AND dealId=...
continuumWishlistPostgresRw --> wishlistPersistenceLayer: matching item records
wishlistPersistenceLayer --> wishlistApplicationServices: List<Item>
wishlistApplicationServices -> wishlistPersistenceLayer: markPurchased(itemId, purchasedAt)
wishlistPersistenceLayer -> continuumWishlistPostgresRw: UPDATE item SET purchased=now()
continuumWishlistPostgresRw --> wishlistPersistenceLayer: OK
wishlistMessagingIntegration -> messageBus: ACK
```

## Related

- Architecture component view: `components-wishlist-service`
- Related flows: [Background Item Expiry Notification](background-expiry-notification.md)
