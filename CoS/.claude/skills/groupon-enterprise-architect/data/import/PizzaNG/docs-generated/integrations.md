---
service: "PizzaNG"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 3
internal_count: 6
---

# Integrations

## Overview

PizzaNG integrates with nine downstream systems to assemble agent support context. Six are internal Continuum services; three are external (CAAP, Doorman, and Merchant Success APIs are not fully modeled in the central federated architecture). All integrations use synchronous HTTPS/JSON. The `gofer` HTTP client handles most downstream calls; Cyclops uses `axios`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| CAAP | REST/HTTP | Customer, order, refund, and snippet operations | yes | `unknownExternalCaap_4b37e1` (stub) |
| Doorman | REST/HTTP | Resolves authentication token flow entrypoints | yes | `unknownExternalDoorman_61b4f8` (stub) |
| Merchant Success APIs | REST/HTTP | Merchant workflow data for CS agents | no | `unknownExternalMerchantSuccess_18bf42` (stub) |

### CAAP Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Gofer client via `continuumPizzaNgCaapIntegration`
- **Auth**: Resolved via Doorman integration
- **Purpose**: Primary source for customer profile, order history, refund eligibility, and support snippet data on the `/api/bff/pizza` response
- **Failure mode**: `/api/bff/pizza` cannot return complete customer/order context; agent sees degraded data
- **Circuit breaker**: No evidence found in codebase

### Doorman Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Node.js module via `continuumPizzaNgDoormanIntegration`
- **Auth**: N/A — Doorman is the auth resolver
- **Purpose**: Provides downstream auth entrypoints required before calling CAAP and other authenticated services
- **Failure mode**: Authenticated downstream calls fail; agent workflow blocked
- **Circuit breaker**: No evidence found in codebase

### Merchant Success APIs Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: No evidence found in codebase for SDK name
- **Auth**: Resolved via Doorman integration
- **Purpose**: Supports merchant-related CS workflows accessed through PizzaNG
- **Failure mode**: Merchant workflows unavailable; core customer/order flows unaffected
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Cyclops | REST/HTTP | Voucher and customer operations | `cyclops` |
| CFS Service (NLP) | REST/HTTP | ECE scoring for deal content via NLP analysis | `continuumCfsService` |
| Deal Catalog | REST/HTTP | Deal category metadata and deal lookups | `continuumDealCatalogService` |
| API Proxy / Lazlo | REST/HTTP | Deal content data via Lazlo-backed endpoints | `apiProxy` |
| Zendesk | REST/HTTP | Ticket queries, field metadata, and ticket creation via ingestion | `zendesk` |
| legacyWeb | HTTPS | Opens Groupon domains for links referenced in agent UI | `legacyWeb` |
| Ingestion Service | REST/HTTP | Creates Zendesk tickets through ingestion pipeline (stub — not in federated model) | `unknownExternalIngestionService_2c9c4a` (stub) |

### Cyclops Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Axios client via `continuumPizzaNgCyclopsIntegration`
- **Auth**: OGWall/session
- **Purpose**: Handles Cyclops-specific voucher and customer operations for support workflows
- **Failure mode**: Cyclops-dependent workflows unavailable; other flows may remain operational
- **Circuit breaker**: No evidence found in codebase

### CFS Service Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Gofer client via `continuumPizzaNgCfsIntegration`
- **Auth**: Internal service auth
- **Purpose**: Runs NLP/ECE content scoring on deal text payloads to support the deal-content-enrichment flow
- **Failure mode**: Content scoring unavailable; deal content displayed without ECE analysis
- **Circuit breaker**: No evidence found in codebase

### Deal Catalog Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Gofer client via `continuumPizzaNgDealCatalogIntegration`
- **Auth**: Internal service auth
- **Purpose**: Provides deal category and lookup data for the deal-content-enrichment flow
- **Failure mode**: Deal catalog data unavailable; agent cannot see deal metadata
- **Circuit breaker**: No evidence found in codebase

### API Proxy / Lazlo Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Gofer client via `continuumPizzaNgLazloIntegration`
- **Auth**: Internal service auth
- **Purpose**: Retrieves deal content details through API proxy endpoints backed by Lazlo
- **Failure mode**: Deal content details unavailable
- **Circuit breaker**: No evidence found in codebase

### Zendesk Detail

- **Protocol**: HTTPS/JSON
- **Base URL / SDK**: Gofer client via `continuumPizzaNgZendeskIntegration` and `continuumPizzaNgIngestionIntegration`
- **Auth**: Zendesk API credentials
- **Purpose**: Reads ticket history/search data for agent context; ticket field metadata is cached for 2 hours
- **Failure mode**: Ticket context and `ticketFields` cache cannot be populated; agent sees incomplete data
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. PizzaNG UI and Chrome extension are accessed directly by CS agents in the Zendesk workflow.

## Dependency Health

> No evidence found in codebase. Health check and retry patterns for downstream dependencies are not explicitly documented in the repository. I-Tier and Gofer framework defaults apply.
