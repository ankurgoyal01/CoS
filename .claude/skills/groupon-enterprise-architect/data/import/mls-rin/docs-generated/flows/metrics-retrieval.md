---
service: "mls-rin"
title: "Metrics Retrieval"
generated: "2026-03-03"
type: flow
flow_name: "metrics-retrieval"
flow_type: synchronous
trigger: "HTTP GET to /v1/metrics"
participants:
  - "continuumMlsRinService"
  - "mlsRinMetricsDb"
architecture_ref: "dynamic-continuumMlsRinService"
---

# Metrics Retrieval

## Summary

The Metrics Retrieval flow serves requests for aggregated marketing performance metrics for a set of deals within a specified time range. The caller specifies one or more deal UUIDs, one or more metric types (email/web/mobile impressions, clicks, shares, referrals), an aggregation period, and a date range. MLS RIN queries the local metrics PostgreSQL database and returns the time-bucketed metric data. This is a simple, self-contained database read with no downstream service calls.

## Trigger

- **Type**: api-call
- **Source**: Merchant Center portal or mx-merchant-analytics service requesting deal performance data
- **Frequency**: On-demand (per page load or analytics query)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MLS RIN Service | Orchestrator — receives request, queries metrics DB, returns response | `continuumMlsRinService` |
| MLS RIN Metrics DB | Primary data source for aggregated marketing metrics | `mlsRinMetricsDb` |

## Steps

1. **Receive metrics request**: Accepts GET on `/v1/metrics` with required query parameters: `deal_ids` (multi-value UUID array), `type` (multi-value enum: EMAIL_CLICKS, EMAIL_IMPRESSIONS, WEB_CLICKS, WEB_DEAL_SHARES, WEB_IMPRESSIONS, WEB_MERCHANT_WEBSITE_REFERRALS, MOBILE_CLICKS, MOBILE_DEAL_SHARES, MOBILE_IMPRESSIONS, MOBILE_MERCHANT_WEBSITE_REFERRALS), `aggregate_by` (DAILY/WEEKLY/MONTHLY/YEARLY/COMPLETE), and `end_date`.
   - From: `caller`
   - To: `continuumMlsRinService`
   - Protocol: REST / HTTP

2. **Authenticate caller**: JTier auth bundle validates client-ID credentials.
   - From: `continuumMlsRinService`
   - To: `mlsRin_apiLayer` (internal)
   - Protocol: direct

3. **Query metrics database**: Metrics and Performance Services issue JDBI queries against `mlsRinMetricsDb` with deal_ids, type filter, aggregate_by period, and date range. Configuration controls `readBatchSize` and `metricsCutoffDays` to limit query scope.
   - From: `continuumMlsRinService`
   - To: `mlsRinMetricsDb`
   - Protocol: JDBI/PostgreSQL

4. **Aggregate and format response**: Results are grouped by metric type and time bucket and serialized to JSON.
   - From/To: `continuumMlsRinService` (internal)
   - Protocol: direct

5. **Return metrics response**: Returns JSON array of metric records bucketed by the requested aggregation period.
   - From: `continuumMlsRinService`
   - To: `caller`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Metrics DB unavailable | JDBI connection failure propagates | HTTP 500 returned to caller |
| Missing required parameters (deal_ids, type, aggregate_by, end_date) | JAX-RS validation failure | HTTP 400 returned |
| deal_ids references no metrics records | Empty result set returned | HTTP 200 with empty data |
| Authentication failure | JTier auth bundle rejects | HTTP 401 / 403 returned |

## Sequence Diagram

```
Caller -> continuumMlsRinService: GET /v1/metrics?deal_ids=...&type=WEB_CLICKS&aggregate_by=DAILY&end_date=...
continuumMlsRinService -> mlsRin_apiLayer: validate auth (client-id)
continuumMlsRinService -> mlsRinMetricsDb: SELECT metrics WHERE deal_id IN (...) AND type IN (...) AND date<=...
mlsRinMetricsDb --> continuumMlsRinService: metric rows
continuumMlsRinService -> mlsRin_metricsDomain: aggregate by period
continuumMlsRinService --> Caller: JSON metrics response
```

## Related

- Architecture dynamic view: `dynamic-continuumMlsRinService`
- Related flows: [Deal List Query](deal-list-query.md)
