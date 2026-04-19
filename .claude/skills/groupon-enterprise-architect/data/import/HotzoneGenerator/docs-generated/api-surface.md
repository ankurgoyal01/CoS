---
service: "HotzoneGenerator"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

HotzoneGenerator is a batch job with no inbound HTTP surface. It does not expose any endpoints. All interactions are outbound: the job calls upstream services to read data and calls the Proximity Notifications API to write generated hotzones and campaigns.

The endpoints listed below are the **outbound calls** HotzoneGenerator makes to its dependencies during each run. They are documented here to capture the integration contract surface rather than any serving surface this service exposes.

## Outbound API Calls Made by This Service

### Proximity Notifications API

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `hotzone/campaign?client_id={clientId}` | Retrieves active hotzone campaign configurations |
| `POST` | `hotzone?client_id={clientId}` | Submits batch of generated hotzones for upsert |
| `POST` | `hotzone/delete-expired?client_id={clientId}` | Triggers deletion of expired hotzones |
| `POST` | `hotzone/campaign?client_id={clientId}` | Creates a new auto-generated category campaign |
| `POST` | `hotzone/campaign/delete-auto?client_id={clientId}` | Deletes all auto-generated campaigns |
| `POST` | `proximity/delete-send-log?client_id={clientId}` | Deletes stale send logs |
| `POST` | `/v1/proximity/location/hotzone/{consumerId}/send-email?client_id={clientId}` | Triggers weekly email for a specific consumer |

### Marketing Deal Service (MDS)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `deals.json?country={country}&size=5000&channel={channel}&page={n}&...` | Fetches paginated deal list by category/country |
| `GET` | `trends/hot.json?country={country}&size=1000&channel={channel}&customer_taxonomy_guid={guid}&...` | Fetches hot trending deals for auto-campaign generation |
| `GET` | `{country}/divisions?client={clientId}` | Fetches list of divisions for a given country |

### Taxonomy Service v2

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `categories/{categoryGuid}` | Resolves English display name for a taxonomy category GUID |

### Deal Catalog Service

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `deal_catalog/v2/deals/{dealUuid}` | Fetches inventory product IDs for a deal |

### Internal API Proxy (GAPI / deal-clusters)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/v2/deals/{dealUuid}?show=options(redemptionLocations)&client_id={clientId}` | Fetches open hours for US deal redemption locations |
| `GET` | `/api/mobile/{countryCode}/deals/{dealUuid}?show=options(redemptionLocations)&client_id={clientId}` | Fetches open hours for non-US deal redemption locations |
| `GET` | `wh/v2/clusters/navigation?country={country}&division={division}&type=DIVISION_L4_CR_MIN10&client_id={clientId}` | Fetches trending categories from deal clusters |

## Request/Response Patterns

### Common headers
- `Authorization: groupon` header passed as username parameter in HTTP basic auth on outbound MDS calls (value `"groupon"`).
- `client_id` passed as query parameter (not header) to Proximity and deal-cluster APIs.

### Error format
> No evidence found in codebase for a standardised inbound error response format; this service has no inbound API.

### Pagination
MDS deal queries paginate by appending `&page={n}` (0-indexed). The job fetches up to 5 pages of 5000 results each, stopping early when a page returns fewer than 5000 results.

## Rate Limits

> No rate limiting configured. This is a batch job with no inbound surface.

## Versioning

> Not applicable. This service exposes no versioned API.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema present in the repository.
