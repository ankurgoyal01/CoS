---
service: "arbitration-service"
title: "Startup Cache Loading"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "startup-cache-loading"
flow_type: scheduled
trigger: "Service process startup"
participants:
  - "continuumArbitrationService"
  - "deliveryRuleManager"
  - "experimentationAdapter"
  - "campaignMetaAccess"
  - "absPostgres"
  - "optimizelyService"
architecture_ref: "dynamic-startupCacheLoading"
---

# Startup Cache Loading

## Summary

At service startup, the Arbitration Service proactively preloads two categories of data into in-memory caches: delivery rules from PostgreSQL and experiment configuration from Optimizely. This eliminates cold-start latency on the first incoming requests and ensures that the hot decisioning path (best-for and arbitrate) can serve requests immediately without blocking on database reads. Cache loading completes before the service is marked ready by Kubernetes readiness probes.

## Trigger

- **Type**: startup
- **Source**: Service process initialization (internal, not externally triggered)
- **Frequency**: Once per service startup; also triggered when pods are cycled or restarted by Kubernetes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Delivery Rule Manager | Orchestrates loading of delivery rules from PostgreSQL into in-memory cache | `deliveryRuleManager` |
| Experimentation Adapter | Fetches and caches experiment config from Optimizely on startup | `experimentationAdapter` |
| Campaign Metadata Access | Executes PostgreSQL query to load delivery rules | `campaignMetaAccess` |
| PostgreSQL | Source of delivery rule records | `absPostgres` |
| Optimizely | Source of experiment definitions | `optimizelyService` |

## Steps

1. **Initiate startup sequence**: Service process starts; initialization logic triggers cache loading before accepting HTTP traffic.
   - From: service runtime
   - To: `deliveryRuleManager` and `experimentationAdapter`
   - Protocol: direct (in-process)

2. **Load delivery rules from PostgreSQL**: Delivery rule manager queries PostgreSQL for all active delivery rules via campaign metadata access and populates the in-memory rule cache.
   - From: `deliveryRuleManager` via `campaignMetaAccess`
   - To: `absPostgres`
   - Protocol: PostgreSQL

3. **Populate in-memory delivery rule cache**: Delivery rule manager stores the loaded rules in memory, making them available for eligibility evaluation in best-for requests without per-request database reads.
   - From: `deliveryRuleManager`
   - To: `deliveryRuleManager`
   - Protocol: direct (in-process)

4. **Fetch experiment config from Optimizely**: Experimentation adapter uses the Optimizely Go SDK to fetch the current experiment datafile using the configured `OPTIMIZELY_SDK_KEY`.
   - From: `experimentationAdapter`
   - To: `optimizelyService`
   - Protocol: HTTPS (Optimizely CDN / SDK)

5. **Populate in-memory experiment config cache**: Experimentation adapter stores the fetched experiment definitions in memory, making them available for arbitration algorithm configuration.
   - From: `experimentationAdapter`
   - To: `experimentationAdapter`
   - Protocol: direct (in-process)

6. **Signal readiness**: Once cache loading completes successfully, the service begins accepting HTTP traffic and Kubernetes readiness probe (`GET /health`) returns healthy.
   - From: service runtime
   - To: Kubernetes readiness probe
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL unavailable at startup | Startup may fail or proceed with empty rule cache | If empty cache, best-for requests cannot evaluate rules; readiness probe may remain unhealthy |
| Optimizely fetch fails at startup | Log warning; proceed with empty experiment config | Service starts without experiment context; arbitration uses default algorithm behavior |
| Partial rule load (query timeout) | Depends on implementation | Risk of serving requests with incomplete rule set; operational procedures to be defined by service owner |

## Sequence Diagram

```
serviceRuntime -> deliveryRuleManager: initialize delivery rule cache
deliveryRuleManager -> absPostgres: query all active delivery rules
absPostgres --> deliveryRuleManager: delivery rule records
deliveryRuleManager -> deliveryRuleManager: populate in-memory rule cache
serviceRuntime -> experimentationAdapter: initialize experiment config cache
experimentationAdapter -> optimizelyService: fetch experiment datafile (SDK key auth)
optimizelyService --> experimentationAdapter: experiment definitions (datafile)
experimentationAdapter -> experimentationAdapter: populate in-memory experiment config cache
serviceRuntime -> kubernetesProbe: GET /health returns healthy
kubernetesProbe --> serviceRuntime: readiness confirmed; traffic routing enabled
```

## Related

- Architecture dynamic view: `dynamic-startupCacheLoading`
- Related flows: [Experiment Config Refresh](experiment-config-refresh.md) — same Optimizely fetch logic; also runs on demand and periodically
- Related flows: [Best-For Selection](best-for-selection.md) — consumes delivery rule cache populated by this flow
- Related flows: [Delivery Rule Management](delivery-rule-management.md) — rule updates should trigger cache invalidation or refresh
