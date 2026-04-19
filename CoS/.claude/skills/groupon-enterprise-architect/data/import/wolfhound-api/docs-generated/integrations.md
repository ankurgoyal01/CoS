---
service: "wolfhound-api"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 6
---

# Integrations

## Overview

Wolfhound API integrates with six internal Continuum platform services and one external SaaS platform. All integrations use HTTP/HTTPS via Retrofit clients managed by the `externalGatewayClients` component. Internal services provide data enrichment for page payloads, mobile content, taxonomy hierarchies, experiment evaluation, and audience targeting. The single external integration (Salesforce Marketing Cloud) handles email subscription form submission.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce Marketing Cloud | HTTPS | Submits email subscription forms from SEO page forms | no | `salesforceMarketingCloud` |

### Salesforce Marketing Cloud Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: Retrofit HTTP client via `externalGatewayClients` component
- **Auth**: > No evidence found in architecture inventory
- **Purpose**: Receives email subscription form submissions triggered from SEO page integrations
- **Failure mode**: > No evidence found in architecture inventory. Consult MEI team for degraded-mode behavior.
- **Circuit breaker**: > No evidence found in architecture inventory

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Relevance API | HTTP | Queries cards and facets for mobile and deal components | `continuumRelevanceApi` |
| Deals Cluster Service | HTTP | Fetches cluster navigation and top-cluster content | `continuumDealsClusterService` |
| LPAPI Service | HTTP | Resolves LPAPI page references and list queries; checked during publish | `continuumLpapiService` |
| Consumer Authority Service | HTTP | Fetches audience membership and targeting attributes | `continuumConsumerAuthorityService` |
| Taxonomy Service | HTTP | Fetches category hierarchy and taxonomy metadata for bootstrap and enrichment | `continuumTaxonomyService` |
| Expy Service | HTTP | Evaluates and manages experiments (Expy/Optimizely integration) | `continuumExpyService` |

### Relevance API Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Retrofit client via `externalGatewayClients`
- **Auth**: > No evidence found
- **Purpose**: Provides cards and facets data used to assemble mobile page payloads
- **Failure mode**: Mobile page payload assembly may be incomplete
- **Circuit breaker**: > No evidence found

### Deals Cluster Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Retrofit client via `externalGatewayClients`
- **Auth**: > No evidence found
- **Purpose**: Supplies cluster navigation and top-cluster content for SEO page assembly
- **Failure mode**: Cluster content section of pages may be empty or stale
- **Circuit breaker**: > No evidence found

### LPAPI Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Retrofit client via `externalGatewayClients`
- **Auth**: > No evidence found
- **Purpose**: Resolves page references and list queries; dependency checked during page publish flow
- **Failure mode**: Publish flow may fail or warn if LPAPI references cannot be resolved
- **Circuit breaker**: > No evidence found

### Consumer Authority Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Retrofit client via `externalGatewayClients`
- **Auth**: > No evidence found
- **Purpose**: Provides audience membership and targeting attributes for personalization on SEO pages
- **Failure mode**: Personalization attributes unavailable; pages may render with default content
- **Circuit breaker**: > No evidence found

### Taxonomy Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Retrofit client via `externalGatewayClients`
- **Auth**: > No evidence found
- **Purpose**: Provides the category hierarchy and taxonomy metadata consumed during taxonomy bootstrap and page enrichment flows
- **Failure mode**: Taxonomy bootstrap may fail; taxonomy-dependent page enrichment degraded
- **Circuit breaker**: > No evidence found

### Expy Service Detail

- **Protocol**: HTTP
- **Base URL / SDK**: Retrofit client via `externalGatewayClients`
- **Auth**: > No evidence found
- **Purpose**: Evaluates active experiments against page context; manages experiment assignment during page publish
- **Failure mode**: Experiment variants not applied; pages served with default content
- **Circuit breaker**: > No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

All outbound HTTP dependencies are managed through the `externalGatewayClients` component (Retrofit + Apache HttpClient). Specific retry policies, timeouts, and circuit breaker configurations are not declared in the architecture inventory. Consult the wolfhound-api source repository configuration files and the MEI team for operational thresholds.
