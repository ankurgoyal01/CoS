---
service: "subscription_flow"
title: "Config and Experiment Loading"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "config-and-experiment-loading"
flow_type: synchronous
trigger: "Service bootstrap startup or scheduled config refresh"
participants:
  - "continuumSubscriptionFlowService"
  - "gconfigService_4b3a"
architecture_ref: "dynamic-config-and-experiment-loading"
---

# Config and Experiment Loading

## Summary

When Subscription Flow starts up (or refreshes its configuration), the Bootstrap component initialises the itier-server application and the Config Loader fetches dynamic configuration and A/B experiment definitions from the GConfig Service. Resolved configuration values and experiment variant bindings are held in memory and made available to all subsequent request handlers via the Controller Layer. This flow ensures the service has current feature flags and experiment assignments before it begins serving traffic.

## Trigger

- **Type**: schedule / startup
- **Source**: Service process startup; periodic config refresh triggered by the itier-server bootstrap lifecycle
- **Frequency**: At every pod startup; periodically during operation (refresh interval determined by GConfig polling configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Subscription Flow Service (Bootstrap) | Initialises application and triggers config load | `continuumSubscriptionFlowService` |
| Config Loader | Fetches and caches configuration from GConfig | `continuumSubscriptionFlowService` (configLoader_SubFlo component) |
| GConfig Service | Provides dynamic configuration and experiment definitions | `gconfigService_4b3a` |

## Steps

1. **Start Bootstrap**: Pod starts; itier-server Bootstrap component begins application initialisation.
   - From: Kubernetes pod start
   - To: `continuumSubscriptionFlowService` (bootstrap component)
   - Protocol: process lifecycle

2. **Invoke Config Loader**: Bootstrap calls the Config Loader to fetch configuration before routing is enabled.
   - From: `continuumSubscriptionFlowService` (bootstrap)
   - To: `continuumSubscriptionFlowService` (configLoader_SubFlo)
   - Protocol: internal

3. **Fetch Configuration from GConfig**: Config Loader makes an HTTP request to GConfig Service to retrieve all configuration keys and experiment definitions for the `subscription_flow` service namespace.
   - From: `continuumSubscriptionFlowService`
   - To: `gconfigService_4b3a`
   - Protocol: REST / HTTP

4. **Receive Config and Experiment Definitions**: GConfig Service responds with the full configuration payload including feature flags, experiment variant definitions, and client bindings.
   - From: `gconfigService_4b3a`
   - To: `continuumSubscriptionFlowService`
   - Protocol: REST / HTTP

5. **Resolve Experiment Variants**: Config Loader processes the experiment definitions and resolves default variant bindings.
   - From: `continuumSubscriptionFlowService` (configLoader_SubFlo)
   - To: `continuumSubscriptionFlowService` (in-memory config store)
   - Protocol: internal

6. **Set Client Bindings**: Resolved configuration values and experiment bindings are set in the in-memory client config store, making them available to all request handlers.
   - From: `continuumSubscriptionFlowService` (configLoader_SubFlo)
   - To: `continuumSubscriptionFlowService` (Controller Layer, in-memory)
   - Protocol: internal

7. **Bootstrap Complete / Server Ready**: Bootstrap signals that initialisation is complete; Express router begins accepting requests.
   - From: `continuumSubscriptionFlowService` (bootstrap)
   - To: `continuumSubscriptionFlowService` (Express Router)
   - Protocol: process lifecycle

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GConfig Service unreachable at bootstrap | Config Loader falls back to hardcoded default configuration values | Service starts with defaults; experiment assignments unavailable; alert raised |
| GConfig returns malformed response | Config Loader logs error and uses defaults | Service starts with defaults; feature flags at default state |
| Periodic refresh fails | Retain previously loaded config; log warning | Service continues with potentially stale config until next successful refresh |

## Sequence Diagram

```
bootstrap -> configLoader_SubFlo: initiate config load
configLoader_SubFlo -> gconfigService_4b3a: GET /config/subscription_flow
gconfigService_4b3a --> configLoader_SubFlo: config payload (flags, experiments)
configLoader_SubFlo -> configLoader_SubFlo: resolve experiment variants
configLoader_SubFlo -> continuumSubscriptionFlowService: set in-memory client bindings
bootstrap -> continuumSubscriptionFlowService: bootstrap complete; start accepting requests
```

## Related

- Architecture dynamic view: `dynamic-config-and-experiment-loading`
- Related flows: [Subscription Modal Render](subscription-modal-render.md)
