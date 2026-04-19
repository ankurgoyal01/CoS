---
service: "voucher-archive-backend"
title: "Consumer Retrieve Vouchers"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "consumer-retrieve-vouchers"
flow_type: synchronous
trigger: "GET request to /ls-voucher-archive/api/v1/consumers/:id/vouchers"
participants:
  - "continuumVoucherArchiveBackendApp"
  - "continuumUsersService"
  - "continuumVoucherArchiveOrdersDb"
  - "continuumVoucherArchiveDealsDb"
architecture_ref: "dynamic-voucher-archive-consumer-retrieve"
---

# Consumer Retrieve Vouchers

## Summary

A consumer client calls the archive API to retrieve all LivingSocial vouchers associated with their account. The service validates the consumer's bearer token against the Users Service, queries the orders and deals databases for voucher and deal data, and returns a serialized list of vouchers. PDF and QR code generation are available on individual voucher endpoints.

## Trigger

- **Type**: api-call
- **Source**: Consumer mobile app or web client
- **Frequency**: On demand, per user request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer Client | Initiates request with bearer token | external |
| Voucher Archive API | Authenticates caller, queries databases, serializes response | `continuumVoucherArchiveBackendApp` |
| Users Service | Validates consumer bearer token | `continuumUsersService` |
| Orders Database | Provides coupon/voucher records for the consumer | `continuumVoucherArchiveOrdersDb` |
| Deals Database | Provides deal metadata for each voucher | `continuumVoucherArchiveDealsDb` |

## Steps

1. **Receives request**: Consumer client sends GET `/ls-voucher-archive/api/v1/consumers/:id/vouchers` with `Authorization: Bearer <token>` header.
   - From: `Consumer Client`
   - To: `continuumVoucherArchiveBackendApp`
   - Protocol: REST / HTTP

2. **Validates bearer token**: API controller delegates token validation to the Users Service.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumUsersService`
   - Protocol: REST

3. **Queries voucher records**: On successful auth, `voucherRepositories` queries the orders database for all coupons/vouchers belonging to the consumer.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveOrdersDb`
   - Protocol: MySQL

4. **Retrieves deal metadata**: For each voucher, `voucherRepositories` fetches the associated deal record (title, merchant, options) from the deals database.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveDealsDb`
   - Protocol: MySQL

5. **Serializes and returns response**: `voucherServices` assembles the voucher list with deal data and returns it as a JSON response.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `Consumer Client`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired bearer token | Users Service returns 401; API returns 401 to caller | Consumer receives 401 Unauthorized |
| Consumer not found in orders database | Returns empty voucher list | 200 with empty array |
| Orders database unreachable | Database connection error raised | 503 Service Unavailable |
| Deals database unreachable | Database connection error raised | 503 Service Unavailable |

## Sequence Diagram

```
Consumer -> VoucherArchiveAPI: GET /ls-voucher-archive/api/v1/consumers/:id/vouchers
VoucherArchiveAPI -> UsersService: POST /validate (bearer token)
UsersService --> VoucherArchiveAPI: 200 OK (token valid, user_id confirmed)
VoucherArchiveAPI -> OrdersDB: SELECT coupons WHERE user_id = :id
OrdersDB --> VoucherArchiveAPI: coupon records
VoucherArchiveAPI -> DealsDB: SELECT deals WHERE deal_id IN (...)
DealsDB --> VoucherArchiveAPI: deal records
VoucherArchiveAPI --> Consumer: 200 OK (voucher list JSON)
```

## Related

- Architecture dynamic view: `dynamic-voucher-archive-consumer-retrieve`
- Related flows: [Authentication Flow](authentication-flow.md), [Deal Retrieval](deal-retrieval.md)
