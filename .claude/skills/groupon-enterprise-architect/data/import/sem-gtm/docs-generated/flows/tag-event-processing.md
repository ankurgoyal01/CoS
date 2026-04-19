---
service: "sem-gtm"
title: "Tag Event Processing"
generated: "2026-03-03"
type: flow
flow_name: "tag-event-processing"
flow_type: synchronous
trigger: "HTTP request from a web browser or Groupon application sending tag data to the server-side GTM endpoint"
participants:
  - "continuumSemGtmTaggingServer"
  - "gtmApiUnknown_ab3a36"
architecture_ref: "dynamic-semGtmTagEventProcessing"
---

# Tag Event Processing

## Summary

When a Groupon web or app client fires a tag event (e.g., page view, purchase conversion, click), it sends an HTTP request to the server-side GTM tagging server instead of directly to third-party tag destinations. The tagging server (`continuumSemGtmTaggingServer`) receives the payload, executes the configured GTM tag logic within the Google-managed runtime, and forwards processed data to tag destinations (Google Analytics, Google Ads, etc.) via the GTM Cloud API. This server-side model removes tag execution from the browser, improving performance and privacy compliance.

## Trigger

- **Type**: api-call
- **Source**: Web browser or Groupon mobile/web application sending an HTTP tag event payload
- **Frequency**: Per user interaction (on-demand) — high frequency in production (supports up to 6 replicas with HPA target utilization 100%)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon web/app client | Initiates tag event; sends HTTP payload to tagging server | External (not in sem-gtm model) |
| GTM Tagging Server | Receives tag event, executes GTM tag logic, routes to destinations | `continuumSemGtmTaggingServer` |
| Google Tag Manager Cloud API | Provides tag execution runtime; receives forwarded event data | `gtmApiUnknown_ab3a36` (stub) |

## Steps

1. **Receive tag event**: Web or app client sends an HTTP request to the tagging server on port 8080
   - From: Groupon web/app client
   - To: `continuumSemGtmTaggingServer`
   - Protocol: HTTP/HTTPS

2. **Execute GTM tag logic**: The GTM Cloud runtime within the tagging server evaluates the incoming event against configured triggers and tags in the GTM workspace (loaded via `CONTAINER_CONFIG`)
   - From: `continuumSemGtmTaggingServer` (internal runtime)
   - To: `continuumSemGtmTaggingServer` (internal runtime)
   - Protocol: In-process

3. **Forward processed data to tag destinations**: The GTM runtime sends the processed event to configured tag destinations (e.g., Google Analytics 4, Google Ads) via the GTM Cloud API
   - From: `continuumSemGtmTaggingServer`
   - To: `gtmApiUnknown_ab3a36` (Google Tag Manager Cloud API)
   - Protocol: HTTPS

4. **Return response to client**: The tagging server returns an HTTP response to the originating client
   - From: `continuumSemGtmTaggingServer`
   - To: Groupon web/app client
   - Protocol: HTTP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GTM Cloud API unreachable | GTM Cloud image internal retry (behavior governed by image internals, not Groupon code) | Event may be lost; no Groupon-side DLQ or retry queue |
| Pod crash / liveness probe failure | Kubernetes restarts the pod; HPA maintains minimum 3 replicas to ensure availability | In-flight requests lost; other replicas continue serving |
| Invalid tag payload | GTM runtime rejects or ignores malformed events per GTM configuration | Client receives error response; event not forwarded |
| HPA at max replicas under heavy load | Requests queue or are shed by load balancer | Potential event loss under extreme load |

## Sequence Diagram

```
Client -> continuumSemGtmTaggingServer: POST /[gtm-route] (tag event payload)
continuumSemGtmTaggingServer -> continuumSemGtmTaggingServer: Execute GTM tag logic (in-process, using CONTAINER_CONFIG workspace)
continuumSemGtmTaggingServer -> gtmApiUnknown_ab3a36: Forward processed event to tag destinations (HTTPS)
gtmApiUnknown_ab3a36 --> continuumSemGtmTaggingServer: Acknowledgement
continuumSemGtmTaggingServer --> Client: HTTP 200 OK
```

## Related

- Architecture dynamic view: `dynamic-semGtmTagEventProcessing`
- Related flows: [Container Startup and Configuration Load](container-startup.md), [Preview Session Debugging](preview-session-debugging.md)
