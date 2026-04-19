---
service: "layout-service"
title: "Context Composition Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "context-composition"
flow_type: synchronous
trigger: "Inbound HTTP layout request carrying locale, market, and user/session signals"
participants:
  - "layoutSvc_httpApi"
  - "layoutSvc_requestComposer"
  - "layoutSvc_templateRenderer"
architecture_ref: "dynamic-layout-service-request-flow"
---

# Context Composition Flow

## Summary

Before a Mustache template can be rendered, Layout Service must assemble a complete rendering context from the inbound HTTP request. The Request Composition component extracts locale, market, user session, and feature signals from request headers and parameters, normalizes them into a structured context object, and passes that object to the Template Renderer. This flow ensures that every layout response is correctly localized, market-specific, and personalized to the current user's session state.

## Trigger

- **Type**: api-call (sub-flow triggered at the start of every layout request, after routing by `layoutSvc_httpApi`)
- **Source**: `layoutSvc_httpApi` — delegates to `layoutSvc_requestComposer` immediately after receiving a valid inbound request
- **Frequency**: Per layout request — runs on every call to `/layout/*`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API Endpoints | Initiator — receives the HTTP request and delegates context assembly | `layoutSvc_httpApi` |
| Request Composition | Context builder — extracts and normalizes locale, market, user, and feature context | `layoutSvc_requestComposer` |
| Template Renderer | Consumer — receives the assembled context and uses it to render the layout template | `layoutSvc_templateRenderer` |

## Steps

1. **Receives inbound HTTP request**: HTTP API Endpoints accept the GET `/layout/*` request and extract raw request data (headers, query parameters, cookies) for context assembly.
   - From: I-tier Frontend App
   - To: `layoutSvc_httpApi`
   - Protocol: REST (HTTP)

2. **Delegates to Request Composition**: HTTP API Endpoints pass the request object to Request Composition to build the rendering context.
   - From: `layoutSvc_httpApi`
   - To: `layoutSvc_requestComposer`
   - Protocol: direct (in-process)

3. **Extracts locale context**: Request Composition reads the locale identifier from the `Accept-Language` header, URL path, or query parameter and normalizes it to the canonical Groupon locale format (e.g., `en-US`, `de-DE`).
   - From: `layoutSvc_requestComposer`
   - To: `layoutSvc_requestComposer` (internal extraction)
   - Protocol: direct

4. **Extracts market context**: Request Composition identifies the target market/division from request routing metadata (path prefix, host header, or forwarded headers set by the i-tier gateway).
   - From: `layoutSvc_requestComposer`
   - To: `layoutSvc_requestComposer` (internal extraction)
   - Protocol: direct

5. **Extracts user and session context**: Request Composition reads user session signals (authenticated vs. guest, user preferences relevant to navigation) from cookies or forwarded session headers.
   - From: `layoutSvc_requestComposer`
   - To: `layoutSvc_requestComposer` (internal extraction)
   - Protocol: direct

6. **Assembles and validates context object**: Request Composition combines all extracted signals into a single context object, applies defaults for missing optional fields, and validates that required fields (locale, market) are present and well-formed.
   - From: `layoutSvc_requestComposer`
   - To: `layoutSvc_requestComposer` (internal validation)
   - Protocol: direct

7. **Passes context to Template Renderer**: Request Composition delivers the assembled context object to Template Renderer for use during Mustache template evaluation.
   - From: `layoutSvc_requestComposer`
   - To: `layoutSvc_templateRenderer`
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required locale | `layoutSvc_requestComposer` applies default locale (e.g., `en-US`) or returns HTTP 400 for unresolvable locale | Layout rendered with default locale, or request rejected with error |
| Missing market identifier | `layoutSvc_requestComposer` applies default market based on request host, or returns HTTP 400 | Layout rendered with default market, or request rejected with error |
| Malformed session/cookie data | User context treated as guest/unauthenticated; rendering continues | Layout rendered as guest experience; no error surfaced to caller |
| Context assembly throws exception | Exception propagated to `layoutSvc_httpApi`; HTTP 500 returned | Layout response unavailable for this request |

## Sequence Diagram

```
I-tier App                   -> layoutSvc_httpApi:         GET /layout/* (headers, cookies, params)
layoutSvc_httpApi            -> layoutSvc_requestComposer: Delegate context assembly
layoutSvc_requestComposer    -> layoutSvc_requestComposer: Extract locale from Accept-Language / URL
layoutSvc_requestComposer    -> layoutSvc_requestComposer: Extract market from host / path headers
layoutSvc_requestComposer    -> layoutSvc_requestComposer: Extract user/session from cookies/headers
layoutSvc_requestComposer    -> layoutSvc_requestComposer: Assemble and validate context object
layoutSvc_requestComposer    --> layoutSvc_templateRenderer: Assembled rendering context
```

## Related

- Architecture dynamic view: `dynamic-layout-service-request-flow`
- Related flows: [Layout Request Flow](layout-request-flow.md), [Asset Resolution Flow](asset-resolution.md), [Template Cache Miss Flow](template-cache-miss.md)
