---
service: "giftcard_service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Giftcard Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [External Gift Card Redemption](external-gift-card-redemption.md) | synchronous | POST /api/v1/redemptions with 16-digit card number and 8-digit PIN | Validates and redeems a physical gift card via First Data/Datawire and allocates Groupon Bucks |
| [Internal VIS Gift Card Redemption](internal-vis-gift-card-redemption.md) | synchronous | POST /api/v1/redemptions with vs- prefixed 22-char code | Validates an internal Groupon gift card code via VIS, checks Orders unit status, validates deal category, and allocates Groupon Bucks |
| [Legacy Credit Code Redemption](legacy-credit-code-redemption.md) | synchronous | POST /api/v1/redemptions with code and no PIN | Authorizes a legacy Groupon credit code without PIN and allocates Groupon Bucks |
| [Legacy Credit Code Creation](legacy-credit-code-creation.md) | synchronous | POST /api/v1/legacy_credit_codes | Creates a batch of unique alphanumeric credit codes for a promotional campaign |
| [First Data Service Discovery](first-data-service-discovery.md) | scheduled | Hourly SuckerPunch background job | Discovers available First Data Datawire endpoint URLs and selects the fastest via latency pinging |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

All redemption flows span multiple services:
- External gift card redemption: `continuumGiftcardService` → `firstDataDatawire` → `continuumOrdersService`
- Internal VIS redemption: `continuumGiftcardService` → `continuumVoucherInventoryService` → `continuumOrdersService` → `continuumDealCatalogService`
- Legacy credit code redemption: `continuumGiftcardService` → `continuumOrdersService`

These flows are referenced in the central architecture model under `continuumGiftcardService` dynamic views.
