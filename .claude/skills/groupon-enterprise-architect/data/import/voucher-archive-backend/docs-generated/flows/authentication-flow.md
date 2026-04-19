---
service: "voucher-archive-backend"
title: "Authentication Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "authentication-flow"
flow_type: synchronous
trigger: "Any inbound API request bearing an Authorization header"
participants:
  - "continuumVoucherArchiveBackendApp"
  - "continuumUsersService"
  - "continuumCsTokenService"
architecture_ref: "dynamic-voucher-archive-authentication"
---

# Authentication Flow

## Summary

All protected endpoints in the voucher-archive-backend require caller authentication. The service does not perform local token validation — instead it delegates to one of three upstream auth services based on the caller role: the Users Service for consumers, the CS Token Service for CSRs, and the MX Merchant API for merchants. This flow describes the shared authentication sub-flow invoked at the start of every protected request.

## Trigger

- **Type**: api-call
- **Source**: Any inbound request to a protected endpoint (consumer, merchant, or CSR namespace)
- **Frequency**: Per request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller Client | Provides bearer or session token in Authorization header | external |
| Voucher Archive API (`authClients`) | Selects appropriate auth service and delegates token validation | `continuumVoucherArchiveBackendApp` |
| Users Service | Validates consumer bearer tokens | `continuumUsersService` |
| CS Token Service | Validates CSR session tokens | `continuumCsTokenService` |
| MX Merchant API | Validates merchant authentication tokens | external / MX Merchant API |

## Steps

1. **Receives request with token**: Caller sends an HTTP request to a protected endpoint with an `Authorization` header containing a bearer token or session token.
   - From: `Caller Client`
   - To: `continuumVoucherArchiveBackendApp`
   - Protocol: REST / HTTP

2. **Identifies caller role**: The `authClients` component determines the caller type based on the request path namespace (`/consumers/`, `/merchants/`, `/csrs/`) and selects the corresponding auth service.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumVoucherArchiveBackendApp` (internal routing logic)
   - Protocol: direct

3a. **Validates consumer token (if consumer)**: Sends token to Users Service for validation.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumUsersService`
   - Protocol: REST

3b. **Validates CSR token (if CSR)**: Sends token to CS Token Service for validation.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `continuumCsTokenService`
   - Protocol: REST

3c. **Validates merchant token (if merchant)**: Sends token to MX Merchant API for validation.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `MX Merchant API`
   - Protocol: REST

4. **Auth service responds**: The upstream auth service confirms the token is valid and returns the confirmed identity (user_id, merchant_id, or csr_id).
   - From: `Auth Service`
   - To: `continuumVoucherArchiveBackendApp`
   - Protocol: REST

5. **Continues with authorized request**: On success, the request proceeds to the business logic handler. On failure, a 401 is returned immediately.
   - From: `continuumVoucherArchiveBackendApp`
   - To: `Caller Client` (on failure) or internal handler (on success)
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing Authorization header | Request rejected before auth service call | 401 Unauthorized |
| Invalid or malformed token | Auth service returns 401 | 401 Unauthorized |
| Expired token | Auth service returns 401 | 401 Unauthorized |
| Auth service unreachable | Connection error; request cannot be authorized | 503 Service Unavailable |
| Token valid for wrong caller role | Auth service or ownership check fails | 403 Forbidden |

## Sequence Diagram

```
Caller -> VoucherArchiveAPI: GET/POST/PUT /ls-voucher-archive/api/v1/<namespace>/...
VoucherArchiveAPI -> VoucherArchiveAPI: identify caller role from path namespace
alt consumer
  VoucherArchiveAPI -> UsersService: validate bearer token
  UsersService --> VoucherArchiveAPI: 200 OK (user_id)
else CSR
  VoucherArchiveAPI -> CsTokenService: validate session token
  CsTokenService --> VoucherArchiveAPI: 200 OK (csr_id)
else merchant
  VoucherArchiveAPI -> MxMerchantAPI: validate merchant token
  MxMerchantAPI --> VoucherArchiveAPI: 200 OK (merchant_id)
end
VoucherArchiveAPI -> VoucherArchiveAPI: proceed to request handler
```

## Related

- Architecture dynamic view: `dynamic-voucher-archive-authentication`
- Related flows: [Consumer Retrieve Vouchers](consumer-retrieve-vouchers.md), [Merchant Redeem Voucher](merchant-redeem-voucher.md), [CSR Process Refund](csr-process-refund.md), [Merchant Bulk Redeem](merchant-bulk-redeem.md)
