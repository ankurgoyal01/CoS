---
service: "mdi-dashboard-v3"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [session, itier-user-auth]
---

# API Surface

## Overview

MDI Dashboard V3 exposes two categories of endpoints: **page routes** that serve server-side-rendered HTML pages (one per feature module), and **JSON API routes** (all under `/api/v1/`) that are called by the browser-side Preact modules to fetch data from downstream services. All JSON endpoints consume and produce `application/json`. CSRF protection is disabled on JSON endpoints via `x-middleware: { csurf: false }`. Authentication is handled by the `itier-user-auth` middleware applied at the server level — all routes require an authenticated Groupon internal session.

The service is internally accessible via:
- Production: `https://mdi-dashboard-v3.production.service`
- Staging: `https://mdi-dashboard-v3.staging.service`
- Production VIP: `https://mdi-dashboard-v3.prod.us-central1.gcp.groupondev.com`

OpenAPI schema: `doc/openapi.yml` (version hash `57836e36e53d477a6460a3df454a669c`)

---

## Endpoints

### Page Routes (HTML)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/` | Renders the default browser/deal search page | Internal session |
| GET | `/browser` | Renders the deal browser page | Internal session |
| GET | `/showDeal` | Renders the deal detail page (accepts `?id=`) | Internal session |
| GET | `/clusters` | Renders the cluster list page | Internal session |
| GET | `/showCluster` | Renders the cluster detail page (accepts `?uuid=`) | Internal session |
| GET | `/rapi` | Renders the RAPI query builder page | Internal session |
| GET | `/feeds` | Renders the feeds management page | Internal session |
| GET | `/merchant` | Renders the merchant insights page | Internal session |
| GET | `/search` | Renders the deal search page | Internal session |
| GET | `/contact` | Renders the contact/help page | Internal session |

### Deal Browser API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/trends/{trendsSubpath}.json` | Fetches deal trend data (proxies to MDS trends endpoint) | Internal session |
| GET | `/api/v1/deals.json` | Fetches filtered deal list from MDS | Internal session |
| GET | `/api/v1/search` | Searches for a deal by search term | Internal session |
| GET | `/api/v1/divisions` | Retrieves division list for a given locale | Internal session |

**Key query parameters for deal browser:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `sort` | string | Sort criteria |
| `country` | string | Country filter |
| `channel` | string | Channel filter |
| `division_id` | string | Division ID filter |
| `customer_taxonomy_guid` | array | CFT taxonomy GUIDs |
| `pds_id` | array | PDS category IDs |
| `subchannels` | array | Sub-channel filters |
| `merchandising_tags` | array | Merchandising tag filters |
| `merchant_id` | string | Merchant ID filter |
| `min_margin` / `max_margin` | string | Margin range |
| `min_price` / `max_price` | string | Price range |
| `min_purchases` / `max_purchases` | string | Purchase count range |
| `min_activations` / `max_activations` | string | Activation count range |
| `locale` | string | Locale (e.g., `en_US`) |
| `brand` | string | Brand filter |
| `lat` / `lng` / `rad` | number | Geographic centre and radius |
| `page` / `size` / `order` | number | Pagination and sort order |

### Show Deal API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/showDeal/dealDetails` | Fetches and enriches full deal data for the show-deal page | Internal session |
| GET | `/api/v1/showDeal/refreshDeal` | Triggers a deal refresh in MDS (PUT to upstream) | Internal session |
| GET | `/api/v1/showDeal/updateBooster` | Updates deal booster/ad status in Ad Inventory Service | Internal session |
| GET | `/api/v1/showDeal/dealPerformance` | Fetches multi-metric sales performance data for a deal | Internal session |
| GET | `/api/v1/showDeal/dealAttributes` | Fetches deal impression attribute metrics | Internal session |

**Key parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | Deal ID or UUID (for `dealDetails`) |
| `dealId` | string | Deal ID (for `refreshDeal`) |
| `dealUUID` | string | Deal UUID (for `updateBooster`, `dealPerformance`, `dealAttributes`) |
| `span` | string | Time period, e.g. `7d`, `24h` (for performance/attributes) |
| `attribute` | string | Attribute name for impressions |

### Clusters API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/clusterTypes` | Retrieves available cluster rule types | Internal session |
| GET | `/api/v1/clusters` | Retrieves paginated and filtered cluster list | Internal session |
| GET | `/api/v1/clusterHistory` | Retrieves cluster history by cluster UUID | Internal session |
| GET | `/api/v1/dealsCluster` | Retrieves deal cluster data for merchant insights | Internal session |
| GET | `/api/v1/dealsCluster/getClusterById` | Retrieves a specific cluster by UUID | Internal session |
| GET | `/api/v1/dealsCluster/getClustersInfoByDeal` | Retrieves all clusters a given deal belongs to | Internal session |
| GET | `/api/v1/dealsCluster/getClusterHistory` | Retrieves cluster history entries by cluster UUID | Internal session |
| GET | `/api/v1/dealsCluster/getDeals` | Retrieves deal details for a list of UUIDs | Internal session |

### RAPI (Relevance API) API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/rapi` | Proxies a relevance API query and returns card results | Internal session |
| GET | `/api/v1/locations` | Returns location autocomplete suggestions | Internal session |

**Key RAPI parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `locale` | string | Target locale (e.g., `en_US`) — determines SNC vs EMEA routing |
| `ell` | string | Locale latitude/longitude |
| `page_type` | string | Page type for RAPI |
| `platform` | string | Platform identifier |
| `consumer_id` | string | Consumer identifier |
| `visitor_id` | string | Visitor identifier |
| `debug_mode` | string | Enables debug output |
| `limit` / `offset` | number | Pagination |
| `finch_treatments` | string | A/B test treatment identifiers |

### Feeds API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/feeds` | Lists feeds, optionally filtered by `clientId` or `feedUuid` | Internal session |
| GET | `/api/v1/feeds/batches` | Lists batches for a feed UUID | Internal session |
| GET | `/api/v1/feeds/batches/upload` | Lists upload batches for a feed batch UUID | Internal session |
| GET | `/api/v1/feeds/dispatcher` | Retrieves dispatcher status for a feed batch UUID | Internal session |

### Merchant Insights API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/api/v1/topCities` | Returns top cities ranked by cluster views for a country/category | Internal session |
| GET | `/api/v1/dealsCluster` | Returns deal cluster data filtered by country, city, and category | Internal session |

---

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` (JSON API endpoints)
- `x-brand: <brand>` — added by the client when a brand filter is active (via `api-client.mjs` option mapper)

### Error format

All JSON API endpoints return a consistent error envelope on failure:

```json
{
  "errors": [
    {
      "details": "Error message string",
      "meta": { "stack": "optional stack trace" }
    }
  ]
}
```

HTTP status `299` is used for handled API errors (returned via `itier-tracing` error path in `object-graph.mjs`).

### Pagination

Deal browser endpoints support `page` (0-indexed) and `size` parameters. Cluster endpoints use `offset` and `size`. The `dealsCluster` merchant insights endpoint fetches up to 10,000 records in a single call.

---

## Rate Limits

No rate limiting is configured within the service itself. Rate limiting is enforced upstream at the hybrid boundary / API gateway layer.

---

## Versioning

All JSON API routes use URL path versioning: `/api/v1/`. No other API version exists in the current codebase.

---

## OpenAPI / Schema References

- OpenAPI schema: `doc/openapi.yml` (in-repo)
- Swagger UI dev tool: `@grpn/swagger-ui` (devDependency)
- Per-module open-api definitions:
  - `modules/api/open-api.js`
  - `modules/api/show_deal/open-api.js`
  - `modules/api/deals_cluster/open-api.js`
  - `modules/browser/open-api.js`
  - `modules/clusters/open-api.js`
  - `modules/feeds/open-api.js`
  - `modules/rapi/open-api.js`
  - `modules/show_deal/open-api.js`
  - `modules/show_cluster/open-api.js`
  - `modules/merchant_insights/open-api.js`
  - `modules/search/open-api.js`
  - `modules/contact/open-api.js`
