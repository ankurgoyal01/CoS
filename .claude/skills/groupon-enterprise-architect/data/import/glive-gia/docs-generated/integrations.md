---
service: "glive-gia"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 4
---

# Integrations

## Overview

GIA integrates with three external live-event ticketing providers (Ticketmaster, Provenue, AXS) and Salesforce for contract/deal data, plus four internal Continuum platform services (Deal Management API, Inventory Service, Accounting Service, Custom Fields Service). Authentication for admin users is handled by OGWall. All integrations use REST/HTTP via the Typhoeus HTTP client. Both the web app (`continuumGliveGiaWebApp`) and background worker (`continuumGliveGiaWorker`) initiate outbound calls depending on whether the integration is triggered synchronously (admin action) or asynchronously (scheduled job).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Ticketmaster API | REST | Import event listings and inventory data from Ticketmaster | yes | `continuumGliveGiaWebApp`, `continuumGliveGiaWorker` |
| Provenue API | REST | Import event listings and inventory data from Provenue | yes | `continuumGliveGiaWebApp`, `continuumGliveGiaWorker` |
| AXS API | REST | Import event listings and inventory data from AXS | yes | `continuumGliveGiaWebApp`, `continuumGliveGiaWorker` |
| Salesforce | REST | Import deal contracts and sync deal metadata | yes | `continuumGliveGiaWebApp`, `continuumGliveGiaWorker` |

### Ticketmaster API Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Configured per-deal via `ticketmaster_settings`; accessed via `gliveGia_remoteClients` / `workerRemoteClients_GliGia`
- **Auth**: API key per deal configuration (stored as reference in `ticketmaster_settings`)
- **Purpose**: Retrieve event listings and availability to populate GIA deal events; used in the Ticketmaster Event Import flow
- **Failure mode**: Scheduled import job fails; events are not updated; manual re-run required
- **Circuit breaker**: No evidence found

### Provenue API Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Configured per-deal via `provenue_settings`; accessed via remote clients
- **Auth**: Per-deal credentials in `provenue_settings`
- **Purpose**: Import Provenue event data for deals using the Provenue ticketing platform
- **Failure mode**: Import job fails; stale or missing event data in GIA
- **Circuit breaker**: No evidence found

### AXS API Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Configured per-deal via `axs_settings`; accessed via remote clients
- **Auth**: Per-deal credentials in `axs_settings`
- **Purpose**: Import AXS event data for deals on the AXS ticketing platform
- **Failure mode**: Import job fails; stale or missing event data in GIA
- **Circuit breaker**: No evidence found

### Salesforce Detail

- **Protocol**: REST / HTTP
- **Base URL / SDK**: Standard Salesforce REST API; accessed via `salesForce` reference
- **Auth**: OAuth or API token (credential managed externally)
- **Purpose**: Import deal contracts from Salesforce to pre-populate GIA deals; sync deal status updates back to Salesforce records
- **Failure mode**: Deal sync job fails; deal data in GIA may lag behind Salesforce; manual re-sync or alert required
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Management API | REST | Retrieve deal and product catalog data; sync inventory metadata | `continuumDealManagementApi` |
| Inventory Service | REST | Manage inventory products and events; sync inventory updates | `inventoryService_unknown_1a2b` (stub) |
| Accounting Service | REST | Create vendor records, payment entries, and invoices in the accounting ledger | `continuumAccountingService` |
| Custom Fields Service | REST | Retrieve custom field definitions for deals | `continuumCustomFieldsService` |
| GTX (Tax Service) | REST | Fetch third-party inventory; tax-related data | `gtxService_unknown_2b3c` (stub) |
| OGWall | Session/OAuth | Authenticate admin users accessing the GIA web UI | `ogwall_unknown_7f81` (stub) |

### Deal Management API Detail

- **Protocol**: REST
- **Purpose**: GIA reads deal and product data to populate its local models; the worker syncs inventory metadata back after GIA modifications
- **Failure mode**: Deal creation wizard may be blocked if deal data cannot be fetched; worker sync retries via Resque retry

### Accounting Service Detail

- **Protocol**: REST
- **Purpose**: When invoices are created or payments recorded in GIA, corresponding entries are pushed to the Accounting Service to maintain the financial ledger
- **Failure mode**: Invoice creation succeeds in GIA MySQL but accounting record creation fails; worker retries; manual reconciliation may be required

### Inventory Service Detail

- **Protocol**: REST
- **Purpose**: GIA pushes inventory product and event updates to the Inventory Service so that consumer-facing systems reflect current availability
- **Failure mode**: Inventory sync job fails; consumer-facing inventory may be stale until retry succeeds

## Consumed By

> Upstream consumers are tracked in the central architecture model. GIA is an internal admin application; no external services are known to call GIA's API directly.

## Dependency Health

- HTTP calls use Typhoeus as the HTTP client; connection and read timeouts are expected to be configured per-client
- No explicit circuit breaker pattern is evidenced in the inventory
- Failed Resque jobs (including those triggered by integration failures) are retried by Resque's built-in retry mechanism and can be inspected via the Resque web UI
- Integration health for Salesforce and ticketing provider APIs depends on external availability; GIA does not expose a consolidated dependency health endpoint
