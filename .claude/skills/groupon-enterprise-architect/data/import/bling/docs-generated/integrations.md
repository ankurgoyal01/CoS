---
service: "bling"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

bling has 2 direct internal service dependencies (Accounting Service and File Sharing Service) plus the Hybrid Boundary OAuth proxy for authentication. Three external systems (Salesforce, NetSuite, Merchant Center) are surfaced in bling's UI but accessed indirectly through the Accounting Service — bling has no direct integration with them. All integrations use synchronous REST/HTTPS patterns.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | Indirect (via Accounting Service) | Read views of Salesforce-originated contract and account data | no | `salesForce` |
| NetSuite | Indirect (via Accounting Service) | Read views of NetSuite accounting records and payment data | no | — |
| Merchant Center | Indirect (via Accounting Service) | Read views of merchant account data | no | `merchantCenter` |

### Salesforce Detail

- **Protocol**: Indirect — bling does not call Salesforce directly; data originates in Salesforce and is surfaced through the Accounting Service
- **Base URL / SDK**: Not applicable for bling
- **Auth**: Not applicable for bling
- **Purpose**: bling displays Salesforce-originated contract and account data as part of contract management views
- **Failure mode**: Data appears stale or missing in bling UI if Accounting Service's Salesforce sync is delayed; bling itself is unaffected
- **Circuit breaker**: Not applicable

### NetSuite Detail

- **Protocol**: Indirect — bling does not call NetSuite directly; payment and invoice data originates in NetSuite and is surfaced through the Accounting Service
- **Base URL / SDK**: Not applicable for bling
- **Auth**: Not applicable for bling
- **Purpose**: bling displays NetSuite-originated payment and accounting records
- **Failure mode**: Data appears stale or missing in bling UI if Accounting Service's NetSuite sync is delayed; bling itself is unaffected
- **Circuit breaker**: Not applicable

### Merchant Center Detail

- **Protocol**: Indirect — bling does not call Merchant Center directly; merchant data is surfaced through the Accounting Service
- **Base URL / SDK**: Not applicable for bling
- **Auth**: Not applicable for bling
- **Purpose**: bling displays merchant account data in payment and invoice context
- **Failure mode**: Merchant data missing in bling UI if Accounting Service's Merchant Center integration is degraded
- **Circuit breaker**: Not applicable

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Accounting Service | REST/HTTP (via Nginx proxy) | Core data backend for all finance operations: invoices, contracts, payments, batches, paysource files, users, search, system errors | `continuumAccountingService` |
| File Sharing Service | REST/HTTP (via Nginx proxy at `/file-sharing-service/files`) | File upload, listing, and download for accounting-related documents | `fileSharingService` |
| Hybrid Boundary | HTTPS OAuth2 | OAuth/Okta authentication and session token issuance for bling users | — |
| Legacy Web | REST/HTTP | Integration with legacy Groupon web systems where applicable | `legacyWeb` |

## Consumed By

> bling is a browser-based internal application. It has no API surface and is not consumed by other services.

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

bling uses `ember-ajax` (v2.3.2) for all HTTP calls; error responses from the Accounting Service and File Sharing Service are surfaced in the UI as error states. The Nginx proxy (`blingNginx`) provides connection-level health; if the Accounting Service is unreachable, the proxy returns 502/503 to the browser. No circuit breaker or retry logic is implemented at the bling application layer — failure handling relies on the Nginx proxy and browser retry behavior.
