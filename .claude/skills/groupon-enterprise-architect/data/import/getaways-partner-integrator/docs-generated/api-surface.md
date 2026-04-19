---
service: "getaways-partner-integrator"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest, soap]
auth_mechanisms: [ws-security]
---

# API Surface

## Overview

Getaways Partner Integrator exposes two categories of API surface: a REST API for internal consumers managing hotel/room/rate plan mappings and querying reservation data, and three SOAP endpoints for inbound channel manager communication. SOAP endpoints are secured with WS-Security (Apache WSS4J). The REST API is served by Dropwizard/Jersey; the SOAP endpoints are served by Apache CXF integrated via `dropwizard-jaxws`.

## Endpoints

### REST API — Mapping and Reservation

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/getaways/v2/channel_manager_integrator/mapping` | Retrieve hotel/room/rate plan mapping records | Internal / JTier |
| PUT | `/getaways/v2/channel_manager_integrator/mapping` | Create or update hotel/room/rate plan mapping records | Internal / JTier |
| GET | `/reservation/data` | Retrieve reservation records | Internal / JTier |
| POST | `/reservation/data` | Submit or update reservation data | Internal / JTier |

### SOAP API — Channel Manager Inbound

| Operation | Endpoint Path | Purpose | Auth |
|-----------|--------------|---------|------|
| ARI updates (APS) | `/GetawaysPartnerARI` | Receives ARI (Availability, Rates, Inventory) notifications from APS | WS-Security |
| Reservations and ARI (SiteMinder) | `/SiteConnectService` | Receives ARI updates and reservation notifications from SiteMinder | WS-Security |
| ARI updates (TravelgateX) | `/TravelGateXARI` | Receives ARI notifications from TravelgateX | WS-Security |

## Request/Response Patterns

### Common headers

- REST endpoints use standard HTTP headers; JTier service mesh may inject trace headers.
- SOAP endpoints require a WS-Security header block conforming to the WSS4J 2.1.6 implementation. Partners authenticate using credentials validated by `cxf-rt-ws-security`.

### Error format

- REST: Standard Dropwizard/Jersey JSON error responses with HTTP status codes.
- SOAP: Standard SOAP Fault responses for protocol and business errors.

### Pagination

> No evidence found of pagination on REST endpoints. Mapping and reservation queries are expected to be scoped by identifiers supplied in query parameters.

## Rate Limits

> No rate limiting configured. Throughput is governed by Kubernetes resource limits and JTier container constraints.

## Versioning

The REST API uses URL path versioning. The current version is `v2`, as seen in `/getaways/v2/channel_manager_integrator/mapping`. SOAP endpoint contracts are versioned implicitly by the WSDL published to each channel manager partner.

## OpenAPI / Schema References

> No evidence found of an OpenAPI spec or WSDL committed to the architecture repository. SOAP WSDLs are served dynamically by Apache CXF at runtime. Contact the Travel team for WSDL access.
