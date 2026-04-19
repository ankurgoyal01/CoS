---
service: "goods-vendor-portal"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

The Goods Vendor Portal has two downstream dependencies: GPAPI (the primary backend for all merchant data operations) and the Continuum Accounting Service (for financial data transmission). Both are consumed over HTTPS. There are no SDK, message-bus, or gRPC integrations at the portal layer.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GPAPI (Groupon Goods Platform API) | REST/HTTPS | Primary backend for all catalog, deal, contract, vendor, analytics, and self-service data | yes | `gpapiApi_unk_1d2b` |

### GPAPI Detail

- **Protocol**: REST over HTTPS
- **Base URL**: Proxied via Nginx at `/goods-gateway/*`; actual GPAPI base URL is environment-specific and resolved via Nginx upstream configuration
- **Auth**: Session-based; portal authenticates via `ember-simple-auth` and forwards session credentials through the Nginx proxy
- **Purpose**: Provides all data persistence and business logic for the merchant portal — catalog management, deal lifecycle, contract storage, vendor profiles, pricing, reviews, insights, and file handling
- **Failure mode**: If GPAPI is unavailable, all data-dependent portal routes fail; the SPA displays error states. Read-only views may serve stale ember-data store cache briefly before erroring.
- **Circuit breaker**: No evidence of circuit breaker at the portal layer; resilience is delegated to GPAPI and Nginx configuration

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Continuum Accounting Service | REST/HTTPS | Receives financial data transmitted via GPAPI | `continuumAccountingService` |

### Continuum Accounting Service Detail

- **Protocol**: REST over HTTPS
- **Purpose**: Financial data (payment terms, co-op agreement financials, contract billing) is transmitted to the Continuum Accounting Service. This flow is mediated by GPAPI — the portal does not call the accounting service directly.
- **Architecture Ref**: `continuumAccountingService`
- **Failure mode**: Financial data transmission failures are handled by GPAPI; the portal surfaces errors returned by GPAPI if accounting integration is disrupted.

## Consumed By

> Upstream consumers are tracked in the central architecture model. The portal is accessed directly by goods merchants and Groupon internal operations staff via a web browser; it is not consumed programmatically by other services.

## Dependency Health

- Health of GPAPI is the primary operational concern for the portal. A degraded GPAPI will cause cascading UI failures across all major portal flows.
- No client-side health check endpoints are exposed by the portal itself.
- Nginx upstream health checks (if configured) are the first line of detection for GPAPI availability issues.
- See [Runbook](runbook.md) for dependency health verification steps.
