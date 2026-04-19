---
service: "voucher-inventory-service"
title: "Inventory Reservation"
generated: "2026-03-03"
type: flow
flow_name: "inventory-reservation"
flow_type: synchronous
trigger: "API call from checkout flow during order creation"
participants:
  - "continuumVoucherInventoryApi"
  - "continuumVoucherInventoryApi_reservationsApi"
  - "continuumVoucherInventoryApi_inventoryUnitManager"
  - "continuumVoucherInventoryApi_pricingClient"
  - "continuumVoucherInventoryApi_cacheAccessors"
  - "continuumVoucherInventoryApi_inventoryDataAccessors"
  - "continuumVoucherInventoryUnitsDb"
  - "continuumVoucherInventoryRedisCache"
architecture_ref: "dynamic-continuum-voucher-inventory"
---

# Inventory Reservation

## Summary

The inventory reservation flow is triggered during checkout when the Orders service requests VIS to reserve voucher inventory against an order. The flow validates pricing, enforces reservation policies, acquires distributed locks to prevent overselling, creates inventory unit records, and returns reservation confirmation. This is a critical synchronous flow in the purchase pipeline.

## Trigger

- **Type**: api-call
- **Source**: Orders Service / Checkout flow calling `POST /inventory/v1/reservation`
- **Frequency**: per-request (every checkout that includes voucher products)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Voucher Inventory API | Entry point, routes HTTP request | `continuumVoucherInventoryApi` |
| Reservation API | Handles reservation HTTP endpoint | `continuumVoucherInventoryApi_reservationsApi` |
| Inventory Unit Manager | Orchestrates reservation logic | `continuumVoucherInventoryApi_inventoryUnitManager` |
| Pricing Client | Validates pricing during reservation | `continuumVoucherInventoryApi_pricingClient` |
| Cache & Lock Accessors | Acquires distributed lock to prevent overselling | `continuumVoucherInventoryApi_cacheAccessors` |
| Inventory Data Accessors | Persists unit and order mapping records | `continuumVoucherInventoryApi_inventoryDataAccessors` |
| Voucher Inventory Units DB | Stores reserved inventory unit records | `continuumVoucherInventoryUnitsDb` |
| Voucher Inventory Redis Cache | Provides distributed locks | `continuumVoucherInventoryRedisCache` |

## Steps

1. **Receive reservation request**: Orders Service sends POST to `/inventory/v1/reservation` with order details, product IDs, and quantity.
   - From: `orders_api` (external)
   - To: `continuumVoucherInventoryApi_reservationsApi`
   - Protocol: REST/HTTPS

2. **Delegate to unit manager**: Reservation API delegates to the Inventory Unit Manager to execute the reservation workflow.
   - From: `continuumVoucherInventoryApi_reservationsApi`
   - To: `continuumVoucherInventoryApi_inventoryUnitManager`
   - Protocol: Ruby method calls

3. **Validate pricing**: Unit Manager calls the Pricing Client to validate pricing for the reservation.
   - From: `continuumVoucherInventoryApi_inventoryUnitManager`
   - To: `continuumVoucherInventoryApi_pricingClient`
   - Protocol: HTTPS/JSON

4. **Acquire distributed lock**: Unit Manager acquires a Redis distributed lock on the inventory product to prevent concurrent overselling.
   - From: `continuumVoucherInventoryApi_inventoryUnitManager`
   - To: `continuumVoucherInventoryApi_cacheAccessors`
   - Protocol: Redis

5. **Persist reservation**: Unit Manager creates inventory unit records in the Units DB via the data access layer.
   - From: `continuumVoucherInventoryApi_inventoryUnitManager`
   - To: `continuumVoucherInventoryApi_inventoryDataAccessors`
   - Protocol: ActiveRecord/SQL

6. **Write to Units DB**: Data accessors persist the unit and order mapping records.
   - From: `continuumVoucherInventoryApi_inventoryDataAccessors`
   - To: `continuumVoucherInventoryUnitsDb`
   - Protocol: MySQL

7. **Return reservation confirmation**: Reservation API returns confirmation with unit IDs and reservation details to the caller.
   - From: `continuumVoucherInventoryApi_reservationsApi`
   - To: `orders_api` (external)
   - Protocol: REST/HTTPS (response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pricing validation failure | Return 422 with pricing error details | Reservation rejected, checkout flow handles error |
| Distributed lock timeout | Return 503 / retry-able error | Caller retries after backoff |
| Insufficient inventory | Return 409 with inventory exhausted error | Checkout flow notifies customer |
| Database write failure | Transaction rollback, release lock | Return 500, caller retries |

## Sequence Diagram

```
Orders Service -> Reservation API: POST /inventory/v1/reservation
Reservation API -> Inventory Unit Manager: createReservation(orderDetails)
Inventory Unit Manager -> Pricing Client: validatePricing(productId, price)
Pricing Client --> Inventory Unit Manager: pricingValid
Inventory Unit Manager -> Cache & Lock Accessors: acquireLock(productId)
Cache & Lock Accessors -> Redis Cache: SET lock key (NX, EX)
Redis Cache --> Cache & Lock Accessors: lockAcquired
Inventory Unit Manager -> Inventory Data Accessors: createUnits(reservationData)
Inventory Data Accessors -> Units DB: INSERT inventory_units, order_mappings
Units DB --> Inventory Data Accessors: persisted
Inventory Unit Manager -> Cache & Lock Accessors: releaseLock(productId)
Inventory Unit Manager --> Reservation API: reservationConfirmation
Reservation API --> Orders Service: 201 Created {unitIds, reservationDetails}
```

## Related

- Architecture dynamic view: `dynamic-continuum-voucher-inventory`
- Related flows: [Order Status Sync](order-status-sync.md), [Voucher Redemption](voucher-redemption.md)
