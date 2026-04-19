---
service: "mbus-sigint-frontend"
title: "Configuration Browse"
generated: "2026-03-03"
type: flow
flow_name: "configuration-browse"
flow_type: synchronous
trigger: "User selects a MessageBus cluster to browse its current configuration"
participants:
  - "sigintReactUi"
  - "sigintBackendApiProxy"
  - "continuumMbusSigintConfigurationService"
architecture_ref: "components-continuum-mbus-sigint-frontend"
---

# Configuration Browse

## Summary

Engineers can browse the live configuration of any MessageBus cluster through the Configuration module. After selecting a cluster from the dropdown (populated during SPA bootstrap), the SPA fetches the full cluster configuration and displays tabbed panels for destinations, credentials, and diverts. Clicking into any individual item fetches its detailed config entry from `mbus-sigint-config`. All requests are proxied through the Node.js backend.

## Trigger

- **Type**: user-action
- **Source**: Engineer selects a cluster in the cluster selector dropdown within the `/configuration` route
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (Groupon engineer) | Selects cluster; navigates configuration panels | — |
| `sigintReactUi` | Issues API calls on cluster selection and item drill-down; renders tabular panels | `sigintReactUi` |
| `sigintBackendApiProxy` | Forwards all configuration read requests to upstream | `sigintBackendApiProxy` |
| `continuumMbusSigintConfigurationService` | Returns cluster configuration and individual item details | `continuumMbusSigintConfigurationService` |

## Steps

1. **Select cluster**: Engineer selects a cluster from the cluster selector. The cluster list was pre-loaded during SPA bootstrap and stored in Redux.
   - From: Browser
   - To: `sigintReactUi` (Redux dispatch)
   - Protocol: Direct

2. **Fetch cluster configuration**: `sigintReactUi` calls `GET /api/mbus-sigint-config/config/{cluster}` for the selected cluster ID.
   - From: `sigintReactUi`
   - To: `sigintBackendApiProxy`
   - Protocol: HTTPS/JSON

3. **Proxy and return cluster config**: The proxy forwards to `continuumMbusSigintConfigurationService` at `GET /config/{cluster}` and returns the full configuration object including destinations, credentials, and diverts lists.
   - From: `sigintBackendApiProxy`
   - To: `continuumMbusSigintConfigurationService`
   - Protocol: HTTPS/JSON

4. **Render configuration panels**: `sigintReactUi` renders tabbed panels (Destinations, Credentials, Diverts) with the returned data.
   - From: `sigintReactUi`
   - To: Browser DOM
   - Protocol: Direct

5. **Drill into destination details**: Engineer clicks a destination name. `sigintReactUi` calls `GET /api/mbus-sigint-config/config/{cluster}/destination/{destinationName}` and `GET /api/mbus-sigint-config/config/{cluster}/config-entry/destination/{destinationName}`.
   - From: `sigintReactUi`
   - To: `sigintBackendApiProxy`
   - Protocol: HTTPS/JSON

6. **Drill into credential details**: Engineer clicks a credential role. `sigintReactUi` calls `GET /api/mbus-sigint-config/config/{cluster}/credential/{role}`.
   - From: `sigintReactUi`
   - To: `sigintBackendApiProxy`
   - Protocol: HTTPS/JSON

7. **Drill into divert details**: Engineer clicks a divert name. `sigintReactUi` calls `GET /api/mbus-sigint-config/config/{cluster}/config-entry/divert/{divertName}`.
   - From: `sigintReactUi`
   - To: `sigintBackendApiProxy`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cluster config load fails | HTTP error propagated to SPA | Configuration panels empty; user sees error state |
| Destination/credential/divert detail load fails | HTTP error propagated to SPA | Detail panel shows error; list remains visible |
| `mbus-sigint-config` unavailable | Gofer timeout (10s browser-side, Gofer server-side) | All panels fail to load |

## Sequence Diagram

```
Browser -> sigintReactUi: Select cluster "my-cluster"
sigintReactUi -> sigintBackendApiProxy: GET /api/mbus-sigint-config/config/my-cluster
sigintBackendApiProxy -> continuumMbusSigintConfigurationService: GET /config/my-cluster
continuumMbusSigintConfigurationService --> sigintBackendApiProxy: 200 { destinations, credentials, diverts }
sigintBackendApiProxy --> sigintReactUi: 200 cluster config
sigintReactUi --> Browser: Render Destinations/Credentials/Diverts tabs
Browser -> sigintReactUi: Click destination "my-topic"
sigintReactUi -> sigintBackendApiProxy: GET /api/mbus-sigint-config/config/my-cluster/destination/my-topic
sigintBackendApiProxy -> continuumMbusSigintConfigurationService: GET /config/my-cluster/destination/my-topic
continuumMbusSigintConfigurationService --> sigintBackendApiProxy: 200 destination details
sigintBackendApiProxy --> sigintReactUi: 200 destination details
sigintReactUi --> Browser: Render destination detail panel
```

## Related

- Architecture dynamic view: `dynamic-configuration-change-flow`
- Related flows: [SPA Bootstrap](spa-bootstrap.md), [Configuration Change Request](configuration-change-request.md)
