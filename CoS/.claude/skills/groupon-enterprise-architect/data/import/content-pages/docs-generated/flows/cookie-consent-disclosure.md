---
service: "content-pages"
title: "Cookie Consent Disclosure Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "cookie-consent-disclosure"
flow_type: synchronous
trigger: "User navigates to /cookie-consent"
participants:
  - "continuumContentPagesService"
  - "cookieConsentController"
architecture_ref: "dynamic-cookie-consent-disclosure"
---

# Cookie Consent Disclosure Flow

## Summary

The Cookie Consent Disclosure flow serves Groupon's cookie consent information page at `/cookie-consent`. This is a read-only, informational page that renders disclosure content explaining Groupon's cookie usage policy. No form submission or downstream API calls beyond the Content Pages GraphQL API are involved.

## Trigger

- **Type**: user-action
- **Source**: User browser navigates to `/cookie-consent`
- **Frequency**: per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User browser | Requests the cookie consent page | — |
| Cookie Consent Controller | Handles route; fetches and renders cookie consent content | `cookieConsentController` |
| Content Pages GraphQL API | Provides cookie consent page content | stub-only |
| Preact | Renders the page | in-process |

## Steps

1. **Receives cookie consent request**: User browser sends `GET /cookie-consent`.
   - From: `User browser`
   - To: `cookieConsentController`
   - Protocol: HTTPS

2. **Fetches cookie consent content**: Controller requests cookie consent page content from the Content Pages GraphQL API.
   - From: `cookieConsentController`
   - To: `Content Pages GraphQL API`
   - Protocol: HTTPS/JSON (GraphQL)

3. **Receives content response**: GraphQL API returns the cookie consent page body and metadata.
   - From: `Content Pages GraphQL API`
   - To: `cookieConsentController`
   - Protocol: HTTPS/JSON

4. **Renders cookie consent page**: Controller passes content to Preact for server-side rendering.
   - From: `cookieConsentController`
   - To: `Preact`
   - Protocol: direct

5. **Returns rendered HTML**: Controller sends the rendered page to the user browser.
   - From: `cookieConsentController`
   - To: `User browser`
   - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Content Pages GraphQL API unavailable | Controller catches error | `errorPagesController` renders 500 error page |

## Sequence Diagram

```
User browser -> cookieConsentController: GET /cookie-consent
cookieConsentController -> Content Pages GraphQL API: GraphQL query for cookie consent content
Content Pages GraphQL API --> cookieConsentController: Cookie consent content payload
cookieConsentController -> Preact: Server-side render cookie consent page
Preact --> cookieConsentController: Rendered HTML
cookieConsentController --> User browser: 200 OK (cookie consent page)
```

## Related

- Architecture dynamic view: No dynamic view defined in DSL
- Related flows: [Privacy Hub Navigation](privacy-hub-navigation.md), [Content Page Retrieval](content-page-retrieval.md)
