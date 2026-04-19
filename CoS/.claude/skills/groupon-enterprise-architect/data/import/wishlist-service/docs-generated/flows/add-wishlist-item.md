---
service: "wishlist-service"
title: "Add Wishlist Item"
generated: "2026-03-03"
type: flow
flow_name: "add-wishlist-item"
flow_type: synchronous
trigger: "API POST request from GAPI or mobile app"
participants:
  - "wishlistApiResources"
  - "wishlistApplicationServices"
  - "wishlistPersistenceLayer"
  - "continuumWishlistPostgresRw"
  - "continuumWishlistRedisCluster"
architecture_ref: "components-wishlist-service"
---

# Add Wishlist Item

## Summary

This flow covers the synchronous path by which a user (via GAPI, deal page, or mobile app) adds a deal and/or option to one of their wishlist lists. The service resolves the target list by name or ID, persists the new item to PostgreSQL, and returns the updated list response including item metadata and pagination. The GAPI SLA requires this response to complete within 40ms.

## Trigger

- **Type**: api-call
- **Source**: GAPI / iTier wishlist front-end app, deal page, mobile iOS/Android app
- **Frequency**: On-demand (per user interaction)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GAPI / mobile caller | Initiates POST request with consumerId, listName or listId, and item payload | External |
| API Resources | Receives and validates the POST request; extracts consumerId, listName/listId, locale, clientId | `wishlistApiResources` |
| Application Services | Orchestrates list resolution, item creation, and response assembly | `wishlistApplicationServices` |
| Persistence Layer | Reads existing list state; writes new item record | `wishlistPersistenceLayer` |
| Wishlist Postgres RW | Stores the new wishlist item record | `continuumWishlistPostgresRw` |
| Wishlist Redis Cluster | (Optional) Reads cached list or deal metadata if caching enabled | `continuumWishlistRedisCluster` |

## Steps

1. **Receive add-item request**: GAPI or mobile app sends `POST /wishlists/v1/lists?consumerId=<uuid>&listName=<name>` or `POST /wishlists/v1/lists/{listId}` with JSON body `{"dealId": "<uuid>", "optionId": "<uuid>"}`.
   - From: GAPI / mobile app
   - To: `wishlistApiResources`
   - Protocol: REST (HTTP)

2. **Parse and validate request**: API Resources extracts `consumerId` (required, UUID), `listName` or `listId`, `locale`, `bcookie`, `isPublic`, `clientId`, and the request body (`AddItemRequest`).
   - From: `wishlistApiResources`
   - To: `wishlistApplicationServices`
   - Protocol: direct

3. **Resolve target list**: Application Services looks up the user's list by name or ID from PostgreSQL read-write (or read-only if caching path). If the list does not exist (add-by-name path), a new list is created.
   - From: `wishlistApplicationServices`
   - To: `wishlistPersistenceLayer` → `continuumWishlistPostgresRw`
   - Protocol: JDBC

4. **Create wishlist item**: Application Services instructs the Persistence Layer to insert a new item row associating the `listId`, `dealId`, `optionId`, `consumerId`, and `locale`. The item receives a generated UUID as `itemId` and a `created` timestamp.
   - From: `wishlistApplicationServices`
   - To: `wishlistPersistenceLayer` → `continuumWishlistPostgresRw`
   - Protocol: JDBC

5. **Assemble response**: Application Services fetches the updated list (items + pagination metadata) and constructs a `GetListResponse` containing the `ItemList` data and `Pagination` object.
   - From: `wishlistApplicationServices`
   - To: `wishlistApiResources`
   - Protocol: direct

6. **Return response**: API Resources serializes the response to JSON and returns HTTP 200 with the updated list payload.
   - From: `wishlistApiResources`
   - To: GAPI / mobile app
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required `consumerId` | Input validation in API Resources | HTTP 400 Bad Request |
| List not found (by ID) | Application Services returns not-found error | HTTP 4xx response |
| PostgreSQL write failure | Exception propagated; logged via Steno | HTTP 500 Internal Server Error |
| Response exceeds 40ms | GAPI drops the response upstream | User sees no wishlist indicator update |

## Sequence Diagram

```
Caller -> wishlistApiResources: POST /wishlists/v1/lists/{listId} (consumerId, dealId, optionId)
wishlistApiResources -> wishlistApplicationServices: addItem(listId, consumerId, dealId, optionId, locale)
wishlistApplicationServices -> wishlistPersistenceLayer: resolveList(listId, consumerId)
wishlistPersistenceLayer -> continuumWishlistPostgresRw: SELECT list WHERE listId=...
continuumWishlistPostgresRw --> wishlistPersistenceLayer: list record
wishlistPersistenceLayer --> wishlistApplicationServices: ItemList
wishlistApplicationServices -> wishlistPersistenceLayer: insertItem(listId, dealId, optionId)
wishlistPersistenceLayer -> continuumWishlistPostgresRw: INSERT item
continuumWishlistPostgresRw --> wishlistPersistenceLayer: item record
wishlistPersistenceLayer --> wishlistApplicationServices: saved Item
wishlistApplicationServices --> wishlistApiResources: GetListResponse
wishlistApiResources --> Caller: HTTP 200 { data: ItemList, pagination: {...} }
```

## Related

- Architecture component view: `components-wishlist-service`
- Related flows: [Get Wishlist Lists](get-wishlist-lists.md)
