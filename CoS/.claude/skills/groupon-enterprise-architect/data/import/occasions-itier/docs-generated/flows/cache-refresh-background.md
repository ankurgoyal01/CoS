---
service: "occasions-itier"
title: "Cache Refresh Background"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "cache-refresh-background"
flow_type: scheduled
trigger: "Internal timer fires every 1800 seconds after service startup"
participants:
  - "continuumOccasionsItier"
  - "continuumOccasionsMemcached"
architecture_ref: "dynamic-occasion-request-flow"
---

# Cache Refresh Background

## Summary

This flow is a background scheduled task running inside `continuumOccasionsItier`. Every 1800 seconds, the Campaign Service poller (powered by `itier-campaign-service-client`) calls Campaign Service (ArrowHead) to retrieve fresh occasion configurations, division mappings, and merchandising themes. Results are written to both the Node.js in-process memory maps and `continuumOccasionsMemcached`, ensuring all request handlers serve up-to-date occasion data without polling upstream on every request.

## Trigger

- **Type**: schedule
- **Source**: Internal timer within `continuumOccasionsItier` process (managed by `itier-campaign-service-client`)
- **Frequency**: Every 1800 seconds (30 minutes); also runs once on service startup

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Occasions ITA (poller task) | Executes the poll cycle; writes results to memory and Memcached | `continuumOccasionsItier` |
| Campaign Service (ArrowHead) | Source of truth for occasion configs, division maps, and themes | — |
| Occasions Memcached | Receives updated serialized campaign config entries | `continuumOccasionsMemcached` |

## Steps

1. **Timer fires**: Internal scheduler triggers the Campaign Service poll cycle after a 1800-second interval (or on service startup).
   - From: `continuumOccasionsItier` (internal timer)
   - To: `continuumOccasionsItier` (poll handler)
   - Protocol: direct (in-process)

2. **Fetches occasion configurations**: Calls Campaign Service (ArrowHead) via `itier-campaign-service-client` to retrieve all active occasion configurations, visual themes, and division mappings.
   - From: `continuumOccasionsItier`
   - To: Campaign Service (ArrowHead)
   - Protocol: REST / HTTPS

3. **Updates in-process memory**: Writes the fresh division map, occasion theme map, and card permalink map into the Node.js in-process memory structures managed by `itier-divisions`.
   - From: `continuumOccasionsItier` (poll handler)
   - To: `continuumOccasionsItier` (in-process memory)
   - Protocol: direct (in-process)

4. **Updates Memcached entries**: Serializes fresh campaign config payloads and writes them to `continuumOccasionsMemcached` using `itier-cached`, replacing or extending existing cache entries.
   - From: `continuumOccasionsItier`
   - To: `continuumOccasionsMemcached`
   - Protocol: Memcached binary protocol

5. **Schedules next poll**: Resets the internal timer for the next 1800-second interval.
   - From: `continuumOccasionsItier` (poll handler)
   - To: `continuumOccasionsItier` (internal timer)
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Campaign Service unavailable | Poll cycle fails silently; timer schedules next attempt in 1800s | Service continues to serve from stale in-process and Memcached data |
| Campaign Service returns malformed response | Error logged; in-process memory and Memcached not updated | Stale data remains in effect |
| Memcached write failure | Log error; in-process memory still updated | Subsequent requests may hit live upstream on Memcached miss |
| Process restart during poll | Poll restarts from scratch on next startup | Brief window of stale data until poll completes |

## Sequence Diagram

```
continuumOccasionsItier (timer) -> continuumOccasionsItier (poll handler): Timer fires (1800s interval)
continuumOccasionsItier -> CampaignService (ArrowHead): GET occasion configs, themes, divisions
CampaignService (ArrowHead) --> continuumOccasionsItier: Fresh configs
continuumOccasionsItier -> continuumOccasionsItier (in-process memory): Update division/theme/permalink maps
continuumOccasionsItier -> continuumOccasionsMemcached: Write updated campaign cache entries
continuumOccasionsItier (timer) -> continuumOccasionsItier (timer): Schedule next poll in 1800s
```

## Related

- Architecture dynamic view: `dynamic-occasion-request-flow`
- Related flows: [Occasion Page Render](occasion-page-render.md), [Manual Cache Control](manual-cache-control.md)
