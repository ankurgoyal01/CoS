---
service: "content-pages"
title: "Privacy Hub Navigation Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "privacy-hub-navigation"
flow_type: synchronous
trigger: "User navigates to /privacy-hub"
participants:
  - "continuumContentPagesService"
  - "privacyHubController"
  - "permalinksService"
architecture_ref: "dynamic-privacy-hub-navigation"
---

# Privacy Hub Navigation Flow

## Summary

The Privacy Hub is a dedicated page that presents a table of contents for all of Groupon's privacy-related legal documents. When a user navigates to `/privacy-hub`, the service fetches the relevant privacy document collection from the Content Pages GraphQL API via `itier-groupon-v2-content-pages`, builds a structured table of contents, and renders the page via Preact server-side rendering.

## Trigger

- **Type**: user-action
- **Source**: User browser navigates to `/privacy-hub`
- **Frequency**: per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User browser | Requests the Privacy Hub page | — |
| Privacy Hub Controller | Handles route; fetches and renders privacy hub content | `privacyHubController` |
| Permalinks Service | Resolves privacy document permalinks for the table of contents | `permalinksService` |
| Content Pages GraphQL API | Provides privacy document content and metadata | stub-only |
| Preact | Renders the page with table of contents | in-process |

## Steps

1. **Receives Privacy Hub request**: User browser sends `GET /privacy-hub`.
   - From: `User browser`
   - To: `privacyHubController`
   - Protocol: HTTPS

2. **Fetches privacy document collection**: Controller requests all privacy-related content from the Content Pages GraphQL API.
   - From: `privacyHubController`
   - To: `Content Pages GraphQL API`
   - Protocol: HTTPS/JSON (GraphQL)

3. **Receives document list and metadata**: GraphQL API returns the list of privacy documents with titles and permalinks.
   - From: `Content Pages GraphQL API`
   - To: `privacyHubController`
   - Protocol: HTTPS/JSON

4. **Resolves document permalinks**: Controller uses `permalinksService` to resolve canonical URLs for all documents in the table of contents.
   - From: `privacyHubController`
   - To: `permalinksService`
   - Protocol: direct

5. **Renders Privacy Hub page**: Controller passes the structured document list to Preact for server-side rendering with table of contents.
   - From: `privacyHubController`
   - To: `Preact`
   - Protocol: direct

6. **Returns rendered HTML**: Controller sends the rendered Privacy Hub page to the user browser.
   - From: `privacyHubController`
   - To: `User browser`
   - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Content Pages GraphQL API unavailable | Controller catches error | `errorPagesController` renders 500 error page |
| Empty document collection returned | Controller detects empty list | Renders Privacy Hub with empty or minimal table of contents |

## Sequence Diagram

```
User browser -> privacyHubController: GET /privacy-hub
privacyHubController -> Content Pages GraphQL API: GraphQL query for privacy documents
Content Pages GraphQL API --> privacyHubController: Privacy document collection
privacyHubController -> permalinksService: Resolve canonical URLs for documents
permalinksService --> privacyHubController: Resolved permalink URLs
privacyHubController -> Preact: Server-side render Privacy Hub with ToC
Preact --> privacyHubController: Rendered HTML
privacyHubController --> User browser: 200 OK (Privacy Hub page)
```

## Related

- Architecture dynamic view: No dynamic view defined in DSL
- Related flows: [Content Page Retrieval](content-page-retrieval.md), [Cookie Consent Disclosure](cookie-consent-disclosure.md)
