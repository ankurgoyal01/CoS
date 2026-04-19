---
service: "api-proxy"
title: "Request Routing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "request-routing"
flow_type: synchronous
trigger: "Inbound HTTP request from a consumer or merchant client application"
participants:
  - "apiProxy_requestRouter"
  - "apiProxy_filterChainEngine"
  - "apiProxy_routeConfigLoader"
  - "apiProxy_rateLimiter"
  - "apiProxy_clientIdLoader"
  - "apiProxy_recaptchaClient"
  - "apiProxy_destinationProxy"
  - "continuumApiProxyRedis"
architecture_ref: "dynamic-api-apiProxy_destinationProxy-request-processing"
---

# Request Routing

## Summary

Request Routing is the primary runtime flow of API Proxy. On every inbound HTTP request, the Request Router builds a request context and passes it through the Filter Chain Engine, which evaluates routing rules, applies throttling constraints, optionally validates a reCAPTCHA token, and — if all policies allow — forwards the request to the resolved backend destination service. The response is streamed back to the original caller.

## Trigger

- **Type**: api-call
- **Source**: Consumer or merchant client application (legacy Android, legacy iOS, legacy web, Merchant Center) sending an HTTP request to `/*`
- **Frequency**: Per-request (continuous, on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Request Router | Accepts inbound HTTP request; builds request context; initiates filter chain | `apiProxy_requestRouter` |
| Filter Chain Engine | Orchestrates ordered filter execution: routing, rate limiting, reCAPTCHA, forwarding | `apiProxy_filterChainEngine` |
| Route Config Loader | Provides cached route definitions and filter directives for route resolution | `apiProxy_routeConfigLoader` |
| Rate Limiter | Evaluates whether the request exceeds configured throttling thresholds | `apiProxy_rateLimiter` |
| Client ID Loader | Supplies client-specific policy overrides and rate-limit configuration | `apiProxy_clientIdLoader` |
| reCAPTCHA Client | Calls Google reCAPTCHA API to verify a token when the route requires it | `apiProxy_recaptchaClient` |
| Destination Proxy | Forwards the allowed request to the resolved backend destination; streams response back | `apiProxy_destinationProxy` |
| API Proxy Redis | Stores and returns rate-limit counters incremented by the Rate Limiter | `continuumApiProxyRedis` |

## Steps

1. **Receive request**: Request Router receives the inbound HTTP request from the client.
   - From: Client application
   - To: `apiProxy_requestRouter`
   - Protocol: HTTP/HTTPS

2. **Build context and start filter chain**: Request Router constructs a request context object (method, path, headers, client ID) and passes it to the Filter Chain Engine.
   - From: `apiProxy_requestRouter`
   - To: `apiProxy_filterChainEngine`
   - Protocol: direct (in-process)

3. **Resolve matching route and directives**: Filter Chain Engine queries the Route Config Loader for the route definition matching the request path; retrieves associated filter directives (e.g., reCAPTCHA required, rate-limit policy).
   - From: `apiProxy_filterChainEngine`
   - To: `apiProxy_routeConfigLoader`
   - Protocol: direct (in-process)

4. **Evaluate throttling constraints**: Filter Chain Engine invokes the Rate Limiter to check whether the current request exceeds the applicable rate-limit threshold.
   - From: `apiProxy_filterChainEngine`
   - To: `apiProxy_rateLimiter`
   - Protocol: direct (in-process)

5. **Load client-level policy overrides**: Rate Limiter retrieves client-specific limits and policy overrides from the Client ID Loader.
   - From: `apiProxy_rateLimiter`
   - To: `apiProxy_clientIdLoader`
   - Protocol: direct (in-process)

6. **Read and increment Redis counter**: Rate Limiter reads the current counter for the client/route key from Redis and increments it atomically. If the counter exceeds the limit, the request is rejected with HTTP 429.
   - From: `apiProxy_rateLimiter`
   - To: `continuumApiProxyRedis`
   - Protocol: RESP/TCP

7. **Verify reCAPTCHA token (conditional)**: If the resolved route requires reCAPTCHA validation and the request includes a token, Filter Chain Engine invokes the reCAPTCHA Client to verify the token with Google's API. This step is skipped for routes without reCAPTCHA enforcement.
   - From: `apiProxy_filterChainEngine`
   - To: `apiProxy_recaptchaClient`
   - Protocol: direct (in-process) → HTTPS to Google reCAPTCHA API

8. **Forward request to backend destination**: Filter Chain Engine instructs the Destination Proxy to forward the request to the resolved backend service.
   - From: `apiProxy_filterChainEngine`
   - To: `apiProxy_destinationProxy`
   - Protocol: direct (in-process)

9. **Proxy request to backend and return response**: Destination Proxy sends the HTTP request to the backend destination service and streams the response back to the original caller.
   - From: `apiProxy_destinationProxy`
   - To: Backend destination service → Client application
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No matching route found | Filter Chain Engine terminates processing | HTTP 404 returned to caller |
| Rate limit exceeded | Rate Limiter rejects request after Redis counter check | HTTP 429 returned to caller |
| reCAPTCHA validation fails | reCAPTCHA Client returns failure; filter chain rejects request | HTTP 4xx returned to caller |
| Backend destination unreachable | Destination Proxy receives connection error | HTTP 502/503 propagated to caller |
| Redis unavailable | Rate Limiter cannot read/write counters | Rate limiting degraded; request may proceed depending on fail-open/fail-closed config |
| reCAPTCHA API unavailable | reCAPTCHA Client receives timeout/error | Configurable fallback per route policy |

## Sequence Diagram

```
Client -> apiProxy_requestRouter: HTTP request (method, path, headers)
apiProxy_requestRouter -> apiProxy_filterChainEngine: Build context, start filter chain
apiProxy_filterChainEngine -> apiProxy_routeConfigLoader: Resolve matching route and directives
apiProxy_routeConfigLoader --> apiProxy_filterChainEngine: Route definition + filter config
apiProxy_filterChainEngine -> apiProxy_rateLimiter: Evaluate throttling constraints
apiProxy_rateLimiter -> apiProxy_clientIdLoader: Load client-level policy overrides
apiProxy_clientIdLoader --> apiProxy_rateLimiter: Client limits + policy
apiProxy_rateLimiter -> continuumApiProxyRedis: Read + increment counter (RESP/TCP)
continuumApiProxyRedis --> apiProxy_rateLimiter: Counter value
apiProxy_rateLimiter --> apiProxy_filterChainEngine: Allow or reject
apiProxy_filterChainEngine -> apiProxy_recaptchaClient: [if required] Verify reCAPTCHA token
apiProxy_recaptchaClient --> apiProxy_filterChainEngine: Verification result
apiProxy_filterChainEngine -> apiProxy_destinationProxy: Forward allowed request
apiProxy_destinationProxy -> BackendDestinationService: HTTP request (HTTPS)
BackendDestinationService --> apiProxy_destinationProxy: HTTP response
apiProxy_destinationProxy --> Client: HTTP response
```

## Related

- Architecture dynamic view: `dynamic-api-apiProxy_destinationProxy-request-processing`
- Related flows: [Config Reload](config-reload.md), [Rate Limiting Enforcement](rate-limiting-enforcement.md)
