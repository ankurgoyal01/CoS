---
service: "itier-ls-voucher-archive"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for LivingSocial Voucher Archive Interaction Tier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Consumer Voucher View](consumer-voucher-view.md) | synchronous | HTTP GET from browser | Consumer requests a legacy LivingSocial voucher detail page |
| [CSR Refund Voucher](csr-refund-voucher.md) | synchronous | HTTP POST from CSR agent browser | CSR agent submits a refund request for a voucher |
| Merchant Search Export | synchronous | HTTP GET from merchant browser | Merchant exports voucher search results as CSV |
| Print Voucher PDF | synchronous | HTTP GET from browser | Consumer requests a printable PDF rendering of their voucher |
| Page Load with Localization | synchronous | HTTP GET from browser | Any page request that requires geo-based locale resolution via Bhuvan |

> Flows without links are documented above but flow detail files are pending generation.

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The consumer voucher view flow is documented as a Structurizr dynamic view: `consumer-voucher-details-flow`. This view captures the runtime interaction between `continuumLsVoucherArchiveItier`, `continuumLsVoucherArchiveMemcache`, `continuumApiLazloService`, `continuumUniversalMerchantApi`, and `continuumBhuvanService`.
