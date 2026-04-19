---
service: "subscription_flow"
title: "Subscription Modal Render"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "subscription-modal-render"
flow_type: synchronous
trigger: "HTTP GET request from web client or upstream aggregation layer"
participants:
  - "continuumSubscriptionFlowService"
  - "continuumApiLazloService"
  - "grouponV2Api_2d1e"
architecture_ref: "dynamic-subscription-modal-render"
---

# Subscription Modal Render

## Summary

When a Groupon web page needs to display a subscription acquisition modal, it sends an HTTP GET request to Subscription Flow. The service routes the request through its middleware stack, delegates to the appropriate controller, fetches any required user context or legacy subscription data from downstream services, then runs the renderer pipeline to produce the HTML response. The entire flow is synchronous and completes within a single HTTP request/response cycle.

## Trigger

- **Type**: api-call
- **Source**: Groupon web client (browser) or upstream Groupon V2 API aggregation layer requesting subscription modal content
- **Frequency**: per-request (on-demand, once per user page load requiring the subscription modal)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Subscription Flow Service | Receives request; routes and renders modal HTML | `continuumSubscriptionFlowService` |
| Lazlo API Service | Provides legacy subscription data needed for modal content | `continuumApiLazloService` |
| Groupon V2 API | Provides user context (auth state, subscription status) for personalised rendering | `grouponV2Api_2d1e` |

## Steps

1. **Receive HTTP Request**: Web client sends GET request to the subscription modal endpoint.
   - From: Web client or Groupon V2 API aggregation layer
   - To: `continuumSubscriptionFlowService`
   - Protocol: REST / HTTP

2. **Apply Fingerprint Middleware**: Fingerprint Middleware normalises request context (device type, locale, session identifiers).
   - From: `continuumSubscriptionFlowService` (Router)
   - To: `continuumSubscriptionFlowService` (Fingerprint Middleware)
   - Protocol: internal

3. **Apply Groupon Middleware**: Groupon Middleware enriches request with authentication context and standard Groupon request metadata.
   - From: `continuumSubscriptionFlowService` (Router)
   - To: `continuumSubscriptionFlowService` (Groupon Middleware)
   - Protocol: internal

4. **Route to Controller**: Router dispatches the enriched request to the appropriate subscription flow controller.
   - From: `continuumSubscriptionFlowService` (Router)
   - To: `continuumSubscriptionFlowService` (Controller Layer)
   - Protocol: internal

5. **Fetch User Context**: Controller fetches user authentication state and subscription status from Groupon V2 API.
   - From: `continuumSubscriptionFlowService`
   - To: `grouponV2Api_2d1e`
   - Protocol: REST / HTTP

6. **Fetch Legacy Subscription Data**: Controller fetches required subscription data from Lazlo API Service.
   - From: `continuumSubscriptionFlowService`
   - To: `continuumApiLazloService`
   - Protocol: REST / HTTP

7. **Load Config and Experiment Variant**: Controller reads the active GConfig-derived configuration (loaded at bootstrap) to determine which modal variant to render.
   - From: `continuumSubscriptionFlowService` (Controller Layer)
   - To: `continuumSubscriptionFlowService` (Config Loader, in-memory)
   - Protocol: internal

8. **Execute Renderer Pipeline**: Controller invokes the Renderer Pipeline with the assembled data context; pipeline produces the HTML output.
   - From: `continuumSubscriptionFlowService` (Controller Layer)
   - To: `continuumSubscriptionFlowService` (Renderer Pipeline)
   - Protocol: internal

9. **Return HTML Response**: Service sends the rendered HTML back to the caller.
   - From: `continuumSubscriptionFlowService`
   - To: Web client or Groupon V2 API aggregation layer
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Groupon V2 API call fails | Render modal without user personalisation (unauthenticated view) | Degraded modal; user sees default subscription offer |
| Lazlo API call fails | Render modal with missing legacy data or return error page | Degraded or error modal returned to client |
| GConfig not loaded / stale | Fall back to default configuration values | Modal rendered with default variant; no A/B experiment applied |
| Renderer pipeline error | Express error handler returns 500 | Error page returned to client |

## Sequence Diagram

```
WebClient -> continuumSubscriptionFlowService: GET /subscription_flow/modal
continuumSubscriptionFlowService -> continuumSubscriptionFlowService: Fingerprint Middleware
continuumSubscriptionFlowService -> continuumSubscriptionFlowService: Groupon Middleware
continuumSubscriptionFlowService -> continuumSubscriptionFlowService: Router -> Controller Layer
continuumSubscriptionFlowService -> grouponV2Api_2d1e: GET /user/context
grouponV2Api_2d1e --> continuumSubscriptionFlowService: user context (auth state, subscription status)
continuumSubscriptionFlowService -> continuumApiLazloService: GET /subscription/data
continuumApiLazloService --> continuumSubscriptionFlowService: legacy subscription data
continuumSubscriptionFlowService -> continuumSubscriptionFlowService: load GConfig variant (in-memory)
continuumSubscriptionFlowService -> continuumSubscriptionFlowService: Renderer Pipeline -> HTML
continuumSubscriptionFlowService --> WebClient: 200 OK (rendered HTML)
```

## Related

- Architecture dynamic view: `dynamic-subscription-modal-render`
- Related flows: [Config and Experiment Loading](config-and-experiment-loading.md)
