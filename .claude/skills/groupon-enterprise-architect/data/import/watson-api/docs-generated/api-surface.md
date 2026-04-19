---
service: "watson-api"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-mtls]
---

# API Surface

## Overview

Watson API exposes REST/JSON endpoints organized by functional component. Each Kubernetes deployment component activates a specific set of API resources determined by the `DEPLOY_COMPONENT` environment variable. All components listen on HTTP port 8080 with an admin port at 8081. The service uses JAX-RS (Jersey via Dropwizard) and produces `application/json` responses. Swagger annotations are present on all resource classes.

## Endpoints

### Deal Key-Value (`dealkv` component)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/dds/buckets/{bucket}/deals/{dealId}` | Retrieve deal KV data for a named bucket as a map | Internal mTLS |
| POST | `/v1/dds/buckets/{bucket}/deals/{dealId}` | Write/update deal KV bucket value; publishes event to Kafka | Internal mTLS |
| GET | `/v1/dds/buckets/{bucket}/data/deals/{dealId}` | Retrieve raw content for a deal KV bucket | Internal mTLS |

**Valid deal buckets** (from `KvBucket` enum): `post-purchase`, `purchase-model`, `related-deals`, `relevance-card-feature`, `relevance-card-intrinsic`, `relevance-item-algo`, `relevance-item-feature`, `relevance-item-intrinsic`, `relevance-item-intrinsic-dark-canary`, `relevance-search-qu-prod`, `view-model`, `cards-goods-customer-also-bought`, `cards-goods-customer-also-bought-2`, `cards-goods-customer-also-viewed`, `cards-goods-sponsored`, `cards-goods-customer-also-x-v1`, `cards-goods-customer-also-x-v2`, `cards-goods-trendy-v1`, `cards-goods-trendy-v2`

### User Key-Value (`userkv` component)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/cds/buckets/{bucket}/consumers/{consumerId}` | Retrieve user KV data for a named bucket as a map | Internal mTLS |
| POST | `/v1/cds/buckets/{bucket}/consumers/{consumerId}` | Write/update user KV bucket value; publishes event to Kafka | Internal mTLS |

**Valid user buckets** (from `KvBucket` enum): `adult-deal-filter`, `d2d-personalization`, `deal-click-boost`, `delta-user-purchase-data`, `realtime-user-purchase-data`, `relevance-user-intrinsic`, `relevance-user-locations`, `relevance-user-deal-preferences`, `user-activity-freshness`, `user-email-activity-freshness`, `user-deal-attributes`, `user-disliked-deal-attributes`, `user-ml-model-data`, `user-purchase-data`, `user-search-history`, `user-getaways-email`, `user-interests`, `deal-freshness`

### Email Freshness (`emailfreshness` component)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/realtime/freshness/email/{consumer-id}` | Retrieve email send and open freshness score for a consumer UUID | Internal mTLS |

### Recently Viewed Deals (`rvd` component)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/impressions/recently_viewed/profile/{userUUID}` | List recently viewed deals for an authenticated user (21-day lookback) | Internal mTLS |
| GET | `/v1/impressions/recently_viewed/anonymous/{bcookie}` | List recently viewed deals for an anonymous user by bcookie | Internal mTLS |

### Janus Aggregation (`janusaggregation` component)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/v1/getEvents` | Query deal event counters (dealView, dealPurchase) with time windowing and aggregation | Internal mTLS |
| GET | `/v1/you_viewed/{consumer_id}` | Retrieve recently viewed activity list for a consumer | Internal mTLS |
| GET | `/v1/bcookie_mapping/consumers/{consumer_id}` | Retrieve all bcookies associated with a consumer UUID | Internal mTLS |

## Request/Response Patterns

### Common headers
- `Content-Type: application/json` (responses)
- `Content-Type: text/plain` (KV POST request bodies)

### Error format
Errors are returned as JSON with a `code` and `message` field:
```json
{"code": "500", "message": "There was an error processing your request. Error - <detail>"}
```
For 400/404 errors, a plain-text or minimal JSON body is returned depending on endpoint.

### Pagination
- `/v1/impressions/recently_viewed/*` accepts an optional `limit` query parameter (default: 30)
- `/v1/you_viewed/{consumer_id}` accepts an optional `limit` query parameter (default: 10)
- No cursor-based pagination; results are bounded by limit and time window

### Query Parameters — `/v1/getEvents`
| Parameter | Required | Values | Description |
|-----------|----------|--------|-------------|
| `dealId` | yes | string | Deal identifier |
| `startDateTime` | yes | `NOW` or `NOW-{n}{unit}` | Start of time window (e.g. `NOW-2h`) |
| `endDateTime` | yes | `NOW` or `NOW-{n}{unit}` | End of time window |
| `eventType` | yes | `dealView`, `dealPurchase`, `dealView\|dealPurchase` | Event type filter |
| `timeAggregation` | yes | `5MIN`, `HOURLY`, `DAILY` | Aggregation granularity |

**Time window limits**: `5MIN` aggregation — max 30-minute window; `HOURLY` — max 1-day window; `DAILY` — max 7-day window.

### Query Parameters — KV POST endpoints
| Parameter | Required | Description |
|-----------|----------|-------------|
| `expirySecs` | no | Custom TTL in seconds; falls back to per-bucket defaults if omitted |

## Rate Limits

> No rate limiting configured. Capacity is managed via Kubernetes HPA (min/max replicas per component).

## Versioning

All endpoints use URL path versioning with a `v1` prefix. No other API versions are currently exposed.

## OpenAPI / Schema References

Swagger annotations are present on all resource classes (`@Api`, `@ApiOperation`). A Swagger UI is available via the JTier Dropwizard admin interface at port 8081. No standalone OpenAPI spec file is committed to the repository.
