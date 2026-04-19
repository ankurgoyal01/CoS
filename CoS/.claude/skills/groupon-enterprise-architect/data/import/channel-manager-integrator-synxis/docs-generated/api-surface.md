---
service: "channel-manager-integrator-synxis"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest, soap]
auth_mechanisms: [internal-network]
---

# API Surface

## Overview

CMI SynXis exposes two protocol surfaces. A REST API (via Dropwizard/Jersey) handles internal mapping management and reservation data retrieval. A SOAP API (via Apache CXF) implements the `CMService` interface, which SynXis CRS calls to push ARI updates into the Continuum platform. Both surfaces run within the same Dropwizard process.

## Endpoints

### REST — Mapping and Reservation API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/mapping` | Retrieve current hotel/room mapping configuration | Internal network |
| `PUT` | `/mapping` | Create or update hotel/room mapping configuration | Internal network |
| `GET` | `/reservations` | Retrieve reservation data and status records | Internal network |

### SOAP — CMService (`/soap/CMService`)

| Operation | Path | Purpose | Auth |
|-----------|------|---------|------|
| `pushAvailability` | `/soap/CMService` | Receive availability update from SynXis CRS | SOAP over HTTPS |
| `pushInventory` | `/soap/CMService` | Receive inventory update from SynXis CRS | SOAP over HTTPS |
| `pushRate` | `/soap/CMService` | Receive rate/pricing update from SynXis CRS | SOAP over HTTPS |
| `ping` | `/soap/CMService` | Health/connectivity check from SynXis CRS | SOAP over HTTPS |

## Request/Response Patterns

### Common headers

- REST endpoints follow standard Dropwizard/Jersey HTTP conventions.
- SOAP operations follow WS-I Basic Profile; messages are SOAP 1.1 envelopes over HTTPS.

### Error format

- REST: Standard Dropwizard error responses (JSON body with `code` and `message` fields).
- SOAP: SOAP fault responses per the CMService WSDL contract.

### Pagination

> No evidence found for pagination on the `/reservations` endpoint. Assumed single-page response for operational query scope.

## Rate Limits

> No rate limiting configured. Both REST and SOAP surfaces are internal-network or partner-facing and rely on infrastructure-level controls.

## Versioning

> No evidence found of explicit API versioning strategy. The SOAP service contract is defined by the CMService WSDL; REST endpoints have no version prefix.

## OpenAPI / Schema References

> No OpenAPI spec or WSDL file path is available in this architecture model. The CMService WSDL is the authoritative SOAP contract; refer to the service repository for the WSDL artifact.
