---
service: "content-pages"
title: "Error Page Rendering Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "error-page-rendering"
flow_type: synchronous
trigger: "An HTTP error condition occurs (404, 500, etc.)"
participants:
  - "continuumContentPagesService"
  - "errorPagesController"
architecture_ref: "dynamic-error-page-rendering"
---

# Error Page Rendering Flow

## Summary

The Error Page Rendering flow is triggered whenever a request results in an HTTP error condition — most commonly a 404 Not Found (invalid permalink, missing page) or a 500 Internal Server Error (upstream dependency failure). The `errorPagesController` component handles all error states and renders the appropriate error page via Preact server-side rendering. This flow also catches unhandled errors from other controllers within the service.

## Trigger

- **Type**: api-call
- **Source**: An error condition encountered during any other request handler (invalid permalink, GraphQL API failure, unhandled exception, etc.)
- **Frequency**: per-error-occurrence

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User browser | Receives the error page | — |
| Error Pages Controller | Catches error conditions and renders the appropriate error page | `errorPagesController` |
| Preact | Renders the error page HTML | in-process |

## Steps

1. **Error condition encountered**: A request handler (e.g., `contentPagesController`, `incidentController`) encounters an error — permalink not found, upstream API failure, unhandled exception.
   - From: `Any controller`
   - To: `errorPagesController`
   - Protocol: direct (Express error handling middleware)

2. **Determines error type**: Error Pages Controller inspects the error status code or type to select the appropriate error page template (404, 500, etc.).
   - From: `errorPagesController`
   - To: in-process error classification
   - Protocol: direct

3. **Renders error page**: Controller passes the error context to Preact for server-side rendering of the error page.
   - From: `errorPagesController`
   - To: `Preact`
   - Protocol: direct

4. **Returns error page to browser**: Controller responds with the rendered error HTML and the appropriate HTTP status code.
   - From: `errorPagesController`
   - To: `User browser`
   - Protocol: HTTPS (HTML response with error status code)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Error page rendering itself fails | Express default error handler catches | Minimal plain-text error response |

## Sequence Diagram

```
contentPagesController -> errorPagesController: Forward error (e.g., 404 / 500)
errorPagesController -> errorPagesController: Classify error type
errorPagesController -> Preact: Server-side render error page template
Preact --> errorPagesController: Rendered HTML
errorPagesController --> User browser: 404 / 500 (error page HTML)
```

## Related

- Architecture dynamic view: No dynamic view defined in DSL
- Related flows: [Content Page Retrieval](content-page-retrieval.md), [Incident Report Submission](incident-report-submission.md), [Infringement Report Submission](infringement-report-submission.md)
