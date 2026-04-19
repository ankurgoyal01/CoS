---
service: "umapi"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumUniversalMerchantApi]
---

# Architecture Context

## System Context

UMAPI sits within the **Continuum Platform** (`continuumSystem`), Groupon's core commerce engine. It serves as the centralized merchant data and operations API, positioned between edge routing (API Proxy) and the downstream messaging infrastructure (Message Bus). It is one of the most heavily depended-upon services in the Continuum ecosystem, consumed by over a dozen internal services spanning merchant-facing UIs, backend integration tiers, reporting, and the next-generation Encore platform.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Universal Merchant (UMAPI) | `continuumUniversalMerchantApi` | Backend Service | Java / Vert.x | -- | Centralized API for merchant lifecycle operations: onboarding, updates, search, reporting, and aggregation for Merchant Center and platform consumers. |

## Components by Container

### Universal Merchant (UMAPI) (`continuumUniversalMerchantApi`)

> No components defined yet in the architecture DSL. Component decomposition is pending.

## Key Relationships

### Inbound (services that call UMAPI)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `apiProxy` | `continuumUniversalMerchantApi` | Routes merchant operations | JSON/HTTPS |
| `continuumMerchantCenterWeb` | `continuumUniversalMerchantApi` | Calls merchant auth, account, deals, vouchers, reporting, and inbox APIs | HTTPS/JSON |
| `continuumMobileFlutterMerchantApp` | `continuumUniversalMerchantApi` | Calls merchant APIs for dashboard, deals, vouchers, and account workflows | -- |
| `continuumMarketingDealService` | `continuumUniversalMerchantApi` | Syncs merchant profile and contact data | HTTP |
| `continuumAiReportingService` | `continuumUniversalMerchantApi` | Authenticate or lookup users | HTTPS/JSON |
| `continuumBookabilityDashboardWeb` | `continuumUniversalMerchantApi` | Uses internal OAuth redirect and token endpoints for login | -- |
| `continuumMailmanService` | `continuumUniversalMerchantApi` | Fetches merchant and location data | HTTP/JSON |
| `continuumMinosService` | `continuumUniversalMerchantApi` | Reads merchant details | -- |
| `continuumMerchantPageService` | `continuumUniversalMerchantApi` | Reads merchant and place data | HTTPS/JSON |
| `continuumMerchantBookingTool` | `continuumUniversalMerchantApi` | Reads and writes booking-service data via merchant API clients and proxy endpoints | HTTPS/JSON |
| `continuumSponsoredCampaignItier` | `continuumUniversalMerchantApi` | Proxies campaign, billing, and performance operations | HTTP |
| `continuumLsVoucherArchiveItier` | `continuumUniversalMerchantApi` | Uses merchant API request module | HTTPS/JSON |
| `continuumMerchantOnboardingItier` | `continuumUniversalMerchantApi` | Reads and updates 3PIP merchant mapping, auth, and onboarding state | HTTPS/JSON |
| `continuumM3MerchantService` | `continuumUniversalMerchantApi` | Synchronizes merchant/place data via M3SyncClient | -- |
| `encoreUmapiWrapper` | `continuumUniversalMerchantApi` | Wraps Universal Merchant API for Encore platform | -- |

### Outbound (services UMAPI calls)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUniversalMerchantApi` | `messageBus` | Publishes and consumes events | Async |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: (not yet defined)
