---
service: "booster"
title: "Booster Relevance Request"
generated: "2026-03-03"
type: flow
flow_name: "booster-relevance-request"
flow_type: synchronous
trigger: "Consumer deal discovery or search request arrives at the API gateway"
participants:
  - "apiProxy"
  - "continuumRelevanceApi"
  - "continuumApiLazloService"
  - "continuumBoosterService"
  - "booster"
architecture_ref: "dynamic-booster-relevance-request"
---

# Booster Relevance Request

## Summary

This flow describes how a consumer deal discovery or search request is routed through Groupon's API infrastructure to obtain ranked deal recommendations from the Booster external SaaS. The request follows the critical consumer path from `apiProxy` through `continuumRelevanceApi`, which calls the Booster API over HTTPS and returns an ordered list of deal recommendations to the consumer. The flow is synchronous and on the critical consumer request path.

## Trigger

- **Type**: api-call
- **Source**: Consumer browsing or searching for deals on the Groupon platform; routed to the Relevance API via the API gateway
- **Frequency**: Per-request (on-demand, synchronous with each consumer discovery or search request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Gateway / Proxy | Receives consumer request and routes to Relevance API | `apiProxy` |
| Relevance API | Orchestrates relevance ranking by calling Booster; enriches results | `continuumRelevanceApi` |
| Lazlo API Service | Provides proxied search routing to Relevance API | `continuumApiLazloService` |
| Booster Integration Boundary | Integration contract representing the Booster connection | `continuumBoosterService` |
| Booster (Data Breakers SaaS) | Receives deal context and returns ranked recommendations | `booster` |

## Steps

1. **Receive consumer deal discovery request**: The consumer initiates a browse or search request on the Groupon platform.
   - From: `consumer`
   - To: `apiProxy`
   - Protocol: HTTPS

2. **Route to Relevance API**: The API gateway forwards the request to `continuumRelevanceApi` on the critical path.
   - From: `apiProxy`
   - To: `continuumRelevanceApi`
   - Protocol: REST / SyncAPI, CriticalPath

3. **Call Booster for ranked recommendations**: `continuumRelevanceApi` submits the deal context and request parameters to the Booster external API to obtain ranked deal recommendations.
   - From: `continuumRelevanceApi` (via `continuumBoosterService` integration boundary)
   - To: `booster`
   - Protocol: HTTPS

4. **Return ranked results**: Booster processes the relevance signals and returns an ordered list of deal recommendations.
   - From: `booster`
   - To: `continuumRelevanceApi`
   - Protocol: HTTPS

5. **Enrich and return response**: `continuumRelevanceApi` optionally enriches ranked results (e.g., via `continuumMarketingDealService` or `continuumApiLazloService`) and returns the final ranked deal list to `apiProxy` and then to the consumer.
   - From: `continuumRelevanceApi`
   - To: `apiProxy` → consumer
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Booster API unavailable | No evidence found in codebase — fallback not documented in architecture model | Consumer may receive unranked or degraded deal listings |
| Booster API returns error response | No evidence found in codebase | Error propagated; on-call alerted via PagerDuty PPPC7X8 |
| Booster API high latency | Integration health monitor detects latency increase; alert triggered | Potential consumer-facing latency degradation on deal discovery |

## Sequence Diagram

```
Consumer -> apiProxy: Deal discovery / search request (HTTPS)
apiProxy -> continuumRelevanceApi: Route relevance request (REST, CriticalPath)
continuumRelevanceApi -> booster: Request ranked deal recommendations (HTTPS)
booster --> continuumRelevanceApi: Ranked deal recommendations
continuumRelevanceApi --> apiProxy: Enriched ranked results (REST)
apiProxy --> Consumer: Ranked deal list (HTTPS)
```

## Related

- Architecture dynamic view: `dynamic-booster-relevance-request`
- Component view: `components-continuum-booster-service`
- Related flows: [Integration Health Monitoring](integration-health-monitoring.md)
- [Architecture Context](../architecture-context.md)
