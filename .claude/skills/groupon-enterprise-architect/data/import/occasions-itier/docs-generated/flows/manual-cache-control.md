---
service: "occasions-itier"
title: "Manual Cache Control"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "manual-cache-control"
flow_type: synchronous
trigger: "Operator HTTP GET or POST to /cachecontrol"
participants:
  - "Operator"
  - "continuumOccasionsItier"
  - "continuumOccasionsMemcached"
architecture_ref: "dynamic-occasion-request-flow"
---

# Manual Cache Control

## Summary

This flow allows operators to inspect and manually flush the Occasions ITA caches without restarting the service. A `GET /cachecontrol` request displays the current cache state and available actions. A `POST /cachecontrol` triggers immediate invalidation of Memcached campaign and/or deal cache entries, causing subsequent requests to re-fetch from upstream services. This is used after emergency campaign configuration changes or when stale data is observed in production.

## Trigger

- **Type**: manual
- **Source**: Operator HTTP request to `GET /cachecontrol` (inspect) or `POST /cachecontrol` (flush)
- **Frequency**: On-demand; not scheduled

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates cache inspection or flush via HTTP | — |
| Occasions ITA | Handles cache control requests; executes flush if instructed | `continuumOccasionsItier` |
| Occasions Memcached | Target of cache flush operations | `continuumOccasionsMemcached` |

## Steps

### Inspect (GET)

1. **Receives inspect request**: Operator sends `GET /cachecontrol` to `continuumOccasionsItier`.
   - From: `Operator`
   - To: `continuumOccasionsItier`
   - Protocol: REST / HTTPS

2. **Reads current cache state**: Queries `continuumOccasionsMemcached` for cache key inventory and entry metadata.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

3. **Returns cache status page**: Responds with an HTML page summarizing current cache state and available flush actions.
   - From: `continuumOccasionsItier`
   - To: `Operator`
   - Protocol: REST / HTTPS (HTML response)

### Flush (POST)

1. **Receives flush request**: Operator sends `POST /cachecontrol` with flush parameters to `continuumOccasionsItier`.
   - From: `Operator`
   - To: `continuumOccasionsItier`
   - Protocol: REST / HTTPS

2. **Validates request**: Verifies operator authorization and validates flush parameters.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsItier` (internal)
   - Protocol: direct (in-process)

3. **Flushes Memcached entries**: Deletes targeted campaign config and/or deal response cache entries from `continuumOccasionsMemcached` using `itier-cached`.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

4. **Triggers immediate poll (optional)**: Depending on implementation, may immediately invoke the Campaign Service poller to re-populate caches without waiting for the 1800-second interval.
   - From: `continuumOccasionsItier`
   - To: Campaign Service (ArrowHead)
   - Protocol: REST / HTTPS

5. **Returns confirmation**: Responds with success status confirming which cache entries were flushed.
   - From: `continuumOccasionsItier`
   - To: `Operator`
   - Protocol: REST / HTTPS (HTML/JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Operator not authorized | Request rejected with 403 | Cache unchanged |
| Memcached unavailable during flush | Log error; return partial failure response | Some or all entries not flushed |
| Campaign Service unavailable after flush | Log error; in-process data may be stale | Next scheduled poll will repopulate when service recovers |

## Sequence Diagram

```
Operator -> continuumOccasionsItier: POST /cachecontrol (flush request)
continuumOccasionsItier -> continuumOccasionsItier: Validate authorization
continuumOccasionsItier -> continuumOccasionsMemcached: Delete targeted cache entries
continuumOccasionsMemcached --> continuumOccasionsItier: Flush confirmation
continuumOccasionsItier --> Operator: Flush success response
```

## Related

- Architecture dynamic view: `dynamic-occasion-request-flow`
- Related flows: [Cache Refresh Background](cache-refresh-background.md), [Occasion Page Render](occasion-page-render.md)
