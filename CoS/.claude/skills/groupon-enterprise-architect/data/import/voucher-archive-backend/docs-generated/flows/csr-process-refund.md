---
service: "voucher-archive-backend"
title: "CSR Process Refund"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "csr-process-refund"
flow_type: synchronous
trigger: "POST request to /ls-voucher-archive/api/v1/csrs/vouchers/:id/refund"
participants:
  - "continuumVoucherArchiveBackendApp"
  - "continuumCsTokenService"
  - "continuumVoucherArchiveOrdersDb"
architecture_ref: "dynamic-voucher-archive-csr-refund"
---

# CSR Process Refund

## Summary

A Groupon customer service representative processes a refund on a LivingSocial voucher via the CSR API. The service validates the CSR's session token against the CS Token Service, creates a refund record in the orders database, and transitions the coupon state using the AASM state machine. This flow covers all standard CSR-initiated refund scenarios for archived LivingSocial vouchers.

## Trigger

- **Type**: api-call
- **Source**: CSR tooling / internal customer service platform
- **Frequency**: On demand, per customer service case

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CSR Tooling | Initiates refund request with CSR session token | external |
| Voucher Archive API | Authenticates CSR, creates refund, updates coupon state | `continuumVoucherArchiveBackendApp` |
| CS Token Service | Validates CSR session token | `continuumCsTokenService` |
| Orders Database | Stores refund record; source and target of coupon state | `continuumVoucherArchiveOrdersDb` |

## Steps

1. **Receives refund request**: CSR tooling sends POST `/ls-voucher-archive/api/v1/csrs/vouchers/:id/refund` with CSR session token and refund details.
   - From: `CSR Tooling`
   - To: `continuumVoucherArchiveBackendApp`
   - Protocol: REST / HTTP

2. **Validates CSR token**: API controller sends session token to the CS Token Service for validation.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumCsTokenService`
   - Protocol: REST

3. **Loads voucher record**: `refundServices` fetches the coupon record by voucher ID from the orders database.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

4. **Creates refund record**: `refundServices` inserts a refund record into the orders database with the refund amount and reason.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

5. **Updates coupon state**: AASM state machine transitions the coupon to `refunded` state, recording the `refunded_at` timestamp.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

6. **Returns confirmation**: API returns 200 with the updated coupon state and refund record.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `CSR Tooling`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired CSR session token | CS Token Service returns 401; API returns 401 | CSR receives 401 Unauthorized |
| Voucher not found | No record in orders database | 404 Not Found |
| Voucher already refunded | AASM guard prevents duplicate transition | 422 Unprocessable Entity |
| Voucher not in refundable state | AASM guard fails | 422 Unprocessable Entity |
| Database write failure | Exception during refund record insert | 500 Internal Server Error |

## Sequence Diagram

```
CSRTooling -> VoucherArchiveAPI: POST /ls-voucher-archive/api/v1/csrs/vouchers/:id/refund
VoucherArchiveAPI -> CsTokenService: validate CSR session token
CsTokenService --> VoucherArchiveAPI: 200 OK (CSR identity confirmed)
VoucherArchiveAPI -> OrdersDB: SELECT coupon WHERE coupon_id = :id
OrdersDB --> VoucherArchiveAPI: coupon record
VoucherArchiveAPI -> OrdersDB: INSERT INTO refunds (coupon_id, amount, reason)
OrdersDB --> VoucherArchiveAPI: refund record created
VoucherArchiveAPI -> OrdersDB: UPDATE coupons SET state='refunded', refunded_at=NOW()
OrdersDB --> VoucherArchiveAPI: write confirmed
VoucherArchiveAPI --> CSRTooling: 200 OK (refund processed)
```

## Related

- Architecture dynamic view: `dynamic-voucher-archive-csr-refund`
- Related flows: [Authentication Flow](authentication-flow.md), [Consumer Retrieve Vouchers](consumer-retrieve-vouchers.md)
