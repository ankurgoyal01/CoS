---
service: "contract-data-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 0
internal_count: 2
---

# Integrations

## Overview

Contract Data Service has two internal downstream dependencies, both used exclusively by the backfill subsystem. The service calls Deal Management API (DMAPI) to fetch legacy deal data and to write back updated contract terms. It calls Deal Catalog Service to resolve secondary deals to their primary deal during backfill. All outbound calls use Retrofit HTTP clients configured via `RetrofitConfiguration` in the JTier configuration file.

## External Dependencies

> No evidence found in codebase. No external (non-Groupon) system integrations were identified.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Management API | HTTP (Retrofit) | Fetch legacy deal data (v1 and v2), generate opportunity contract payload, create CoDS contract on DMAPI, update deal in DMAPI during backfill | `continuumDealManagementApi` |
| Deal Catalog Service | HTTP (Retrofit) | Resolve secondary deal to primary deal by inventory product ID during backfill | `continuumDealCatalogService` |

### Deal Management API (`continuumDealManagementApi`) Detail

- **Protocol**: HTTP REST via Retrofit (`jtier-retrofit` 4.2.2)
- **Base URL / SDK**: Configured via `dealManagementClient` key in `ContractDataServiceConfiguration`; `RetrofitConfiguration` from `jtier-retrofit`
- **Auth**: Managed by JTier/Retrofit configuration (credentials not in source)
- **Purpose**: Used exclusively by `cds_backfillDealResource` / `BackfillProcessor` to:
  - Fetch deal data at `GET /v1/deals/{id}` (v1 deal with expand params)
  - Fetch deal data at `GET /v2/deals/{id}` (v2 deal with expand params)
  - Retrieve opportunity contract payload at `GET v1/opportunity_contract_payload/deals/{id}`
  - Create CoDS contract at `POST v2/contract_data_service/contract`
  - Update deal at `PUT /v2/deals/{id}` with supplier contract terms
- **Failure mode**: Backfill reports an error in the response map (`errorMap`) and logs the failure; no circuit breaker pattern identified in source
- **Circuit breaker**: No evidence found in codebase

### Deal Catalog Service (`continuumDealCatalogService`) Detail

- **Protocol**: HTTP REST via Retrofit (`jtier-retrofit` 4.2.2)
- **Base URL / SDK**: Configured via `dealCatalogClient` key in `ContractDataServiceConfiguration`; `RetrofitConfiguration` from `jtier-retrofit`
- **Auth**: Managed by JTier/Retrofit configuration (credentials not in source)
- **Purpose**: Used exclusively by `cds_backfillDealResource` / `DealCatalogSecondaryDealFinder` during backfill to resolve secondary deals: `GET /deal_catalog/v1/deals/lookupId?inventoryProductId={uuid}`
- **Failure mode**: If lookup returns null, an error is recorded in the backfill `errorMap` (`SECONDARY_DEAL_ERROR`); backfill aborts for that deal
- **Circuit breaker**: No evidence found in codebase

## Consumed By

> Upstream consumers are tracked in the central architecture model. The service is internal to Groupon's Continuum platform and is called by services that need authoritative merchant contract data.

## Dependency Health

Both outbound HTTP clients are configured through `RetrofitConfiguration` (JTier). JTier's OkHttp integration provides connection pooling and timeout management. No explicit circuit breaker, retry policy, or health check endpoint for downstream dependencies was found in the service source. Backfill failures surface as structured error messages in the API response rather than HTTP error codes.
