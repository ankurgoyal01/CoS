---
service: "gpapi"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 3
internal_count: 13
---

# Integrations

## Overview

gpapi maintains 3 external dependencies and 13 internal Continuum service dependencies, making it one of the most highly connected services in the Goods Platform. All integrations use synchronous REST/HTTPS request-response patterns. External dependencies include Google reCAPTCHA Enterprise for session 2FA, NetSuite for accounting event webhooks, and Amazon S3 for vendor document file storage. Internal dependencies span the full Goods ecosystem plus shared Continuum platform services.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google reCAPTCHA Enterprise | HTTPS SDK | Session 2FA verification during vendor login | yes | `continuumGoogleRecaptcha` |
| NetSuite | HTTPS webhook (inbound) | Delivers accounting events to gpapi | yes | — |
| Amazon S3 | HTTPS SDK | Stores and retrieves vendor external files | no | — |

### Google reCAPTCHA Enterprise Detail

- **Protocol**: HTTPS SDK (`google-cloud-recaptcha_enterprise` gem v1.5.1)
- **Base URL / SDK**: Google Cloud reCAPTCHA Enterprise API
- **Auth**: Google Cloud service account credentials (environment-injected)
- **Purpose**: Verifies reCAPTCHA tokens submitted during vendor portal login to prevent automated credential attacks; part of 2FA session flow
- **Failure mode**: Login blocked if reCAPTCHA verification fails or service is unreachable; vendor cannot establish a session
- **Circuit breaker**: No evidence found in codebase

### NetSuite Detail

- **Protocol**: HTTPS webhook (inbound POST to `/webhooks/netsuite`)
- **Base URL / SDK**: NetSuite pushes events; gpapi does not call out to NetSuite
- **Auth**: HMAC or token-based webhook authentication
- **Purpose**: Receives accounting lifecycle events (invoice updates, payment confirmations) from NetSuite for downstream processing
- **Failure mode**: Missed events if gpapi is unavailable; NetSuite retry behavior governs re-delivery
- **Circuit breaker**: Not applicable (inbound only)

### Amazon S3 Detail

- **Protocol**: HTTPS SDK (AWS SDK for Ruby)
- **Base URL / SDK**: AWS S3 API
- **Auth**: AWS IAM credentials (environment-injected)
- **Purpose**: Stores vendor-uploaded external files (contracts, compliance documents) via the `/api/v2/external_files` endpoint
- **Failure mode**: File upload/download operations fail with error returned to vendor portal user; no fallback storage
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Goods Stores Service | REST/HTTP | Retrieves and manages legacy goods store data (V0 API surface) | — |
| Goods Inventory Service | REST/HTTP | Manages inventory item instances for vendor items | — |
| Goods Product Catalog | REST/HTTP | Retrieves and updates product catalog entries | — |
| Goods Promotion Manager | REST/HTTP | Creates and manages promotions and co-op agreements | `continuumGoodsPromotionManager` |
| Deal Catalog | REST/HTTP | Retrieves deal instance data for V3 API | — |
| DMAPI | REST/HTTP | Merchant data lookup and management | — |
| Pricing Service | REST/HTTP | Retrieves and updates vendor item pricing | — |
| Taxonomy Service | REST/HTTP | Category and taxonomy lookups for product classification | — |
| Users Service | REST/HTTP | User account management and vendor-user linking | — |
| Vendor Compliance Service | REST/HTTP | Orchestrates vendor compliance onboarding checks | `continuumVendorComplianceService` |
| Commerce Interface | REST/HTTP | Commerce workflow integration for deal and contract lifecycle | — |
| Geo Details Service | REST/HTTP | Geographic details lookup for vendor and product location data | — |
| Accounting Service | REST/HTTP | Financial data integration for bank info and accounting records | — |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Goods Vendor Portal UI | REST/HTTP | Primary consumer; all vendor portal screens call gpapi |
| NetSuite | HTTPS webhook | Delivers inbound accounting events |

> Upstream consumers beyond the Vendor Portal UI are tracked in the central architecture model.

## Dependency Health

All downstream HTTP calls use `rest-client` (v2.1.0) and `typhoeus` (v1.4.0) for single and parallel requests respectively. `schema_driven_client` (v0.5.0) provides schema validation on internal API responses. Elastic APM (`elastic-apm` v4.7.3) traces distributed calls for latency observability. No explicit circuit breaker or retry library is identified in the inventory; failure handling is assumed to propagate HTTP error responses back to the Vendor Portal UI.
