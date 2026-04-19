---
service: "reporting-service"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 2
internal_count: 14
---

# Integrations

## Overview

The reporting service has a broad integration footprint: it calls 14 internal Continuum APIs to enrich report data and two external platforms (AWS S3 and Teradata). All outbound internal API calls are made by the `reportingService_externalApiClients` component using HTTP/JSON. MBus integration is handled separately by `reportingService_mbusConsumers` and `mbusProducer`. Most internal dependencies are stub-only in the federated model, meaning their relationships are declared but the target containers live in other service repos.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| AWS S3 | SDK | Store and retrieve generated report artifacts (Excel, CSV, PDF) | yes | `reportingS3Bucket` |
| Teradata | JDBC/query | Query campaign reporting data for weekly summary reports | no | `teradataWarehouse` |

### AWS S3 Detail

- **Protocol**: AWS SDK (S3/STS)
- **Base URL / SDK**: AWS SDK for Java; bucket name configured via environment
- **Auth**: IAM role / STS assumed role
- **Purpose**: Persists rendered report files so they can be retrieved on demand via `GET /reports/v1/reports/{id}` without re-generating
- **Failure mode**: Report generation succeeds but file is unavailable for download; retry or re-generation required
- **Circuit breaker**: No evidence found

### Teradata Detail

- **Protocol**: JDBC/query (stub only in federated model)
- **Base URL / SDK**: Teradata JDBC; connection details configured via environment
- **Auth**: Database credentials
- **Purpose**: Queries campaign reporting data for the weekly campaign summary scheduled report
- **Failure mode**: Weekly campaign summary report generation fails; no fallback evidence found
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Catalog | REST | Fetches deal metadata for report enrichment | `dcApi` |
| FED | REST | Fetches financial event data for deal settlement reports | `fedApi` |
| FED VAT | REST | Fetches VAT-specific financial data for VAT invoicing | `fedVatApi` |
| M3 Merchant | REST | Fetches merchant metadata for merchant-facing reports | `m3Api` |
| M3 Places | REST | Fetches merchant place data for location-based reporting | `m3PlacesApi` |
| GIA | REST | Fetches purchase and offer data | `giaApi` |
| Booking Tool | REST | Fetches booking data for booking-based deal reports | `bookingToolApi` |
| VIS | REST | Fetches voucher inventory data for redemption reporting | `visApi` |
| Orders | REST | Fetches order data for performance report calculations | `ordersApi` |
| UGC | REST | Fetches merchant reviews for inclusion in performance reports | `ugcApi` |
| Taxonomy | REST | Fetches category taxonomy data for report categorization | `taxonomyApi` |
| Refunds (RR) | REST | Fetches refunds and returns data for net redemption calculations | `rrApi` |
| Geoplaces | REST | Resolves geographic place data for location reporting | `geoplacesApi` |
| NOTS | REST | Sends notifications (e.g., report ready alerts) | `notsApi` |
| Localization | REST | Fetches localization strings for report rendering | `localizeApi` |
| Continuum Pricing | REST | Fetches pricing data for deal value calculations | `continuumPricingApi` |
| MBus | message-bus | Publishes BulkVoucherRedemption; consumes PaymentNotification, ugc.reviews, VatInvoicing, BulkVoucherRedemption | `mbus` |

> Note: All internal dependencies except `continuumPricingApi` are stub-only in the federated architecture model. Their relationships are declared but the target containers are defined in other service repositories.

## Consumed By

> Upstream consumers are tracked in the central architecture model. The API is consumed by merchant portal frontends and internal Continuum tooling.

## Dependency Health

- The `reportingService_externalApiClients` component makes HTTP/JSON calls to all internal Continuum APIs. No circuit breaker or retry configuration evidence is present in the architecture model.
- The only active (non-stub) internal relationship in the federated model is `continuumReportingApiService -> continuumPricingApi`.
- S3 and MBus are infrastructure dependencies — degradation of either directly affects report delivery and event processing.
- Operational health check and retry strategies to be confirmed with the MX Platform Team.
