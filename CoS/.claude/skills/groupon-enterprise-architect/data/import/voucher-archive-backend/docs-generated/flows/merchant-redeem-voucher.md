---
service: "voucher-archive-backend"
title: "Merchant Redeem Voucher"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-redeem-voucher"
flow_type: synchronous
trigger: "PUT request to /ls-voucher-archive/api/v1/vouchers/:id/redeem"
participants:
  - "continuumVoucherArchiveBackendApp"
  - "continuumMxMerchantApi"
  - "continuumVoucherArchiveOrdersDb"
architecture_ref: "dynamic-voucher-archive-merchant-redeem"
---

# Merchant Redeem Voucher

## Summary

A merchant uses the archive API to mark a LivingSocial voucher as redeemed at point of service. The service validates the merchant's authentication token via the MX Merchant API, confirms the voucher belongs to the merchant's deal, applies the AASM state machine transition from active to redeemed, and persists the updated state. Single-voucher redemption; for batch operations see [Merchant Bulk Redeem](merchant-bulk-redeem.md).

## Trigger

- **Type**: api-call
- **Source**: Merchant portal or point-of-sale integration
- **Frequency**: On demand, per customer transaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Client | Initiates redemption request with merchant token | external |
| Voucher Archive API | Authenticates merchant, validates ownership, executes state transition | `continuumVoucherArchiveBackendApp` |
| MX Merchant API | Validates merchant authentication token | external / MX Merchant API |
| Orders Database | Source of coupon record; target of redeemed state write | `continuumVoucherArchiveOrdersDb` |

## Steps

1. **Receives redemption request**: Merchant client sends PUT `/ls-voucher-archive/api/v1/vouchers/:id/redeem` with merchant auth token.
   - From: `Merchant Client`
   - To: `continuumVoucherArchiveBackendApp`
   - Protocol: REST / HTTP

2. **Validates merchant token**: API controller sends token to the MX Merchant API for validation.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `MX Merchant API`
   - Protocol: REST

3. **Loads voucher record**: `voucherRepositories` fetches the coupon record by voucher ID from the orders database.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

4. **Validates ownership**: `voucherServices` confirms the voucher's deal is associated with the authenticated merchant.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveBackendApp` (internal logic)
   - Protocol: direct

5. **Applies state transition**: AASM state machine transitions the coupon from `active` to `redeemed`, recording `redeemed_at` timestamp.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

6. **Returns confirmation**: API returns 200 with updated voucher state.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `Merchant Client`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid merchant token | MX Merchant API returns 401; API returns 401 | Merchant receives 401 Unauthorized |
| Voucher not found | No record in orders database | 404 Not Found |
| Voucher ownership mismatch | voucherServices guard fails | 403 Forbidden |
| Voucher already redeemed | AASM guard prevents invalid transition | 422 Unprocessable Entity |
| Voucher already refunded | AASM guard prevents invalid transition | 422 Unprocessable Entity |
| Database write failure | Exception raised during state transition | 500 Internal Server Error |

## Sequence Diagram

```
MerchantClient -> VoucherArchiveAPI: PUT /ls-voucher-archive/api/v1/vouchers/:id/redeem
VoucherArchiveAPI -> MxMerchantAPI: validate merchant token
MxMerchantAPI --> VoucherArchiveAPI: 200 OK (merchant identity confirmed)
VoucherArchiveAPI -> OrdersDB: SELECT coupon WHERE coupon_id = :id
OrdersDB --> VoucherArchiveAPI: coupon record (state: active)
VoucherArchiveAPI -> VoucherArchiveAPI: validate merchant ownership
VoucherArchiveAPI -> OrdersDB: UPDATE coupons SET state='redeemed', redeemed_at=NOW()
OrdersDB --> VoucherArchiveAPI: write confirmed
VoucherArchiveAPI --> MerchantClient: 200 OK (voucher redeemed)
```

## Related

- Architecture dynamic view: `dynamic-voucher-archive-merchant-redeem`
- Related flows: [Merchant Bulk Redeem](merchant-bulk-redeem.md), [Authentication Flow](authentication-flow.md)
