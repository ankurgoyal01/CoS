---
service: "garvis"
title: "On-Call Lookup and Notification"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "on-call-lookup-notification"
flow_type: synchronous
trigger: "Google Chat command (@Jarvis oncall <service>)"
participants:
  - "continuumJarvisBot"
  - "continuumJarvisRedis"
  - "googlePubSub"
  - "googleChatApi"
architecture_ref: "dynamic-onCallLookup"
---

# On-Call Lookup and Notification

## Summary

The On-Call Lookup and Notification flow allows any engineer to query the current on-call person for a given service or team directly from Google Chat. Garvis receives the lookup command via Pub/Sub, queries PagerDuty for the active on-call schedule, and returns the current on-call engineer's name and contact details as a Chat message. The flow can also send a direct notification to the on-call engineer if requested.

## Trigger

- **Type**: event (chat command)
- **Source**: Any engineer sends `@Jarvis oncall <service-name>` in a Google Chat space
- **Frequency**: On demand (per lookup request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Cloud Pub/Sub | Delivers the Google Chat message to the bot | `googlePubSub` |
| Jarvis Bot | Receives, parses, and handles the on-call lookup command | `continuumJarvisBot` |
| Jarvis Redis | Optionally caches PagerDuty lookup results to reduce API calls | `continuumJarvisRedis` |
| PagerDuty | Provides on-call schedule data for the queried service | External (pdpyras) |
| Google Chat API | Returns the on-call result and optional notification to the user | `googleChatApi` |

## Steps

1. **Receives on-call lookup command**: Engineer sends `@Jarvis oncall <service-name>` in Google Chat.
   - From: Google Chat user
   - To: `googlePubSub` (Google Chat delivers event to configured Pub/Sub topic)
   - Protocol: Google Chat event push to Pub/Sub

2. **Consumes Pub/Sub event**: `botPubSubSubscriber` in `continuumJarvisBot` receives the message.
   - From: `googlePubSub`
   - To: `continuumJarvisBot`
   - Protocol: Google Pub/Sub streaming pull

3. **Routes on-call command**: `botCommandRouter` identifies the `oncall` command and passes it to `botPluginHandlers`.
   - From: `botPubSubSubscriber`
   - To: `botCommandRouter` → `botPluginHandlers`
   - Protocol: In-process (Python)

4. **Checks cache**: Plugin handler checks `continuumJarvisRedis` for a cached on-call result for the requested service (if caching is configured).
   - From: `continuumJarvisBot`
   - To: `continuumJarvisRedis`
   - Protocol: Redis GET

5. **Queries PagerDuty**: On cache miss, `botPluginHandlers` calls the PagerDuty API via `pdpyras` to retrieve the current on-call user for the matching schedule or escalation policy.
   - From: `continuumJarvisBot`
   - To: PagerDuty API
   - Protocol: HTTPS / REST (pdpyras)

6. **Caches result**: Plugin handler writes the PagerDuty result to `continuumJarvisRedis` with a short TTL to avoid redundant API calls.
   - From: `continuumJarvisBot`
   - To: `continuumJarvisRedis`
   - Protocol: Redis SET with TTL

7. **Sends on-call result**: `botChatClient` posts the on-call engineer's name and contact details to the requesting Google Chat space.
   - From: `continuumJarvisBot`
   - To: `googleChatApi`
   - Protocol: HTTPS / REST

8. **Sends notification (optional)**: If the user requested that the on-call engineer be notified (e.g., `@Jarvis ping oncall <service>`), `botChatClient` sends a direct message to the on-call engineer in Google Chat.
   - From: `continuumJarvisBot`
   - To: `googleChatApi`
   - Protocol: HTTPS / REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PagerDuty API unreachable | Plugin handler catches exception | Bot replies with an error message indicating PagerDuty is unavailable; no result returned |
| Service name not found in PagerDuty | PagerDuty returns empty schedule list | Bot replies with "no on-call schedule found for <service>" |
| Google Chat API error on reply | Exception raised in `botChatClient` | User sees no response; error logged; no retry |
| Redis cache write failure | Non-critical; plugin handler continues without caching | PagerDuty is queried on every subsequent request until cache is available |

## Sequence Diagram

```
Engineer -> GoogleChat: @Jarvis oncall <service-name>
GoogleChat -> googlePubSub: Push chat event
googlePubSub -> continuumJarvisBot: Deliver message (streaming pull)
continuumJarvisBot -> continuumJarvisBot: Route to oncall plugin handler
continuumJarvisBot -> continuumJarvisRedis: Check cache for service schedule
continuumJarvisRedis --> continuumJarvisBot: Cache miss (or hit)
continuumJarvisBot -> PagerDuty: GET /oncalls?schedule_ids=<id>
PagerDuty --> continuumJarvisBot: Return current on-call user
continuumJarvisBot -> continuumJarvisRedis: Cache result (TTL)
continuumJarvisBot -> googleChatApi: Post on-call result to Chat space
googleChatApi --> Engineer: On-call engineer name and contact
```

## Related

- Architecture dynamic view: `dynamic-onCallLookup` (not yet defined in DSL)
- Related flows: [Incident Response Orchestration](incident-response-orchestration.md)
