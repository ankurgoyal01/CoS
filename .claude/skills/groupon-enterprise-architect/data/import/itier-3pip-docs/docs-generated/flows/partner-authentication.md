---
service: "itier-3pip-docs"
title: "Partner Authentication"
generated: "2026-03-03"
type: flow
flow_name: "partner-authentication"
flow_type: synchronous
trigger: "Partner browser request to any protected route or API endpoint"
participants:
  - "frontendBundle"
  - "simulatorApiActions"
  - "continuumUsersService"
architecture_ref: "dynamic-continuumThreePipDocsWeb"
---

# Partner Authentication

## Summary

Every request to a protected page route or simulator API endpoint in `itier-3pip-docs` must carry a valid Groupon partner session. The service validates this session by calling `continuumUsersService` through the `itier-user-auth` library. Unauthenticated or invalid sessions are redirected to the Groupon login page. Once authenticated, the user's `userId` is extracted and used as the identity key for all subsequent PAPI queries.

## Trigger

- **Type**: user-action
- **Source**: Partner browser HTTP request to any protected route (`/integration`, `/api/*`, `/3pip/docs`, etc.)
- **Frequency**: Per-request (every protected API call and page load)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Partner Browser | Initiates request with session cookie | External actor |
| `frontendBundle` | Sends API requests from the SPA with cookie credentials | `continuumThreePipDocsWeb` |
| `simulatorApiActions` | Calls `getUserValidation()` before processing any action | `continuumThreePipDocsWeb` |
| `continuumUsersService` | Validates the session token and returns user identity | `continuumUsersService` |

## Steps

1. **Receives partner request**: Partner browser sends HTTP request to a protected route, including the `macaroon` (or equivalent) session cookie.
   - From: `frontendBundle` (browser)
   - To: `simulatorApiActions` (server)
   - Protocol: HTTP REST

2. **Validates session**: `simulatorApiActions` calls `getUserValidation(deps)`, which invokes `userAuth.getPersonalizedUser()` via `itier-user-auth`.
   - From: `simulatorApiActions`
   - To: `continuumUsersService`
   - Protocol: Cookie / OAuth token

3. **Returns user identity**: `continuumUsersService` validates the session cookie and returns the authenticated user object, including `user.id`.
   - From: `continuumUsersService`
   - To: `simulatorApiActions`
   - Protocol: Internal service response

4. **Proceeds or redirects**: If the user has a valid `id`, the request continues to the action handler. If validation fails (no `id`, exception thrown), the action returns HTTP 401 (for API endpoints) or redirects to the Groupon login URL (for page routes).
   - From: `simulatorApiActions`
   - To: `frontendBundle` (browser)
   - Protocol: HTTP response (200/401/302)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session cookie missing or invalid | `userAuth.getPersonalizedUser()` throws or returns user without `id` | API: HTTP 401 returned; Page: redirect to `redirectRoutes.grouponLogin` |
| `continuumUsersService` unreachable | Exception caught in `getUserValidation()` | API: HTTP 401 returned; Page: redirect to login |
| `bypassMerchantAuth: true` (production flag) | Merchant auth middleware skipped for `/3pip/docs` route | Route proceeds without merchant-specific auth check |

## Sequence Diagram

```
Partner Browser -> simulatorApiActions: HTTP request + session cookie
simulatorApiActions -> continuumUsersService: getPersonalizedUser()
continuumUsersService --> simulatorApiActions: { id: userId } or error
simulatorApiActions --> Partner Browser: 200 (continue) or 401/302 (redirect to login)
```

## Related

- Architecture dynamic view: `dynamic-continuumThreePipDocsWeb`
- Related flows: [Partner Onboarding Configuration Load](partner-onboarding-config-load.md), [Test Deal Setup](test-deal-setup.md)
