---
service: "voucher-inventory-service"
title: "Voucher Redemption"
generated: "2026-03-03"
type: flow
flow_name: "voucher-redemption"
flow_type: synchronous
trigger: "API call from consumer or merchant to redeem a voucher"
participants:
  - "continuumVoucherInventoryApi"
  - "continuumVoucherInventoryApi_unitsAndRedemptionsApi"
  - "continuumVoucherInventoryApi_inventoryUnitManager"
  - "continuumVoucherInventoryApi_merchantServiceClient"
  - "continuumVoucherInventoryApi_geoServiceClient"
  - "continuumVoucherInventoryApi_inventoryDataAccessors"
  - "continuumVoucherInventoryApi_cacheAccessors"
  - "continuumVoucherInventoryApi_inventoryProductsMessageProducer"
  - "continuumVoucherInventoryUnitsDb"
  - "continuumVoucherInventoryMessageBus"
architecture_ref: "dynamic-continuum-voucher-inventory"
---

# Voucher Redemption

## Summary

The voucher redemption flow handles the process of a consumer or merchant redeeming a voucher unit. It validates the unit status, loads merchant and location data, optionally validates location constraints via the Geo Service, transitions the unit to redeemed status, and publishes a domain event for downstream consumers. This flow supports multiple redemption types including standard, barcode, and third-party code pool redemptions.

## Trigger

- **Type**: api-call
- **Source**: Consumer app, merchant tool, or internal service calling redemption endpoints
- **Frequency**: per-request (every voucher redemption)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Voucher Inventory API | Entry point, routes HTTP request | `continuumVoucherInventoryApi` |
| Units & Redemptions API | Handles redemption HTTP endpoints | `continuumVoucherInventoryApi_unitsAndRedemptionsApi` |
| Inventory Unit Manager | Orchestrates redemption logic and state transitions | `continuumVoucherInventoryApi_inventoryUnitManager` |
| Merchant Service Client | Loads merchant and location data | `continuumVoucherInventoryApi_merchantServiceClient` |
| Geo Service Client | Validates redemption location constraints | `continuumVoucherInventoryApi_geoServiceClient` |
| Cache & Lock Accessors | Acquires distributed lock on unit | `continuumVoucherInventoryApi_cacheAccessors` |
| Inventory Data Accessors | Persists redemption records | `continuumVoucherInventoryApi_inventoryDataAccessors` |
| Inventory Products Message Producer | Publishes redemption event | `continuumVoucherInventoryApi_inventoryProductsMessageProducer` |
| Voucher Inventory Units DB | Stores redemption records and status | `continuumVoucherInventoryUnitsDb` |
| Voucher Inventory Message Bus | Receives published events | `continuumVoucherInventoryMessageBus` |

## Steps

1. **Receive redemption request**: Client sends a redemption request to the Units & Redemptions API endpoint.
   - From: External caller
   - To: `continuumVoucherInventoryApi_unitsAndRedemptionsApi`
   - Protocol: REST/HTTPS

2. **Delegate to unit manager**: The API delegates to the Inventory Unit Manager for redemption orchestration.
   - From: `continuumVoucherInventoryApi_unitsAndRedemptionsApi`
   - To: `continuumVoucherInventoryApi_inventoryUnitManager`
   - Protocol: Ruby method calls

3. **Load merchant data**: Unit Manager calls Merchant Service Client to load merchant and location information.
   - From: `continuumVoucherInventoryApi_inventoryUnitManager`
   - To: `continuumVoucherInventoryApi_merchantServiceClient`
   - Protocol: HTTPS/JSON

4. **Validate location (if applicable)**: For location-constrained vouchers, validate the redemption location via Geo Service.
   - From: `continuumVoucherInventoryApi_inventoryUnitManager`
   - To: `continuumVoucherInventoryApi_geoServiceClient`
   - Protocol: HTTPS/JSON

5. **Acquire distributed lock**: Lock the unit to prevent concurrent redemption attempts.
   - From: `continuumVoucherInventoryApi_inventoryUnitManager`
   - To: `continuumVoucherInventoryApi_cacheAccessors`
   - Protocol: Redis

6. **Persist redemption**: Create the redemption record and transition unit status to redeemed.
   - From: `continuumVoucherInventoryApi_inventoryUnitManager`
   - To: `continuumVoucherInventoryApi_inventoryDataAccessors`
   - Protocol: ActiveRecord/SQL

7. **Publish redemption event**: Publish a domain event for downstream consumers (sold count updates, analytics).
   - From: `continuumVoucherInventoryApi_inventoryProductsMessageProducer`
   - To: `continuumVoucherInventoryMessageBus`
   - Protocol: JMS topics

8. **Return redemption confirmation**: Return success with redemption details.
   - From: `continuumVoucherInventoryApi_unitsAndRedemptionsApi`
   - To: External caller
   - Protocol: REST/HTTPS (response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unit not in redeemable status | Return 422 with status error | Redemption rejected |
| Merchant Service unavailable | Return 503 with dependency error | Caller retries |
| Geo validation failure | Return 422 with location error | Redemption rejected for location constraint |
| Distributed lock timeout | Return 503 / retry-able error | Caller retries after backoff |
| Database write failure | Transaction rollback, release lock | Return 500 |

## Sequence Diagram

```
Client -> Units & Redemptions API: POST /inventory/v2/redemptions
Units & Redemptions API -> Inventory Unit Manager: redeemUnit(unitId, redemptionData)
Inventory Unit Manager -> Merchant Service Client: getMerchant(merchantId)
Merchant Service Client --> Inventory Unit Manager: merchantData
Inventory Unit Manager -> Geo Service Client: validateLocation(unitId, location)
Geo Service Client --> Inventory Unit Manager: locationValid
Inventory Unit Manager -> Cache & Lock Accessors: acquireLock(unitId)
Inventory Unit Manager -> Inventory Data Accessors: createRedemption(unitId, data)
Inventory Data Accessors -> Units DB: INSERT unit_redemptions, UPDATE inventory_units
Inventory Unit Manager -> Message Producer: publishRedemptionEvent(unitId)
Message Producer -> Message Bus: publish(voucher_inventory.unit.redeemed)
Inventory Unit Manager -> Cache & Lock Accessors: releaseLock(unitId)
Inventory Unit Manager --> Units & Redemptions API: redemptionConfirmation
Units & Redemptions API --> Client: 201 Created {redemptionId, details}
```

## Related

- Architecture dynamic view: `dynamic-continuum-voucher-inventory`
- Related flows: [Inventory Reservation](inventory-reservation.md), [Order Status Sync](order-status-sync.md)
