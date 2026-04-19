---
service: "deal-service"
title: "Dynamic Configuration Reload"
generated: "2026-03-02"
type: flow
flow_name: "dynamic-configuration-reload"
flow_type: event-driven
trigger: "Service startup + configUpdate event emitted by keldor-config"
participants:
  - "continuumDealService"
architecture_ref: "dynamic-dynamic-configuration-reload"
---

# Dynamic Configuration Reload

## Summary

Deal Service uses the `keldor-config` library (via the `configLoader_Dea` component) to load runtime feature flags at startup and to receive live configuration updates without redeployment. On startup, the worker loads the full configuration from the Keldor Config Service and stores it in a shared `gConfig` object. `configLoader_Dea` also registers a `configUpdate` event listener so that whenever keldor-config detects a change upstream, `gConfig` is updated in place. All processing components (`processDeal`, `redisScheduler`, `inventoryUpdatePublisher`, `notificationPublisher`) read from `gConfig` on each cycle, ensuring they always operate with the latest configuration values.

## Trigger

- **Type**: event
- **Source**: (1) Worker process startup; (2) `configUpdate` event from keldor-config when upstream config changes
- **Frequency**: Once at startup; then continuously as config changes propagate from the Keldor Config Service

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Service Worker (`configLoader_Dea`) | Loads config on startup; registers `configUpdate` listener; updates `gConfig` | `continuumDealService` |
| Keldor Config Service | Provides feature flag values; notifies on changes | `externalKeldorConfigApi_3f2e` (stub) |
| `gConfig` (in-process shared object) | Shared mutable config state read by all processing components | `continuumDealService` |

## Steps

1. **Worker starts**: The worker process initializes and calls `configLoader_Dea` to load configuration.
   - From: `continuumDealService` (worker startup)
   - To: `configLoader_Dea`
   - Protocol: in-process

2. **Fetches initial config from Keldor Config Service**: `configLoader_Dea` makes an outbound call to the Keldor Config Service at the URL specified by `KELDOR_CONFIG_SOURCE`.
   - From: `continuumDealService`
   - To: `externalKeldorConfigApi_3f2e`
   - Protocol: REST

3. **Populates gConfig**: Stores the retrieved configuration values in the shared `gConfig` object, including all `feature_flags.*` and `deal_option_inventory_update.*` keys.
   - From: `configLoader_Dea`
   - To: `gConfig` (in-process)
   - Protocol: in-process

4. **Registers configUpdate listener**: `configLoader_Dea` registers an event listener on the keldor-config client for `configUpdate` events.
   - From: `configLoader_Dea`
   - To: keldor-config client (in-process event emitter)
   - Protocol: in-process Node.js EventEmitter

5. **Processing components read gConfig**: On each polling cycle, `processDeal`, `redisScheduler`, `inventoryUpdatePublisher`, and `notificationPublisher` read their respective flags from `gConfig` (e.g., `feature_flags.processDeals.active`, `feature_flags.processDeals.limit`, `deal_option_inventory_update.mbus_producer.active`).
   - From: all processing components
   - To: `gConfig`
   - Protocol: in-process

6. **Config change detected (async)**: When the Keldor Config Service updates configuration values, keldor-config emits a `configUpdate` event.
   - From: `externalKeldorConfigApi_3f2e`
   - To: keldor-config client (in-process)
   - Protocol: polling / webhook (keldor-config library internal)

7. **gConfig updated in place**: The `configUpdate` listener in `configLoader_Dea` merges the new values into `gConfig`. No restart is required.
   - From: `configLoader_Dea` (event handler)
   - To: `gConfig`
   - Protocol: in-process

8. **Next processing cycle uses updated config**: On the next polling interval, all components read the updated values from `gConfig` and behave accordingly (e.g., new batch size, toggled flags).
   - From: processing components
   - To: `gConfig`
   - Protocol: in-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Keldor Config Service unavailable at startup | Service starts with default or last-known config values | Processing proceeds with defaults; may not reflect latest flags |
| Config update event not received | `gConfig` retains last-loaded values | Config drift until service restarts or next successful update event |
| Invalid config value received | Depends on keldor-config library behavior; no explicit handling evidenced | Processing components may use stale or default values |

## Sequence Diagram

```
Worker -> configLoader_Dea: initialize on startup
configLoader_Dea -> KeldorConfigService: GET config (KELDOR_CONFIG_SOURCE)
KeldorConfigService --> configLoader_Dea: feature flags + config values
configLoader_Dea -> gConfig: populate all config keys
configLoader_Dea -> keldorClient: register configUpdate listener
--- (each processing cycle) ---
processDeal -> gConfig: read feature_flags.processDeals.active
processDeal -> gConfig: read feature_flags.processDeals.limit
inventoryUpdatePublisher -> gConfig: read deal_option_inventory_update.mbus_producer.active
inventoryUpdatePublisher -> gConfig: read deal_option_inventory_update.mbus_producer.topic
--- (async, when config changes upstream) ---
KeldorConfigService -> keldorClient: configUpdate event
keldorClient -> configLoader_Dea: configUpdate handler fires
configLoader_Dea -> gConfig: merge updated values
```

## Related

- Architecture dynamic view: `dynamic-dynamic-configuration-reload`
- Related flows: [Deal Processing Cycle](deal-processing-cycle.md), [Worker Process Restart](worker-process-restart.md)
