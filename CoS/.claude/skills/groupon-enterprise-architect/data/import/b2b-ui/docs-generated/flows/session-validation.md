---
service: "b2b-ui"
title: "Session Validation Flow"
generated: "2026-03-03"
type: flow
flow_name: "session-validation"
flow_type: synchronous
trigger: "Every inbound browser HTTP request to the RBAC UI"
participants:
  - "rbacUi_webUi"
  - "rbacUi_sessionMiddleware"
  - "rbacUi_bffApi"
architecture_ref: "dynamic-rbac-rbacUi_webUi-role-management-flow"
---

# Session Validation Flow

## Summary

Every request from the browser to the RBAC UI passes through the Session Middleware component before reaching any page route or BFF API route. The middleware extracts the auth cookie, validates the JWT using `jose`, and injects RBAC identity headers. Requests that fail validation are redirected to login. This flow is a prerequisite for all other RBAC UI flows.

## Trigger

- **Type**: api-call (internal, per-request)
- **Source**: Every inbound HTTP request from the browser, including page navigations and API calls
- **Frequency**: Per-request (every browser interaction)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| RBAC Web UI | Originates the request with the auth cookie | `rbacUi_webUi` |
| Session Middleware | Validates the cookie/JWT; injects identity headers or redirects | `rbacUi_sessionMiddleware` |
| RBAC BFF API | Receives the authenticated, header-enriched request | `rbacUi_bffApi` |

## Steps

1. **Sends request with auth cookie**: Browser sends an HTTP request (page navigation or API call) carrying the auth cookie.
   - From: `rbacUi_webUi`
   - To: `rbacUi_sessionMiddleware`
   - Protocol: HTTP (Next.js request pipeline)

2. **Extracts and validates JWT**: Session Middleware parses the cookie using the `cookie` library, extracts the JWT, and verifies its signature and claims using `jose`.
   - From: `rbacUi_sessionMiddleware` (internal processing)
   - To: `rbacUi_sessionMiddleware`
   - Protocol: In-process

3. **Injects RBAC identity headers**: On successful validation, Session Middleware adds RBAC identity headers to the request (requester identity, roles, region context) before forwarding to the BFF API or page handler.
   - From: `rbacUi_sessionMiddleware`
   - To: `rbacUi_bffApi`
   - Protocol: HTTP (Next.js middleware chain)

4. **Redirects to login on failure**: If JWT validation fails (expired, invalid signature, missing cookie), the middleware redirects the browser to the login page.
   - From: `rbacUi_sessionMiddleware`
   - To: Browser (redirect response)
   - Protocol: HTTP 302 redirect

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing auth cookie | Middleware redirects to login | User must log in before accessing any screen |
| Expired JWT | Middleware redirects to login | User is prompted to re-authenticate |
| Invalid JWT signature | Middleware redirects to login | Possible session tampering; user redirected |
| Middleware internal error | Next.js default error handling | 500 error page shown |

## Sequence Diagram

```
rbacUi_webUi -> rbacUi_sessionMiddleware: Sends request with auth cookie
rbacUi_sessionMiddleware -> rbacUi_sessionMiddleware: Parses cookie; validates JWT (jose)
alt JWT valid
  rbacUi_sessionMiddleware -> rbacUi_bffApi: Forwards request with injected identity headers
else JWT invalid or missing
  rbacUi_sessionMiddleware --> rbacUi_webUi: HTTP 302 redirect to login
end
```

## Related

- Architecture dynamic view: `dynamic-rbac-rbacUi_webUi-role-management-flow`
- Related flows: [Role Management Request Flow](role-management-request.md), [User Provisioning Flow](user-provisioning.md)
