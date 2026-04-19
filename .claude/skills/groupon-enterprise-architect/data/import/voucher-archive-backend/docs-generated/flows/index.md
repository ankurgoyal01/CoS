---
service: "voucher-archive-backend"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for Voucher Archive Backend.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Consumer Retrieve Vouchers](consumer-retrieve-vouchers.md) | synchronous | API call from consumer client | Consumer authenticates and fetches their LivingSocial vouchers |
| [Merchant Redeem Voucher](merchant-redeem-voucher.md) | synchronous | API call from merchant portal | Merchant authenticates, validates voucher ownership, and marks voucher as redeemed |
| [CSR Process Refund](csr-process-refund.md) | synchronous | API call from CSR tooling | CSR authenticates and processes a refund on a voucher |
| [GDPR Right to Be Forgotten](gdpr-right-to-be-forgotten.md) | event-driven | Message bus event from GDPR orchestrator | Receives account erasure event, erases PII via Retcon, publishes completion event |
| [Merchant Bulk Redeem](merchant-bulk-redeem.md) | synchronous | API call from merchant portal | Merchant submits batch redemption of multiple vouchers in a single request |
| [Deal Retrieval](deal-retrieval.md) | synchronous | API call from consumer or merchant client | Retrieves deal record with options, images, and redemption instructions |
| [Authentication Flow](authentication-flow.md) | synchronous | Inbound API request requiring auth | Validates caller token via the appropriate upstream auth service |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The [GDPR Right to Be Forgotten](gdpr-right-to-be-forgotten.md) flow spans `continuumVoucherArchiveBackendApp`, `messageBus`, and `continuumRetconService`.
- The [Authentication Flow](authentication-flow.md) spans `continuumVoucherArchiveBackendApp`, `continuumUsersService`, `continuumCsTokenService`, and the MX Merchant API.
