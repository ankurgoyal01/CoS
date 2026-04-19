---
service: "janus-engine"
title: "Curator Metadata Refresh"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "curator-metadata-refresh"
flow_type: scheduled
trigger: "Service startup and periodic cache refresh"
participants:
  - "continuumJanusEngine"
  - "janusOrchestrator"
  - "curationProcessor"
  - "janusMetadataClientComponent"
architecture_ref: "components-janusEngineComponents"
---

# Curator Metadata Refresh

## Summary

Before any event curation can occur, Janus Engine must load mapper definitions and routing rules from the Janus metadata service. The `janusMetadataClientComponent` performs an HTTP fetch (via curator-api 0.0.41) on startup and caches the results in-process. Subsequent curation requests by `curationProcessor` are served from this in-memory cache. The cache is refreshed periodically to pick up updated mapper definitions without requiring a service restart.

## Trigger

- **Type**: schedule / lifecycle
- **Source**: Service startup (driven by `janusOrchestrator`) and periodic background refresh (driven by `janusMetadataClientComponent`)
- **Frequency**: Once on startup; then on a scheduled refresh interval (interval configuration managed externally)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Janus Engine Application (Orchestrator) | Bootstraps the service; triggers initial metadata load | `janusOrchestrator` |
| Curator Processor | Consumes cached metadata for per-event curation decisions | `curationProcessor` |
| Janus Metadata Client | Fetches mapper/rules from metadata service; manages in-memory cache | `janusMetadataClientComponent` |
| Janus metadata service | External HTTP service providing mapper definitions and routing rules | External (Janus web cloud production service) |

## Steps

1. **Bootstrap metadata load**: `janusOrchestrator` starts up and initializes `janusMetadataClientComponent`, triggering the initial metadata fetch.
   - From: `janusOrchestrator`
   - To: `janusMetadataClientComponent`
   - Protocol: direct

2. **Fetch mapper definitions and rules**: `janusMetadataClientComponent` makes an HTTP request to the Janus metadata service to retrieve all mapper definitions and curation routing rules.
   - From: `janusMetadataClientComponent`
   - To: Janus metadata service (`janus.web.cloud.production.service`)
   - Protocol: HTTP (curator-api 0.0.41)

3. **Populate in-memory cache**: `janusMetadataClientComponent` stores the retrieved mapper definitions and rules in the in-process cache, keyed by source topic and event type.
   - From: Janus metadata service response
   - To: `janusMetadataClientComponent` in-memory cache
   - Protocol: direct

4. **Serve curation requests**: `curationProcessor` queries `janusMetadataClientComponent` for the mapper definition matching each incoming event's source topic and event type; the cache responds without an outbound HTTP call.
   - From: `curationProcessor`
   - To: `janusMetadataClientComponent` (cache lookup)
   - Protocol: direct

5. **Periodic refresh**: On the configured refresh interval, `janusMetadataClientComponent` repeats steps 2-3 to update the cache with any new or changed mapper definitions, without interrupting ongoing event processing.
   - From: `janusMetadataClientComponent` (scheduled)
   - To: Janus metadata service
   - Protocol: HTTP (curator-api 0.0.41)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Metadata service unavailable on startup | Startup may fail or proceed with empty/partial cache | No event curation possible if cache is empty; service owner must ensure metadata service availability before deploying |
| Metadata service unavailable during refresh | Previous cached data continues to be served | Curation continues with stale mappers; events may be misrouted if schema has changed; stale-metadata alert should fire |
| Mapper definition not found for event type | Cache returns null / miss | `curationProcessor` cannot curate the event; event is skipped or routed to DLQ |
| HTTP timeout | curator-api timeout handling | Refresh skipped; next interval retry; cached data continues to serve |

## Sequence Diagram

```
janusOrchestrator            -> janusMetadataClientComponent : Initialize metadata client (startup)
janusMetadataClientComponent -> Janus metadata service       : GET /mappers (fetch all mapper definitions and rules)
Janus metadata service       --> janusMetadataClientComponent : Returns mapper definitions and routing rules
janusMetadataClientComponent -> in-memory cache              : Stores mapper definitions keyed by (topic, event type)
curationProcessor            -> janusMetadataClientComponent : Lookup mapper for (source topic, event type)
janusMetadataClientComponent --> curationProcessor           : Returns mapper definition and routing tier
[periodic refresh]
janusMetadataClientComponent -> Janus metadata service       : GET /mappers (refresh)
Janus metadata service       --> janusMetadataClientComponent : Returns updated mapper definitions
janusMetadataClientComponent -> in-memory cache              : Updates cache entries
```

## Related

- Architecture dynamic view: `components-janusEngineComponents`
- Related flows: [Kafka Stream Curation](kafka-stream-curation.md), [MBus Bridge Curation](mbus-bridge-curation.md), [DLQ Replay](dlq-replay.md)
