---
service: "leadminer"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 7
---

# Integrations

## Overview

Leadminer has one external dependency (Salesforce) and seven internal Continuum service dependencies. All integrations are synchronous REST/HTTP calls made via the `m3_client` gem or direct HTTP. The service is a consumer-only integration point — it does not expose an API consumed by other services.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST | External merchant UUID mapping for cross-system identity | no | `salesForce` |

### Salesforce Detail

- **Protocol**: REST/HTTP
- **Base URL / SDK**: Configured via environment/m3_client settings
- **Auth**: Not discoverable from inventory — likely API token or OAuth
- **Purpose**: Maps Leadminer merchant records to Salesforce external UUIDs, enabling cross-system merchant identity linking
- **Failure mode**: Merchant UUID lookup fails; operators may see missing or unresolved external IDs
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Place Read Service | REST/HTTP | Fetches place records, search results, and place details | `continuumPlaceReadService` |
| Place Write Service | REST/HTTP | Persists place edits, merges, and defrank operations | `continuumPlaceWriteService` |
| M3 Merchant Service | REST/HTTP | Reads and writes merchant records | `continuumM3MerchantService` |
| Input History Service | REST/HTTP | Retrieves audit/input history for places and merchants | `continuumInputHistoryService` |
| BoomStick Service | REST/HTTP | Supplementary data lookups for place/merchant enrichment | `continuumBoomStickService` |
| Taxonomy Service | REST/HTTP | Provides business category and service taxonomy reference data | `continuumTaxonomyService` |
| GeoDetails Service | REST/HTTP | Resolves geocode coordinates and address details | `continuumGeoDetailsService` |
| Control Room | REST/HTTP | Authenticates and authorizes internal operator sessions | `continuumControlRoom` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Leadminer is an internal editorial tool; no downstream services are known to consume its API.

## Dependency Health

> No evidence found in codebase of explicit retry, circuit breaker, or health-check patterns for downstream dependencies. The `m3_client` gem likely handles HTTP connection errors with standard Ruby Net::HTTP timeouts. Operational procedures to be defined by service owner.
