---
service: "api-proxy"
title: "Rate Limiting Enforcement"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "rate-limiting-enforcement"
flow_type: synchronous
trigger: "Every inbound proxied request, inline within the filter chain"
participants:
  - "apiProxy_filterChainEngine"
  - "apiProxy_rateLimiter"
  - "apiProxy_clientIdLoader"
  - "continuumApiProxyRedis"
architecture_ref: "dynamic-api-apiProxy_destinationProxy-request-processing"
---

# Rate Limiting Enforcement

## Summary

Rate Limiting Enforcement is an inline sub-flow within the main request routing flow. For every request that has passed route resolution, the Filter Chain Engine delegates to the Rate Limiter to determine whether the request should be throttled. The Rate Limiter retrieves client-specific policy overrides from the Client ID Loader and then reads and increments an atomic counter in `continuumApiProxyRedis`. If the counter exceeds the configured threshold, the request is rejected immediately with HTTP 429.

## Trigger

- **Type**: api-call (inline, per-request)
- **Source**: Filter Chain Engine, during request processing, after route resolution
- **Frequency**: Per-request (every inbound request to `/*`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Filter Chain Engine | Invokes Rate Limiter as part of the ordered filter sequence | `apiProxy_filterChainEngine` |
| Rate Limiter | Core enforcement component; reads counters, applies limits, decides allow/reject | `apiProxy_rateLimiter` |
| Client ID Loader | Supplies per-client rate-limit thresholds and policy overrides | `apiProxy_clientIdLoader` |
| API Proxy Redis | Stores shared atomic rate-limit counters and throttling state across all proxy instances | `continuumApiProxyRedis` |

## Steps

1. **Filter chain invokes Rate Limiter**: After resolving the route, the Filter Chain Engine calls the Rate Limiter with the current request context (client ID, route identifier).
   - From: `apiProxy_filterChainEngine`
   - To: `apiProxy_rateLimiter`
   - Protocol: direct (in-process)

2. **Load client-level policy overrides**: Rate Limiter queries the Client ID Loader for the client's configured rate-limit threshold and any per-client policy overrides (e.g., elevated limits for trusted clients).
   - From: `apiProxy_rateLimiter`
   - To: `apiProxy_clientIdLoader`
   - Protocol: direct (in-process)

3. **Determine applicable limit and key**: Rate Limiter constructs the Redis key (namespace + client ID + route + time window) and identifies the applicable counter limit from the policy.
   - From: `apiProxy_rateLimiter`
   - To: `apiProxy_rateLimiter` (internal)
   - Protocol: direct (in-process)

4. **Read and atomically increment counter**: Rate Limiter executes an atomic increment (e.g., Redis `INCR` / `INCRBY`) on the computed key in `continuumApiProxyRedis`. The returned value is the current count within the window.
   - From: `apiProxy_rateLimiter`
   - To: `continuumApiProxyRedis`
   - Protocol: RESP/TCP (Jedis 2.1.0)

5. **Evaluate allow or reject decision**: Rate Limiter compares the counter value against the applicable limit.
   - If counter is within limit: returns `allow` to the Filter Chain Engine; processing continues to the next filter (reCAPTCHA or forwarding).
   - If counter exceeds limit: returns `reject`; Filter Chain Engine terminates the request and returns HTTP 429.
   - From: `apiProxy_rateLimiter`
   - To: `apiProxy_filterChainEngine`
   - Protocol: direct (in-process)

6. **Set throttle state flag (on breach)**: When a limit is first exceeded, the Rate Limiter may set a throttle state key in Redis with a TTL to avoid repeated counter reads for already-throttled clients.
   - From: `apiProxy_rateLimiter`
   - To: `continuumApiProxyRedis`
   - Protocol: RESP/TCP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis connection timeout | Jedis raises connection exception; Rate Limiter cannot read counter | Fail-open or fail-closed depending on configuration; request may proceed or be rejected |
| Redis returns unexpected value | Rate Limiter falls back to conservative estimate | May result in premature throttling or missed limit enforcement |
| Client ID Loader cache miss | Client ID Loader falls back to global default limits | Global rate limit applied instead of per-client override |
| Counter key expired between read and increment | Standard Redis INCR handles atomically; no race condition | Counter resets correctly for new window |

## Sequence Diagram

```
apiProxy_filterChainEngine -> apiProxy_rateLimiter: Evaluate throttling (clientId, routeId)
apiProxy_rateLimiter -> apiProxy_clientIdLoader: Load client-level policy overrides
apiProxy_clientIdLoader --> apiProxy_rateLimiter: Rate-limit threshold + policy
apiProxy_rateLimiter -> continuumApiProxyRedis: INCR rate-limit counter key (RESP/TCP)
continuumApiProxyRedis --> apiProxy_rateLimiter: Current counter value
apiProxy_rateLimiter -> apiProxy_rateLimiter: Compare counter vs. limit
apiProxy_rateLimiter --> apiProxy_filterChainEngine: Allow (continue) or Reject (HTTP 429)
```

## Related

- Architecture dynamic view: `dynamic-api-apiProxy_destinationProxy-request-processing`
- Related flows: [Request Routing](request-routing.md), [Config Reload](config-reload.md)
