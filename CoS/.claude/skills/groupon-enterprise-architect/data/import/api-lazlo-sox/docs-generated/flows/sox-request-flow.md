---
service: "api-lazlo-sox"
title: "SOX Request Flow"
generated: "2026-03-03"
type: flow
flow_name: "sox-request-flow"
flow_type: synchronous
trigger: "HTTP request to SOX-regulated endpoint"
participants:
  - "continuumApiLazloSoxService_httpApi"
  - "continuumApiLazloSoxService_commonFiltersAndViews"
  - "continuumApiLazloSoxService_partnersApi"
  - "continuumApiLazloSoxService_sharedBlsModules"
  - "continuumApiLazloSoxService_downstreamServiceClients"
  - "continuumApiLazloSoxService_redisAccess"
  - "continuumApiLazloRedisCache"
  - "continuumApiLazloSoxService_metricsAndLogging"
architecture_ref: "dynamic-api-lazlo-sox-request"
---

# SOX Request Flow

## Summary

This flow describes how a request is processed through the API Lazlo SOX Service, the SOX-scoped variant of the mobile API gateway. The SOX service handles a restricted subset of endpoints focused on partner bookings and regulated user/account flows. It applies the same Vert.x/Lazlo architecture as the main API Lazlo service but with SOX-specific routing, configuration, and compliance controls. The service is deployed independently to meet Sarbanes-Oxley regulatory requirements.

## Trigger

- **Type**: API call
- **Source**: Client application accessing SOX-regulated partner or user flows
- **Frequency**: Per-request (lower volume than main API Lazlo, focused on partner/booking flows)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SOX Client | Initiates the HTTP request to SOX-regulated endpoint | External |
| HTTP Mobile API Gateway (SOX) | Receives the request, applies SOX-specific routing | `continuumApiLazloSoxService_httpApi` |
| Common Filters (SOX) | Applies shared filters with SOX-specific configuration | `continuumApiLazloSoxService_commonFiltersAndViews` |
| Partners and Bookings API (SOX) | Handles SOX partner and listings endpoints | `continuumApiLazloSoxService_partnersApi` |
| Shared BLS Domain Modules (SOX) | Reuses core BLS modules under SOX configuration | `continuumApiLazloSoxService_sharedBlsModules` |
| Downstream Service Clients (SOX) | Makes HTTP calls with SOX-specific client configuration | `continuumApiLazloSoxService_downstreamServiceClients` |
| Redis Cache Access (SOX) | Reads/writes cached data for SOX flows | `continuumApiLazloSoxService_redisAccess` |
| API Lazlo Redis Cache | Shared distributed cache store | `continuumApiLazloRedisCache` |
| Metrics and Logging (SOX) | Records metrics and audit logs for compliance | `continuumApiLazloSoxService_metricsAndLogging` |

## Steps

1. **Client sends SOX request**: Client sends an HTTP request to a SOX-regulated endpoint (e.g., `/api/mobile/{countryCode}/partners/{partnerId}/bookings`).
   - From: SOX Client
   - To: `continuumApiLazloSoxService_httpApi`
   - Protocol: HTTPS/JSON

2. **Apply SOX common filters**: The SOX HTTP gateway applies common filters including locale, headers, metrics, and SOX-specific authorization and compliance checks.
   - From: `continuumApiLazloSoxService_httpApi`
   - To: `continuumApiLazloSoxService_commonFiltersAndViews`
   - Protocol: in-process

3. **Route to SOX controller**: The request is routed to the SOX-specific controller (e.g., Partners and Bookings API).
   - From: `continuumApiLazloSoxService_httpApi`
   - To: `continuumApiLazloSoxService_partnersApi`
   - Protocol: in-process

4. **Delegate to shared BLS modules**: The SOX controller delegates business logic to the shared BLS domain modules, which reuse the same core logic as the main API Lazlo service but under SOX-specific routing and configuration.
   - From: `continuumApiLazloSoxService_partnersApi`
   - To: `continuumApiLazloSoxService_sharedBlsModules`
   - Protocol: Lazlo EventBus / Promises

5. **Check Redis cache**: The BLS module checks Redis for cached configuration and transient state.
   - From: `continuumApiLazloSoxService_sharedBlsModules`
   - To: `continuumApiLazloSoxService_redisAccess`
   - Protocol: Redis client

6. **Call downstream services (SOX config)**: The BLS module calls downstream domain services through Lazlo clients configured with SOX-specific schemas and endpoints.
   - From: `continuumApiLazloSoxService_sharedBlsModules`
   - To: `continuumApiLazloSoxService_downstreamServiceClients`
   - Protocol: HTTP/JSON over internal network

7. **Compose and return SOX response**: The BLS module composes the response, the controller applies views, and the HTTP gateway returns the JSON response with SOX compliance headers.
   - From: `continuumApiLazloSoxService_httpApi`
   - To: SOX Client
   - Protocol: HTTPS/JSON

8. **Record SOX audit metrics**: Metrics and audit logging capture the request for SOX compliance tracking.
   - From: `continuumApiLazloSoxService_metricsAndLogging`
   - To: Metrics and audit backend
   - Protocol: Metrics export / Structured logging

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SOX authorization failure | SOX filters reject requests that do not meet compliance criteria | 403 Forbidden with audit log entry |
| Downstream service timeout | Configurable timeout per SOX client; request fails | 502/504 returned to client with audit trail |
| Redis cache unavailable | Fallback to direct downstream calls | Degraded latency but functional |
| Invalid partner ID | Controller validates path parameters | 404 Not Found |
| SOX compliance violation | Request blocked at filter level | 403 Forbidden, logged for audit |

## Sequence Diagram

```
SOX Client -> continuumApiLazloSoxService_httpApi: HTTPS /api/mobile/{cc}/partners/{id}/bookings
continuumApiLazloSoxService_httpApi -> continuumApiLazloSoxService_commonFiltersAndViews: Apply SOX filters (auth, compliance, locale)
continuumApiLazloSoxService_commonFiltersAndViews --> continuumApiLazloSoxService_httpApi: SOX filters applied
continuumApiLazloSoxService_httpApi -> continuumApiLazloSoxService_partnersApi: Route to SOX partners controller
continuumApiLazloSoxService_partnersApi -> continuumApiLazloSoxService_sharedBlsModules: Delegate via EventBus
continuumApiLazloSoxService_sharedBlsModules -> continuumApiLazloSoxService_redisAccess: Check cache
continuumApiLazloSoxService_redisAccess -> continuumApiLazloRedisCache: GET cached data
continuumApiLazloRedisCache --> continuumApiLazloSoxService_redisAccess: Cache hit/miss
continuumApiLazloSoxService_sharedBlsModules -> continuumApiLazloSoxService_downstreamServiceClients: Call downstream (SOX config)
continuumApiLazloSoxService_downstreamServiceClients --> continuumApiLazloSoxService_sharedBlsModules: Downstream responses
continuumApiLazloSoxService_sharedBlsModules --> continuumApiLazloSoxService_partnersApi: Composed result
continuumApiLazloSoxService_partnersApi --> continuumApiLazloSoxService_httpApi: Controller response
continuumApiLazloSoxService_httpApi --> SOX Client: HTTPS JSON response (SOX compliant)
```

## Related

- Architecture component view: `components-continuum-continuumApiLazloService_httpApi-lazlo-sox-service`
- Related flows: [Mobile API Request Flow](mobile-api-request-flow.md), [User Authentication Flow](user-authentication-flow.md)
