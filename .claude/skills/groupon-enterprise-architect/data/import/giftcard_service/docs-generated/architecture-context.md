---
service: "giftcard_service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumGiftcardService"
  containers: [continuumGiftcardService]
---

# Architecture Context

## System Context

The Giftcard Service sits within the Continuum payments platform, acting as the redemption gateway between customer-facing checkout flows and payment processors. Callers (typically the PWA checkout or internal tools) POST gift card credentials to this service; the service validates the card against either First Data (external physical cards) or the Voucher Inventory Service (internal VIS codes), then credits the redeemed amount as Groupon Bucks to the user's account via the Orders Service. It depends on four external systems: the Orders Service for bucks allocation and unit status, the Voucher Inventory Service for VIS code validation, the Deal Catalog Service for product category eligibility checks, and First Data/Datawire for external card processing.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Giftcard Service | `continuumGiftcardService` | Service | Ruby on Rails | 3.2.22 | Rails service for gift card redemption, inventory lookups, and legacy credit codes |

## Components by Container

### Giftcard Service (`continuumGiftcardService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Giftcard API Controllers | Exposes redemption and legacy credit code endpoints; handles request validation and response rendering | Rails Controllers |
| Redemption Service | Coordinates gift card redemption and reversal logic; routes to First Data, VIS, or Groupon credit code authorization | Ruby Services |
| First Data Integration | Builds and sends XML requests to First Data/Datawire; handles service discovery for endpoint URLs | Ruby Services |
| Deal Catalog Client | Fetches deal catalog metadata from Deal Catalog Service to validate primary deal service category | HTTP Client |
| Voucher Inventory Client | Verifies and redeems internal VIS (vs-) codes via the Voucher Inventory Service API | HTTP Client |
| Orders Client | Fetches order inventory unit status and creates Groupon Bucks allocations via the Orders bucks API | HTTP Client |
| Service Discovery Job | Background job (SuckerPunch, runs hourly) that discovers and pings available First Data endpoint URLs | ActiveJob |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGiftcardService` | `continuumOrdersService` | Creates Groupon Bucks allocations; queries inventory unit status | HTTP |
| `continuumGiftcardService` | `continuumVoucherInventoryService` | Verifies and redeems internal VIS gift card codes | HTTP |
| `continuumGiftcardService` | `continuumDealCatalogService` | Validates product category eligibility for VIS codes | HTTP |
| `continuumGiftcardService` | `firstDataDatawire` | Redeems external gift cards; discovers service URLs | HTTPS (XML) |

## Architecture Diagram References

- System context: `contexts-giftcardService`
- Container: `containers-giftcardService`
- Component: `components-giftcardService`
