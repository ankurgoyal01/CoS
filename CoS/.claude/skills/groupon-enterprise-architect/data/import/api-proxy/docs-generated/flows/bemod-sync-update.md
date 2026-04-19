---
service: "api-proxy"
title: "BEMOD Sync Update"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "bemod-sync-update"
flow_type: scheduled
trigger: "Periodic background timer (interval configured via BEMOD_SYNC_INTERVAL_MS)"
participants:
  - "apiProxy_bemodSync"
  - "apiProxy_routeConfigLoader"
architecture_ref: "dynamic-api-apiProxy_destinationProxy-request-processing"
---

# BEMOD Sync Update

## Summary

BEMOD Sync Update is a background maintenance flow that keeps API Proxy's behaviour-modification (BEMOD) routing overlays current. The BEMOD Sync worker periodically contacts the BASS Service (via the bass-client library) to fetch the latest set of marked, blacklisted, and whitelisted entries. Once retrieved and validated, the worker pushes the updated overlay data to the Route Config Loader, which applies it to the in-process routing state so the Filter Chain Engine can enforce BEMOD rules on subsequent requests.

## Trigger

- **Type**: schedule
- **Source**: Internal background timer (interval configured via `BEMOD_SYNC_INTERVAL_MS`)
- **Frequency**: Periodic (configurable interval)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| BEMOD Sync | Background worker; drives the entire sync cycle; calls BASS Service via bass-client | `apiProxy_bemodSync` |
| BASS Service | External data provider; holds authoritative marked/blacklisted/whitelisted BEMOD data | — (external; bass-client 0.1.24) |
| Route Config Loader | Receives updated BEMOD overlay data; applies it to the in-process routing and filter state | `apiProxy_routeConfigLoader` |

## Steps

1. **Background timer fires**: The BEMOD Sync worker's scheduler reaches the configured sync interval and initiates a new sync cycle.
   - From: Internal scheduler
   - To: `apiProxy_bemodSync`
   - Protocol: in-process

2. **Fetch BEMOD data from BASS**: BEMOD Sync calls the BASS Service endpoint using the bass-client 0.1.24 library to retrieve the current BEMOD dataset (marked, blacklisted, and whitelisted routing entries).
   - From: `apiProxy_bemodSync`
   - To: BASS Service (via `BASS_SERVICE_URL`)
   - Protocol: HTTPS (bass-client)

3. **Validate received BEMOD dataset**: BEMOD Sync parses and validates the response from BASS. If the response is empty, malformed, or indicates an error, the sync cycle is aborted and the existing in-process overlay is retained.
   - From: `apiProxy_bemodSync`
   - To: `apiProxy_bemodSync` (internal)
   - Protocol: direct (in-process)

4. **Push updated overlays to Route Config Loader**: BEMOD Sync passes the validated dataset to the Route Config Loader, which refreshes the BEMOD routing overlays in the in-process configuration cache.
   - From: `apiProxy_bemodSync`
   - To: `apiProxy_routeConfigLoader`
   - Protocol: direct (in-process)

5. **Route Config Loader applies BEMOD overlays**: Route Config Loader merges the new BEMOD data into the active routing configuration, making the updated marked/blacklisted/whitelisted rules available to the Filter Chain Engine for all subsequent requests.
   - From: `apiProxy_routeConfigLoader`
   - To: in-process route/filter cache
   - Protocol: direct (in-process)

6. **Emit sync metric**: BEMOD Sync increments the `api_proxy.bemod_sync.success` (or `bemod_sync.failure`) counter and emits a structured log entry.
   - From: `apiProxy_bemodSync`
   - To: `metricsStack`
   - Protocol: TCP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| BASS Service unreachable | Sync cycle aborted; connection error logged; `api_proxy.bemod_sync.failure` incremented | Existing in-process BEMOD overlay continues to serve; no routing disruption |
| BASS returns HTTP error (4xx/5xx) | Sync cycle aborted; response error logged | Existing overlay retained; retry on next scheduled cycle |
| Malformed BEMOD payload | Parsing/validation fails; dataset discarded | Existing overlay retained; warning logged |
| Partial BEMOD dataset (missing required lists) | Validation fails; dataset discarded | Existing overlay retained; warning logged |
| BEMOD Sync and Config Reload race condition | Route Config Loader serialises updates | Both updates applied sequentially; no data corruption |

## Sequence Diagram

```
Scheduler -> apiProxy_bemodSync: Timer fires (BEMOD_SYNC_INTERVAL_MS)
apiProxy_bemodSync -> BASSService: Fetch BEMOD data (HTTPS via bass-client)
BASSService --> apiProxy_bemodSync: BEMOD dataset (marked/blacklisted/whitelisted)
apiProxy_bemodSync -> apiProxy_bemodSync: Validate and parse dataset
apiProxy_bemodSync -> apiProxy_routeConfigLoader: Refresh BEMOD routing overlays
apiProxy_routeConfigLoader -> InProcessCache: Merge BEMOD overlays into route config
apiProxy_bemodSync -> metricsStack: Emit bemod_sync.success counter + structured log
```

## Related

- Architecture dynamic view: `dynamic-api-apiProxy_destinationProxy-request-processing`
- Related flows: [Config Reload](config-reload.md), [Request Routing](request-routing.md)
