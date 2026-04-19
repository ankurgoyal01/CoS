---
service: "api-lazlo-sox"
title: "Mobile API Request Flow"
generated: "2026-03-03"
type: flow
flow_name: "mobile-api-request-flow"
flow_type: synchronous
trigger: "HTTP request from mobile app or web client"
participants:
  - "continuumApiLazloService_httpApi"
  - "continuumApiLazloService_commonFiltersAndViews"
  - "continuumApiLazloService_dealsAndListingsApi"
  - "continuumApiLazloService_dealsBlsModule"
  - "continuumApiLazloService_downstreamServiceClients"
  - "continuumApiLazloService_redisAccess"
  - "continuumApiLazloRedisCache"
  - "continuumApiLazloService_metricsAndLogging"
architecture_ref: "dynamic-api-lazlo-request"
---

# Mobile API Request Flow

## Summary

This flow describes the end-to-end path of a typical mobile API request through API Lazlo. A mobile client sends an HTTP request to `/api/mobile/{countryCode}/...`, which is received by the Vert.x HTTP server, processed through common filters (locale, headers, metrics), routed to the appropriate domain controller, delegated to a BLS module for business logic orchestration, and fulfilled by calls to downstream services and the Redis cache before a composed JSON response is returned.

## Trigger

- **Type**: API call
- **Source**: Groupon mobile app (iOS/Android) or web client
- **Frequency**: Per-request (millions of requests per day)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Mobile Client | Initiates the HTTP request | External |
| HTTP Mobile API Gateway | Receives the request, applies SSL, wires routing | `continuumApiLazloService_httpApi` |
| Common Filters, Params and Views | Applies locale handling, header processing, metrics | `continuumApiLazloService_commonFiltersAndViews` |
| Domain Controller (e.g., Deals API) | Handles the specific endpoint routing | `continuumApiLazloService_dealsAndListingsApi` |
| BLS Module (e.g., Deals BLS) | Orchestrates business logic and downstream calls | `continuumApiLazloService_dealsBlsModule` |
| Downstream Service Clients | Makes typed HTTP calls to downstream services | `continuumApiLazloService_downstreamServiceClients` |
| Redis Cache Access | Reads/writes cached data | `continuumApiLazloService_redisAccess` |
| API Lazlo Redis Cache | Distributed cache store | `continuumApiLazloRedisCache` |
| Metrics and Logging | Records request metrics and structured logs | `continuumApiLazloService_metricsAndLogging` |

## Steps

1. **Client sends HTTP request**: Mobile client sends a REST/JSON request to `/api/mobile/{countryCode}/{endpoint}`.
   - From: Mobile Client
   - To: `continuumApiLazloService_httpApi`
   - Protocol: HTTPS/JSON

2. **Apply common filters**: The HTTP gateway applies cross-cutting filters including locale resolution, header processing, metrics initialization, and authentication validation.
   - From: `continuumApiLazloService_httpApi`
   - To: `continuumApiLazloService_commonFiltersAndViews`
   - Protocol: in-process

3. **Route to domain controller**: Based on the URL path, the request is routed to the appropriate domain controller (e.g., Deals API for `/deals` paths).
   - From: `continuumApiLazloService_httpApi`
   - To: `continuumApiLazloService_dealsAndListingsApi` (example)
   - Protocol: in-process

4. **Delegate to BLS module**: The controller delegates business logic to the appropriate BLS module via the Lazlo EventBus / Promises pattern.
   - From: `continuumApiLazloService_dealsAndListingsApi`
   - To: `continuumApiLazloService_dealsBlsModule`
   - Protocol: Lazlo EventBus / Promises

5. **Check Redis cache**: The BLS module checks Redis for cached data (taxonomy, localization, previously computed results).
   - From: `continuumApiLazloService_dealsBlsModule`
   - To: `continuumApiLazloService_redisAccess`
   - Protocol: Redis client

6. **Call downstream services**: For data not in cache, the BLS module calls downstream domain services through typed Lazlo clients.
   - From: `continuumApiLazloService_dealsBlsModule`
   - To: `continuumApiLazloService_downstreamServiceClients`
   - Protocol: HTTP/JSON over internal network

7. **Populate cache**: Responses from downstream services are cached in Redis with appropriate TTLs.
   - From: `continuumApiLazloService_dealsBlsModule`
   - To: `continuumApiLazloService_redisAccess`
   - Protocol: Redis client

8. **Compose and return response**: The BLS module composes the aggregated response, the controller applies views, and the HTTP gateway returns the JSON response to the client.
   - From: `continuumApiLazloService_httpApi`
   - To: Mobile Client
   - Protocol: HTTPS/JSON

9. **Record metrics**: Throughout the flow, metrics-vertx records request duration, status codes, and downstream call metrics.
   - From: `continuumApiLazloService_metricsAndLogging`
   - To: Metrics backend
   - Protocol: Metrics export

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Downstream service timeout | Configurable timeout per client; request fails with 502/504 | Client receives error response with appropriate HTTP status |
| Redis cache unavailable | Cache miss path; request proceeds without cache (degraded latency) | Request succeeds but with higher latency |
| Authentication failure | Common filters reject request before reaching controller | 401 Unauthorized returned to client |
| Invalid country code | Common filters validate path parameters | 400 Bad Request returned to client |
| Downstream 5xx error | Error mapped by Lazlo client to appropriate API Lazlo error response | Client receives 502 or domain-specific error |

## Sequence Diagram

```
Mobile Client -> continuumApiLazloService_httpApi: HTTPS /api/mobile/{cc}/{endpoint}
continuumApiLazloService_httpApi -> continuumApiLazloService_commonFiltersAndViews: Apply filters (locale, headers, auth)
continuumApiLazloService_commonFiltersAndViews --> continuumApiLazloService_httpApi: Filters applied
continuumApiLazloService_httpApi -> continuumApiLazloService_dealsAndListingsApi: Route to controller
continuumApiLazloService_dealsAndListingsApi -> continuumApiLazloService_dealsBlsModule: Delegate via EventBus
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_redisAccess: Check cache
continuumApiLazloService_redisAccess -> continuumApiLazloRedisCache: GET cached data
continuumApiLazloRedisCache --> continuumApiLazloService_redisAccess: Cache hit/miss
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_downstreamServiceClients: Call downstream services (on miss)
continuumApiLazloService_downstreamServiceClients --> continuumApiLazloService_dealsBlsModule: Downstream responses
continuumApiLazloService_dealsBlsModule -> continuumApiLazloService_redisAccess: Populate cache
continuumApiLazloService_dealsBlsModule --> continuumApiLazloService_dealsAndListingsApi: Composed result
continuumApiLazloService_dealsAndListingsApi --> continuumApiLazloService_httpApi: Controller response
continuumApiLazloService_httpApi --> Mobile Client: HTTPS JSON response
```

## Related

- Architecture component view: `components-continuum-continuumApiLazloService_httpApi-lazlo-service`
- Related flows: [Deal Discovery Flow](deal-discovery-flow.md), [User Authentication Flow](user-authentication-flow.md)
