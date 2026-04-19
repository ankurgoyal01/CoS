---
service: "itier-ls-voucher-archive"
title: "CSR Refund Voucher Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "csr-refund-voucher"
flow_type: synchronous
trigger: "HTTP POST from CSR agent browser"
participants:
  - "continuumLsVoucherArchiveItier"
  - "continuumApiLazloService"
  - "Voucher Archive Backend"
architecture_ref: "dynamic-continuumLsVoucherArchive-csr-refund"
---

# CSR Refund Voucher Flow

## Summary

This flow allows a Customer Service Representative (CSR) agent to submit a refund for a legacy LivingSocial voucher. The CSR navigates to the CSR voucher detail page, reviews the voucher, and submits a refund POST request. CSRF protection is enforced via `csurf`. The interaction tier validates the session and CSRF token, then forwards the refund operation to the Voucher Archive Backend (and/or Groupon v2 API), and returns a confirmation page to the CSR agent.

## Trigger

- **Type**: user-action
- **Source**: CSR agent submits the refund form on `/ls_voucher_archive/csrs/:voucherId`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CSR Agent Browser | Initiates refund submission | — |
| LS Voucher Archive Interaction Tier | Request handler, CSRF validator, refund dispatcher | `continuumLsVoucherArchiveItier` |
| Voucher Archive Backend | Executes the refund operation on the voucher record | not modelled separately |
| Groupon v2 API (Lazlo) | Provides user and order context for CSR view | `continuumApiLazloService` |

## Steps

1. **Load CSR voucher detail page**: CSR agent sends GET `/ls_voucher_archive/csrs/:voucherId`; itier validates session via `itier-user-auth`, fetches voucher data from Voucher Archive Backend and user context from Lazlo, renders the CSR detail page with a CSRF token injected into the refund form.
   - From: CSR Browser
   - To: `continuumLsVoucherArchiveItier`
   - Protocol: HTTP GET

2. **Submit refund form**: CSR agent completes the refund form and submits; browser sends POST `/ls_voucher_archive/csrs/:voucherId/refund` with the CSRF token in the request.
   - From: CSR Browser
   - To: `continuumLsVoucherArchiveItier`
   - Protocol: HTTP POST

3. **Validate session and CSRF token**: `itier-user-auth` validates the session; `csurf` middleware validates the CSRF token. Request rejected with 403 if either fails.
   - From: `continuumLsVoucherArchiveItier`
   - To: (in-process middleware)
   - Protocol: in-process

4. **Forward refund request to Voucher Archive Backend**: Itier calls the Voucher Archive Backend to execute the refund operation on the voucher, passing the voucher ID and refund reason.
   - From: `continuumLsVoucherArchiveItier`
   - To: Voucher Archive Backend
   - Protocol: REST (keldor)

5. **Render confirmation page**: On success, itier renders a refund confirmation page and returns it to the CSR agent's browser.
   - From: `continuumLsVoucherArchiveItier`
   - To: CSR Browser
   - Protocol: HTTP 200

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing or invalid CSRF token | `csurf` middleware returns HTTP 403 | CSR sees 403 Forbidden; must reload page and retry |
| CSR session expired | `itier-user-auth` redirects to login | CSR redirected to Groupon login before refund can proceed |
| Voucher Archive Backend returns error | Express error handler returns 500 or error page | CSR sees error message; no refund applied |
| Voucher already refunded | Backend returns conflict response | CSR sees "already refunded" message |
| Backend unreachable | keldor timeout; error handler returns 500 | CSR sees generic error; must retry |

## Sequence Diagram

```
CSRBrowser -> LsVoucherArchiveItier: GET /ls_voucher_archive/csrs/:voucherId
LsVoucherArchiveItier -> VoucherArchiveBackend: GET /vouchers/:voucherId
VoucherArchiveBackend --> LsVoucherArchiveItier: Voucher record (JSON)
LsVoucherArchiveItier -> LazloAPI: GET /v2/users/me
LazloAPI --> LsVoucherArchiveItier: CSR user context (JSON)
LsVoucherArchiveItier --> CSRBrowser: CSR detail page with refund form (CSRF token embedded)
CSRBrowser -> LsVoucherArchiveItier: POST /ls_voucher_archive/csrs/:voucherId/refund (CSRF token, refund_reason)
LsVoucherArchiveItier -> LsVoucherArchiveItier: Validate session (itier-user-auth)
LsVoucherArchiveItier -> LsVoucherArchiveItier: Validate CSRF token (csurf)
LsVoucherArchiveItier -> VoucherArchiveBackend: POST /vouchers/:voucherId/refund
VoucherArchiveBackend --> LsVoucherArchiveItier: Refund confirmed (JSON)
LsVoucherArchiveItier --> CSRBrowser: HTTP 200 — Refund confirmation page
```

## Related

- Architecture dynamic view: `dynamic-continuumLsVoucherArchive-csr-refund`
- Related flows: [Consumer Voucher View](consumer-voucher-view.md)
