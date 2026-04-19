---
service: "next-pwa-app"
title: "SSR Request Middleware Chain Flow"
generated: "2026-03-03"
type: flow
flow_name: "ssr-request-middleware-chain"
flow_type: synchronous
trigger: "Every incoming HTTP request to the Next.js server"
participants:
  - "consumer"
  - "mbnxtWebsite"
  - "web_routing"
architecture_ref: ""
---

# SSR Request Middleware Chain Flow

## Summary

Every HTTP request to the Next.js application passes through an extensive middleware chain before reaching the page route handler. The middleware stack is composed of individual middleware functions (prefixed `with-*`) that are chained together via `stack-proxy.ts`. These middlewares handle concerns such as locale detection, authorization, nonce generation, URL rewrites, redirects, template detection, Sentry integration, traffic source tracking, and App Router compatibility. This flow is critical because it determines routing behavior, security headers, and user session context for every request.

## Trigger

- **Type**: api-call
- **Source**: Any HTTP request hitting the Next.js server (browser navigation, API call, crawler)
- **Frequency**: Per-request (every HTTP request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer / Client | Sends HTTP request | `consumer` |
| MBNXT Web | Receives and processes the request through middleware | `mbnxtWebsite` |
| Web Routing & Pages | Final route resolution after middleware completes | `web_routing` |

## Steps

1. **Request Received**: Incoming HTTP request hits the Next.js middleware entry point
   - From: `consumer`
   - To: `mbnxtWebsite` (middleware entry)
   - Protocol: HTTPS

2. **Nonce Generation** (`with-nonce`): Generates a CSP nonce for the request
   - From: middleware chain
   - To: request headers
   - Protocol: Direct

3. **Request Data Injection** (`with-request-data`): Enriches request with parsed metadata (user agent, device, etc.)
   - From: middleware chain
   - To: request headers
   - Protocol: Direct

4. **Sentry Integration** (`with-sentry`): Attaches Sentry context and transaction to the request
   - From: middleware chain
   - To: Sentry SDK
   - Protocol: Direct

5. **Authorization Check** (`with-authorization`): Validates user session/auth tokens
   - From: middleware chain
   - To: session store
   - Protocol: Direct

6. **Locale Redirect** (`with-locale-redirect`): Detects user locale and redirects if needed
   - From: middleware chain
   - To: response (redirect or continue)
   - Protocol: Direct

7. **Localized URL Rewrite** (`with-localized-url-rewrite`): Rewrites URLs for locale-specific paths
   - From: middleware chain
   - To: request URL
   - Protocol: Direct

8. **Browse Redirect** (`with-browse-redirect`): Handles legacy browse URL redirects
   - From: middleware chain
   - To: response (redirect or continue)
   - Protocol: Direct

9. **Legacy Redirect** (`with-legacy-redirect`): Handles legacy URL patterns
   - From: middleware chain
   - To: response (redirect or continue)
   - Protocol: Direct

10. **Template Detection** (`with-template-detection`): Detects white-label template from request context
    - From: middleware chain
    - To: request headers (template ID, brand)
    - Protocol: Direct

11. **App Router Rewrite** (`with-app-router-rewrite`): Rewrites paths for App Router routes
    - From: middleware chain
    - To: request URL
    - Protocol: Direct

12. **SSG Handler** (`with-ssg-handler`): Handles statically generated page requests
    - From: middleware chain
    - To: response or continue
    - Protocol: Direct

13. **Traffic Source Cookies** (`with-traffic-source-cookies`): Sets cookies for marketing attribution
    - From: middleware chain
    - To: response cookies
    - Protocol: Direct

14. **User Activity Cookies** (`with-user-activity-cookies`): Sets cookies for user activity tracking
    - From: middleware chain
    - To: response cookies
    - Protocol: Direct

15. **Response Headers** (`with-response-headers`): Sets security and cache headers
    - From: middleware chain
    - To: response headers
    - Protocol: Direct

16. **Response Cookies** (`with-response-cookies`): Sets final response cookies
    - From: middleware chain
    - To: response cookies
    - Protocol: Direct

17. **Route Resolution**: After middleware completes, Next.js resolves the final route
    - From: `mbnxtWebsite` (middleware exit)
    - To: `web_routing`
    - Protocol: Direct (Next.js internal)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Middleware exception | Error caught, request continues with defaults | Degraded but functional page render |
| Redirect loop detected | Loop detection prevents infinite redirects | 500 error returned |
| Auth check failure | Redirect to login page | Consumer redirected to `/login` |
| Invalid locale | Fallback to default locale | Page rendered in default locale |

## Sequence Diagram

```
Consumer -> MBNXT Web: HTTP Request
MBNXT Web -> with-nonce: Generate CSP nonce
with-nonce -> with-request-data: Enrich request
with-request-data -> with-sentry: Attach Sentry context
with-sentry -> with-authorization: Check auth
with-authorization -> with-locale-redirect: Check locale
with-locale-redirect -> with-localized-url-rewrite: Rewrite URL
with-localized-url-rewrite -> with-browse-redirect: Check redirects
with-browse-redirect -> with-template-detection: Detect template
with-template-detection -> with-app-router-rewrite: Rewrite for App Router
with-app-router-rewrite -> with-response-headers: Set headers
with-response-headers -> Web Routing: Resolved request
Web Routing --> MBNXT Web: Page render result
MBNXT Web --> Consumer: HTTP Response
```

## Related

- Architecture dynamic view: N/A (internal processing flow)
- Related flows: [Consumer Browse and Search](consumer-browse-and-search.md), [Deal Page View](deal-page-view.md)
