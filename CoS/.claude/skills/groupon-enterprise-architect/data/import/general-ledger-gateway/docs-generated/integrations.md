---
service: "general-ledger-gateway"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

GLG has two primary service integrations: NetSuite ERP (external SaaS) and Accounting Service (internal Groupon service). Both are called synchronously over HTTPS with Resilience4j retry logic applied to handle transient failures. NetSuite is accessed via OAuth 1.0-signed RESTlet calls; Accounting Service is accessed via plain HTTPS with a service client ID.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| NetSuite ERP | HTTPS (OAuth 1.0 RESTlet) | Create/update vendor bills; execute saved searches for applied invoices and payments | yes | `netSuiteErpExternalContainerUnknown_1a2c` |

### NetSuite ERP Detail

- **Protocol**: HTTPS (port 443), OAuth 1.0 via ScribeJava 8.1.0
- **Base URL**: Per-instance RESTlet URLs — e.g., `4004600.restlets.api.netsuite.com/app/site/hosting/restlet.nl`
- **Auth**: OAuth 1.0 with per-instance consumer key/secret and access token/secret (injected at runtime from environment secrets)
- **Instances configured**:
  - `NORTH_AMERICA_LOCAL_NETSUITE` — realm `4004600`, script IDs 139 (search), 140 (find-and-insert), saved search 134 (applied invoices)
  - `GOODS_NETSUITE` — realm `3579761`, script IDs 233 (search), 234 (find-and-insert)
  - `NETSUITE` (international) — realm `1202613`, script IDs 371 (search), 370 (find-and-insert)
- **Purpose**: Create/update vendor bills for merchant payments; run saved searches to download applied invoice and payment records
- **Failure mode**: Resilience4j retry policy applied; failed invoice sends surface as errors to calling service
- **Circuit breaker**: Retry only (no circuit breaker configured in codebase)
- **Caching**: NetSuite currency lookups are cached in Redis to reduce round trips

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Accounting Service | HTTPS | Invoice create, show, and apply operations during applied invoice import job | `accountingServiceExternalContainerUnknown_6d4b` |

### Accounting Service Detail

- **Protocol**: HTTPS (port 80 internally)
- **Base URL (production)**: `accounting-service.production.service`
- **Base URL (staging)**: `accounting-service.staging.service`
- **Auth**: Service client ID (`ACCOUNTING_SERVICE_CLIENT_ID` env var)
- **Operations called**:
  - `createInvoice` — creates an invoice record in Accounting Service
  - `showInvoice` — retrieves an invoice by ledger and ledger ID
  - `applyInvoice` — applies a credit to an invoice (used by import applied invoices job)
- **Failure mode**: Resilience4j retry policy applied; failures in apply-invoice during job processing are logged
- **Circuit breaker**: Retry only

## Consumed By

> Upstream consumers are tracked in the central architecture model. Accounting Service is the known primary consumer, calling GLG's invoice and job REST endpoints.

## Dependency Health

Both NetSuite and Accounting Service clients use `RetryFactory.newInstance()` (Resilience4j) to wrap all outbound HTTP calls. Currency results from NetSuite are cached in Redis to reduce load on the external system. The PostgreSQL connection pools include health-check validation queries (`SELECT 1`) run on connection acquisition with a 3-second timeout.
