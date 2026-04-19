---
service: "mdi-dashboard-v2"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 7
---

# Integrations

## Overview

mdi-dashboard-v2 depends on 7 internal Continuum platform services and 2 external systems. All outbound HTTP calls to Continuum services are routed through the API Proxy. External integrations (Salesforce, JIRA) use direct HTTP clients (gofer, keldor, jira library). The dashboard is a pure consumer — it does not expose a public API for other services to call.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST | Retrieve merchant CRM data for deal and merchant insights views | no | `salesForce` |
| JIRA | REST | Create JIRA tickets for deal-related issues raised from the dashboard | no | — |

### Salesforce Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Accessed via gofer or keldor HTTP client; base URL configured via environment variable
- **Auth**: OAuth2 or API token (configured via environment variable; exact mechanism not confirmed in inventory)
- **Purpose**: Provides merchant CRM context (account data, relationship history) surfaced in merchant insight views
- **Failure mode**: Merchant CRM data unavailable; dashboard degrades gracefully and shows deal/feed data without Salesforce-sourced fields
- **Circuit breaker**: No evidence found

### JIRA Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: jira npm library v0.9.2
- **Auth**: Basic auth or API token (configured via environment variables)
- **Purpose**: Allows users to create JIRA tickets for deal issues directly from the dashboard without switching tools
- **Failure mode**: Ticket creation fails; user receives error; dashboard core functionality unaffected
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Marketing Deal Service | REST | Primary source of deal data for browser and insights views | `continuumMarketingDealService` |
| Relevance API | REST | Provides relevance scores for deals shown in search results | `continuumRelevanceApi` |
| Deal Catalog Service | REST | Supplies deal option details for `/options/:id` lookups | `continuumDealCatalogService` |
| Voucher Inventory Service | REST | Provides voucher inventory data displayed alongside deal information | `continuumVoucherInventoryService` |
| Taxonomy Service | REST | Supplies taxonomy category, city, and location data for search and filtering | `continuumTaxonomyService` |
| Deals Cluster API | REST | Returns deal clustering and grouping analytics for the `/clusters` view | — |
| MDS Feed Service | REST | Executes feed generation jobs triggered from the feed builder | — |
| API Proxy | REST | Routes outbound calls to internal Continuum services | `apiProxy` |

### Marketing Deal Service Detail

- **Protocol**: REST / HTTP via keldor or gofer
- **Purpose**: Primary deal data source; powers the deal browser and merchant insights features
- **Failure mode**: Deal browser and merchant insights views unavailable; feed and key management features unaffected

### Relevance API Detail

- **Protocol**: REST / HTTP via gofer
- **Purpose**: Augments deal search results with relevance scores surfaced in the browser view
- **Failure mode**: Relevance scores unavailable; deal browser may show results without ranking signal

### Deal Catalog Service Detail

- **Protocol**: REST / HTTP
- **Purpose**: Supplies deal option metadata for the `/options/:id` endpoint
- **Failure mode**: Options lookup fails; user receives error on that specific page

### Voucher Inventory Service Detail

- **Protocol**: REST / HTTP
- **Purpose**: Provides voucher inventory counts displayed in deal detail views
- **Failure mode**: Inventory data unavailable; deal views degrade without inventory fields

### Taxonomy Service Detail

- **Protocol**: REST / HTTP
- **Purpose**: Powers the `/search/*` taxonomy, city, and location search features
- **Failure mode**: Search autocomplete and taxonomy filtering unavailable

### Deals Cluster API Detail

- **Protocol**: REST / HTTP
- **Purpose**: Provides deal clustering data for the `/clusters` analytics view
- **Failure mode**: Cluster analytics view unavailable

### MDS Feed Service Detail

- **Protocol**: REST / HTTP
- **Purpose**: Executes feed generation on demand when triggered from the feed builder
- **Failure mode**: Feed generation job submission fails; user receives error; feed configuration in PostgreSQL is unaffected

## Consumed By

> Upstream consumers are tracked in the central architecture model. mdi-dashboard-v2 is an internal tool accessed directly by human users via browser. No service-to-service consumers are known.

## Dependency Health

> No evidence found of circuit breaker, retry, or explicit health check patterns configured at the dashboard layer. Dependency health is inferred from HTTP response codes. Operational procedures to be defined by service owner.
