---
service: "mds-feed-job"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 5
internal_count: 8
---

# Integrations

## Overview

MDS Feed Job has a broad integration footprint: 8 internal Continuum services and 5 external platform dependencies. All integrations are outbound only — the job calls dependencies; no system calls into it. Internal Continuum service calls use HTTPS/JSON via Retrofit2 HTTP clients. External dependencies use their respective SDKs or JDBC drivers. Failsafe 3.3.2 provides retry and circuit-breaker resilience for external API calls.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Cloud Storage | GCS SDK | Read MDS snapshots; write feed staging output | yes | `continuumMdsFeedJob` |
| BigQuery | BigQuery API | Read gift-booster enrichment signals | no | `bigQuery` |
| Google Translate | REST/SDK | Translate feed content for multi-language feeds | no | — |
| Google Merchant Center | REST API | Publish finalized feeds to Google Merchant Center | yes | — |
| Google Ads | REST API | Publish SEM and ads feeds | yes | — |

### Google Cloud Storage Detail

- **Protocol**: Google Cloud Storage SDK (BOM 26.70.0)
- **Auth**: Service account / Workload Identity
- **Purpose**: Primary distributed storage for MDS snapshot input and feed output staging
- **Failure mode**: Job cannot read input data or write output; batch fails with storage error
- **Circuit breaker**: Failsafe retry wraps SDK calls

### BigQuery Detail

- **Protocol**: BigQuery API (Google Cloud SDK)
- **Auth**: Service account / Workload Identity
- **Purpose**: Read gift-booster enrichment signals used in transformer pipeline enrichment step
- **Failure mode**: Enrichment step produces output without gift-booster signals; may degrade feed quality
- **Circuit breaker**: Failsafe retry

### Google Translate Detail

- **Protocol**: Google Translate REST/SDK
- **Auth**: API key or service account
- **Purpose**: Translate deal content (titles, descriptions) for multi-language feed variants
- **Failure mode**: Translation step fails or is skipped; non-translated content may be published
- **Circuit breaker**: Failsafe retry

### Google Merchant Center Detail

- **Protocol**: Google Merchant Center API (REST)
- **Auth**: OAuth2 service account
- **Purpose**: Upload finalized product feed files to Google Merchant Center for Shopping ads
- **Failure mode**: Feed upload fails; batch status updated as failed; no feed refresh for that run
- **Circuit breaker**: Failsafe retry

### Google Ads Detail

- **Protocol**: Google Ads REST API
- **Auth**: OAuth2 service account
- **Purpose**: Publish SEM and ads feed data to Google Ads campaigns
- **Failure mode**: Ads feed publish fails; batch marked failed
- **Circuit breaker**: Failsafe retry

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Marketing Deal Service (Feed API) | HTTPS/JSON | Load feed definitions, update batch lifecycle status, trigger upload workflows | `continuumMarketingDealService` |
| Taxonomy Service | HTTPS/JSON | Read taxonomy/category mappings for feed field transformations | `continuumTaxonomyService` |
| Deal Catalog Service | HTTPS/JSON | Fetch localized deal catalog content | `continuumDealCatalogService` |
| M3 Merchant Service | HTTPS/JSON | Resolve merchant and place metadata for appointment and feed transforms | `continuumM3MerchantService` |
| Pricing Service | HTTPS/JSON | Request dynamic and localized prices per deal | `continuumPricingService` |
| Travel Inventory Service | HTTPS/JSON | Read dated travel inventory details | `continuumTravelInventoryService` |
| Voucher Inventory Service | HTTPS/JSON | Read voucher inventory details | `continuumVoucherInventoryService` |
| Third-Party Inventory Service (TPIS) | HTTPS/JSON | Read third-party availability data for TTD feeds | `continuumThirdPartyInventoryService` |

### EDW (Enterprise Data Warehouse) Detail

- **Protocol**: JDBC/Teradata (driver 17.20)
- **Auth**: Database credentials (secrets-managed)
- **Purpose**: Read SEM source datasets for SEM feed enrichment and filtering
- **Failure mode**: SEM feed generation step fails; batch marked failed for affected feed types
- **Circuit breaker**: Failsafe retry on JDBC calls

### Salesforce Detail

- **Protocol**: HTTPS/REST
- **Auth**: OAuth2 / API credentials (secrets-managed)
- **Purpose**: Query VAT metadata for Salesforce VAT transformer step
- **Failure mode**: VAT transformer step fails or is skipped; VAT metadata not applied to affected feeds
- **Circuit breaker**: Failsafe retry

## Consumed By

> Upstream consumers are tracked in the central architecture model. This job is triggered by external schedulers or Livy job submissions; it does not expose an API surface that other services call directly.

## Dependency Health

- Retrofit2 with OkHttp is used for all HTTPS/JSON internal service calls via the `externalApiAdapters` component.
- Failsafe 3.3.2 provides configurable retry policies and circuit breakers for resilience against transient failures in external API dependencies.
- JDBC connections to Teradata (EDW) and PostgreSQL use standard driver-level connection pooling and timeout configuration.
- BigQuery and GCS calls use Google Cloud SDK retry built-ins, augmented by Failsafe.
