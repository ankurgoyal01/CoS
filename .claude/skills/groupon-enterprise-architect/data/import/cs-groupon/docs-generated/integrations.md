---
service: "cs-groupon"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 12
---

# Integrations

## Overview

cyclops is a high-integration service with 12 internal Continuum platform dependencies and 1 external third-party dependency (Zendesk). Internal dependencies are called synchronously via REST through the `apiProxy` (Web App and API containers) or directly (Background Jobs). Async messaging is handled through the `messageBus`. Outbound HTTP calls use Typhoeus (v0.6.3) for parallel execution.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Zendesk | rest (zendesk_api gem) | CS ticket creation, update, and retrieval | yes | `zendesk_api` |

### Zendesk Detail

- **Protocol**: REST via `zendesk_api` Ruby gem
- **Base URL / SDK**: Configured via environment variable; managed through `zendesk_api` gem
- **Auth**: API token (Zendesk API token credential)
- **Purpose**: CS agents create and manage Zendesk tickets from within the cyclops UI; provides the ticketing backbone for escalated customer issues
- **Failure mode**: Ticket creation fails; CS agents must manually create tickets in Zendesk; cyclops continues to function for order/user lookups
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| API Proxy | HTTP (internal) | Routes all internal service API calls | `apiProxy` |
| Message Bus | MBus | Async event consumption and GDPR confirmation publishing | `messageBus` |
| Orders Service | REST | Order and refund lookups for CS context | `continuumOrdersService` |
| Users Service | REST | User profile lookups and account management | `continuumUsersService` |
| Deal Catalog Service | REST | Deal metadata retrieval for CS context | `continuumDealCatalogService` |
| Inventory Service | REST | Inventory status checks | `continuumInventoryService` |
| Pricing Service | REST | Pricing calculations for refund/adjustment flows | `continuumPricingService` |
| Regulatory Consent Log API | REST | CS consent action logging (sync and async) | `continuumRegulatoryConsentLogApi` |
| Email Service | REST | Customer notification dispatch (sync and async) | `continuumEmailService` |
| Voucher Inventory Service | REST | Voucher issue, cancel, and resend operations | `continuumVoucherInventoryService` |
| Goods Inventory Service | REST | Goods inventory operations | `continuumGoodsInventoryService` |
| Third-Party Inventory Service | REST | Third-party inventory operations | `continuumThirdPartyInventoryService` |
| CLO Inventory Service | REST | Card-Linked Offer inventory operations | `continuumCloInventoryService` |
| Logging Stack | Internal | Structured log shipping from all containers | `loggingStack` |
| Metrics Stack | Internal | Metrics publishing via sonoma-metrics (all containers) | `metricsStack` |
| Tracing Stack | Internal | Distributed trace publishing from all containers | `tracingStack` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| CS Agents (browser) | HTTP / session | Use the `continuumCsWebApp` UI for issue resolution |
| Internal CS tooling integrations | REST | Call `/api/v1`–`/api/v3` endpoints via `continuumCsApi` |

> Upstream consumers beyond direct agent browser access are tracked in the central architecture model.

## Dependency Health

- Outbound HTTP calls via Typhoeus support parallel execution to reduce CS page load times when aggregating data from multiple downstream services.
- No evidence of circuit breaker patterns in the inventory; downstream service failures surface as errors to CS agents.
- Resque retry logic provides resilience for async jobs; failures land in the Resque `:failed` queue.
- Redis availability is critical — its failure impacts sessions (agent login), job queuing, and caching simultaneously.
- MySQL availability is critical — its failure prevents all CS data reads and writes.
