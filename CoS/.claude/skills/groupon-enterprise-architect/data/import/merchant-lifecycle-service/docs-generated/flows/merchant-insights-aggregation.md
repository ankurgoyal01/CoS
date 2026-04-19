---
service: "merchant-lifecycle-service"
title: "Merchant Insights Aggregation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-insights-aggregation"
flow_type: synchronous
trigger: "API call — GET /insights/merchant/{uuid}/analytics or GET /insights/merchant/{uuid}/cxhealth"
participants:
  - "continuumMlsRinService"
  - "metricsPostgres"
  - "continuumMarketingDealService"
  - "merchantAdvisorService"
  - "continuumUgcService"
  - "continuumOrdersService"
architecture_ref: "components-mls-rin-service"
---

# Merchant Insights Aggregation

## Summary

This flow serves the merchant insights endpoints (`GET /insights/merchant/{uuid}/analytics` and `GET /insights/merchant/{uuid}/cxhealth`). The `continuumMlsRinService` reads pre-aggregated metrics from `metricsPostgres`, then enriches results with live or near-live data from marketing analytics, merchant advisor, UGC, and orders services. The combined result provides a comprehensive analytics or CX health snapshot for a given merchant UUID.

## Trigger

- **Type**: api-call
- **Source**: Merchant portal or internal tooling calls `GET /insights/merchant/{uuid}/analytics` or `GET /insights/merchant/{uuid}/cxhealth`
- **Frequency**: On demand, per request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller | Initiates insights request for a merchant UUID | — |
| `rinApiLayer` | Receives request and routes to insights domain | `continuumMlsRinService` |
| `rinInsightsDomain` | Orchestrates data retrieval and aggregation | `continuumMlsRinService` |
| `rinDataAccess` | Reads analytics and CX health data from local PostgreSQL | `continuumMlsRinService` |
| `metricsPostgres` | Pre-aggregated metrics and lifecycle analytics data | `metricsPostgres` |
| `rinExternalGateway` | Issues HTTP calls to upstream enrichment services | `continuumMlsRinService` |
| `continuumMarketingDealService` | Provides marketing analytics and deal-index data | `continuumMarketingDealService` |
| `merchantAdvisorService` | Provides merchant advisor performance metrics | `merchantAdvisorService` |
| `continuumUgcService` | Provides UGC summaries (ratings, reviews) | `continuumUgcService` |
| `continuumOrdersService` | Provides order and billing records for CX health | `continuumOrdersService` |

## Steps

1. **Receive insights request**: Caller sends `GET /insights/merchant/{uuid}/analytics` or `GET /insights/merchant/{uuid}/cxhealth`.
   - From: `caller`
   - To: `rinApiLayer`
   - Protocol: REST/HTTP

2. **Route to insights domain**: `rinApiLayer` delegates to `rinInsightsDomain` with the merchant UUID.
   - From: `rinApiLayer`
   - To: `rinInsightsDomain`
   - Protocol: direct (in-process)

3. **Read local metrics data**: `rinInsightsDomain` calls `rinDataAccess` to retrieve pre-aggregated analytics or CX health data from `metricsPostgres`.
   - From: `rinInsightsDomain`
   - To: `rinDataAccess` -> `metricsPostgres`
   - Protocol: JDBI/PostgreSQL

4. **Fetch external analytics context**: `rinInsightsDomain` calls `rinExternalGateway` to retrieve marketing analytics from `continuumMarketingDealService` and merchant advisor metrics from `merchantAdvisorService`, concurrently via RxJava 3.
   - From: `rinExternalGateway`
   - To: `continuumMarketingDealService`, `merchantAdvisorService`
   - Protocol: REST/HTTP

5. **Fetch UGC and order data**: For CX health requests, `rinInsightsDomain` also fetches UGC summaries from `continuumUgcService` and order/billing records from `continuumOrdersService`.
   - From: `rinExternalGateway`
   - To: `continuumUgcService`, `continuumOrdersService`
   - Protocol: REST/HTTP

6. **Aggregate and format response**: `rinInsightsDomain` merges local metrics with upstream enrichments and formats the insights response payload.
   - From: `rinInsightsDomain`
   - To: `rinApiLayer`
   - Protocol: direct (in-process)

7. **Return insights response**: `rinApiLayer` returns the aggregated response to the caller.
   - From: `rinApiLayer`
   - To: `caller`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `metricsPostgres` unavailable | JDBC connection failure | HTTP 5xx returned to caller |
| `continuumMarketingDealService` unavailable | RxJava error handling; field omitted | Partial insights response; marketing analytics absent |
| `merchantAdvisorService` unavailable | RxJava error handling; field omitted | Partial insights response; advisor metrics absent |
| `continuumUgcService` unavailable | RxJava error handling; field omitted | Partial CX health response; UGC data absent |
| `continuumOrdersService` unavailable | RxJava error handling; field omitted | Partial CX health response; order data absent |

## Sequence Diagram

```
Caller -> rinApiLayer: GET /insights/merchant/{uuid}/analytics (or /cxhealth)
rinApiLayer -> rinInsightsDomain: route insights request
rinInsightsDomain -> rinDataAccess: read local metrics
rinDataAccess -> metricsPostgres: SELECT analytics/CX health records
metricsPostgres --> rinDataAccess: metrics rows
rinDataAccess --> rinInsightsDomain: metrics data
rinInsightsDomain -> rinExternalGateway: fetch external analytics context (concurrent)
rinExternalGateway -> continuumMarketingDealService: GET marketing analytics
rinExternalGateway -> merchantAdvisorService: GET merchant advisor metrics
rinExternalGateway -> continuumUgcService: GET UGC summaries (cxhealth only)
rinExternalGateway -> continuumOrdersService: GET order/billing records (cxhealth only)
rinExternalGateway --> rinInsightsDomain: enrichment responses
rinInsightsDomain -> rinInsightsDomain: aggregate and format
rinInsightsDomain --> rinApiLayer: insights response payload
rinApiLayer --> Caller: HTTP 200 merchant insights
```

## Related

- Architecture component view: `components-mls-rin-service`
- Related flows: [Unit Search Aggregation](unit-search-aggregation.md)
