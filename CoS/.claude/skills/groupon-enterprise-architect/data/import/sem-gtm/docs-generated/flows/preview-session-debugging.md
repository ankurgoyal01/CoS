---
service: "sem-gtm"
title: "Preview Session Debugging"
generated: "2026-03-03"
type: flow
flow_name: "preview-session-debugging"
flow_type: synchronous
trigger: "Tag engineer initiates a debug/preview session from the Google Tag Manager UI against the deployed preview server"
participants:
  - "continuumSemGtmPreviewServer"
  - "continuumSemGtmTaggingServer"
  - "gtmApiUnknown_ab3a36"
architecture_ref: "dynamic-semGtmPreviewSession"
---

# Preview Session Debugging

## Summary

Before publishing tag configuration changes to production in Google Tag Manager, tag engineers use the GTM preview/debug mode to validate their changes against live web traffic. The GTM UI instructs the browser to route tag requests through the deployed preview server (`continuumSemGtmPreviewServer`) instead of the tagging server, allowing engineers to inspect tag firing, data layer values, and trigger evaluation without affecting production data. The preview server runs as a single-replica fixed deployment (min 1, max 1) since it serves only human-initiated debug sessions.

## Trigger

- **Type**: user-action
- **Source**: Tag engineer clicking "Preview" in the Google Tag Manager UI console
- **Frequency**: On-demand (low frequency; serves only tag engineers)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Tag Engineer | Initiates debug session via GTM UI | External actor |
| Google Tag Manager UI | Orchestrates the preview session; injects debug cookies/headers into the browser | External (GTM SaaS) |
| GTM Preview Server | Hosts the preview session runtime; receives debug requests and returns configuration validation results | `continuumSemGtmPreviewServer` |
| GTM Tagging Server | Receives tag event requests from the browser during the preview session (with debug context attached) | `continuumSemGtmTaggingServer` |
| Google Tag Manager Cloud API | Provides preview session management and tag configuration state | `gtmApiUnknown_ab3a36` (stub) |

## Steps

1. **Initiate preview session**: Tag engineer clicks "Preview" in GTM UI for a container workspace; GTM UI communicates with the GTM Cloud API to start a preview session
   - From: Tag engineer (GTM UI)
   - To: `gtmApiUnknown_ab3a36` (Google Tag Manager Cloud API)
   - Protocol: HTTPS

2. **Inject debug context into browser**: GTM UI instructs the browser to send debug requests to the preview server URL (`https://gtm.groupon.com/preview/`)
   - From: GTM UI
   - To: Tag engineer's browser
   - Protocol: In-browser

3. **Browser sends tag event to tagging server with debug token**: Web page fires a tag event; the browser attaches a debug session token (set by GTM preview mode) and the tagging server routes it to the preview server via `PREVIEW_SERVER_URL`
   - From: Tag engineer's browser
   - To: `continuumSemGtmTaggingServer`
   - Protocol: HTTP/HTTPS

4. **Tagging server delegates to preview server**: The tagging server detects the debug session token and forwards the request to `continuumSemGtmPreviewServer` at `https://gtm.groupon.com/preview/`
   - From: `continuumSemGtmTaggingServer`
   - To: `continuumSemGtmPreviewServer`
   - Protocol: HTTPS

5. **Preview server evaluates tag configuration**: The preview server processes the event against the unpublished workspace configuration, evaluating which tags and triggers would fire
   - From: `continuumSemGtmPreviewServer` (internal runtime)
   - To: `continuumSemGtmPreviewServer` (internal runtime)
   - Protocol: In-process

6. **Return debug results to GTM UI**: The preview server sends evaluation results back through the chain to the GTM debug panel in the tag engineer's browser
   - From: `continuumSemGtmPreviewServer`
   - To: Tag engineer's browser (GTM debug panel)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Preview server pod unavailable | No fallback — preview server runs as a single replica (min 1, max 1) | Debug session fails; production tagging unaffected |
| Invalid/expired debug session token | GTM runtime rejects the request | Debug session terminates; engineer must restart preview from GTM UI |
| Tagging server cannot reach preview server | HTTPS connection failure to `PREVIEW_SERVER_URL` | Debug routing fails; normal (non-debug) tag events continue processing |

## Sequence Diagram

```
TagEngineer -> GTMUi: Click "Preview" for workspace
GTMUi -> gtmApiUnknown_ab3a36: Start preview session (HTTPS)
gtmApiUnknown_ab3a36 --> GTMUi: Session token
GTMUi -> Browser: Inject debug session token
Browser -> continuumSemGtmTaggingServer: Tag event request with debug token (HTTPS)
continuumSemGtmTaggingServer -> continuumSemGtmPreviewServer: Forward debug request to PREVIEW_SERVER_URL (HTTPS)
continuumSemGtmPreviewServer -> continuumSemGtmPreviewServer: Evaluate tag configuration
continuumSemGtmPreviewServer --> continuumSemGtmTaggingServer: Debug evaluation results
continuumSemGtmTaggingServer --> Browser: Response
Browser -> GTMUi: Display debug panel results
```

## Related

- Architecture dynamic view: `dynamic-semGtmPreviewSession`
- Related flows: [Tag Event Processing](tag-event-processing.md), [Container Startup and Configuration Load](container-startup.md)
