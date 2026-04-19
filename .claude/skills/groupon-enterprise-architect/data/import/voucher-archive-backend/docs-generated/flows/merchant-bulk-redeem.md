---
service: "voucher-archive-backend"
title: "Merchant Bulk Redeem"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-bulk-redeem"
flow_type: synchronous
trigger: "POST request to /ls-voucher-archive/api/v1/merchants/:id/vouchers/bulk_redeem"
participants:
  - "continuumVoucherArchiveBackendApp"
  - "continuumMxMerchantApi"
  - "continuumVoucherArchiveOrdersDb"
architecture_ref: "dynamic-voucher-archive-merchant-bulk-redeem"
---

# Merchant Bulk Redeem

## Summary

A merchant submits a batch of voucher IDs for redemption in a single API call. The service validates the merchant's authentication token, iterates over each voucher in the batch, validates ownership, and applies the AASM redeemed state transition for each eligible voucher. Results are returned per-voucher indicating success or failure reason. This flow is designed for high-volume redemption scenarios at merchant locations.

## Trigger

- **Type**: api-call
- **Source**: Merchant portal or point-of-sale batch processing integration
- **Frequency**: On demand, per batch submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Client | Initiates bulk redemption request with list of voucher IDs | external |
| Voucher Archive API | Authenticates merchant, iterates and processes each voucher | `continuumVoucherArchiveBackendApp` |
| MX Merchant API | Validates merchant authentication token | external / MX Merchant API |
| Orders Database | Source of coupon records; target of redeemed state writes | `continuumVoucherArchiveOrdersDb` |

## Steps

1. **Receives bulk redemption request**: Merchant client sends POST `/ls-voucher-archive/api/v1/merchants/:id/vouchers/bulk_redeem` with merchant auth token and array of voucher IDs.
   - From: `Merchant Client`
   - To: `continuumVoucherArchiveBackendApp`
   - Protocol: REST / HTTP

2. **Validates merchant token**: API controller sends token to the MX Merchant API for validation.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `MX Merchant API`
   - Protocol: REST

3. **Loads voucher records**: `voucherRepositories` fetches all coupon records matching the submitted IDs from the orders database in a batch query.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

4. **Validates and transitions each voucher**: For each voucher, `voucherServices` validates merchant ownership and applies the AASM transition to `redeemed` state. Vouchers that fail validation are recorded with a failure reason without stopping the batch.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

5. **Returns batch results**: API returns 200 with per-voucher success/failure status.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `Merchant Client`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid merchant token | MX Merchant API returns 401; entire batch rejected | 401 Unauthorized |
| One voucher already redeemed | AASM guard fails for that voucher; others proceed | Partial success; failure detail in response |
| One voucher ownership mismatch | voucherServices guard fails for that voucher | Partial success; failure detail in response |
| Empty voucher ID list | Input validation rejects request | 422 Unprocessable Entity |
| Database write failure mid-batch | Exception raised; partial batch may be committed | 500 with partial state; investigation required |

## Sequence Diagram

```
MerchantClient -> VoucherArchiveAPI: POST /ls-voucher-archive/api/v1/merchants/:id/vouchers/bulk_redeem [voucher_ids]
VoucherArchiveAPI -> MxMerchantAPI: validate merchant token
MxMerchantAPI --> VoucherArchiveAPI: 200 OK
VoucherArchiveAPI -> OrdersDB: SELECT coupons WHERE coupon_id IN (...)
OrdersDB --> VoucherArchiveAPI: coupon records
loop for each voucher
  VoucherArchiveAPI -> VoucherArchiveAPI: validate ownership + AASM guard
  VoucherArchiveAPI -> OrdersDB: UPDATE coupons SET state='redeemed' WHERE coupon_id = :id
  OrdersDB --> VoucherArchiveAPI: write confirmed
end
VoucherArchiveAPI --> MerchantClient: 200 OK (per-voucher results)
```

## Related

- Architecture dynamic view: `dynamic-voucher-archive-merchant-bulk-redeem`
- Related flows: [Merchant Redeem Voucher](merchant-redeem-voucher.md), [Authentication Flow](authentication-flow.md)
