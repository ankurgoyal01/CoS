---
service: "b2b-ui"
title: "Role Management Request Flow"
generated: "2026-03-03"
type: flow
flow_name: "role-management-request"
flow_type: synchronous
trigger: "Browser action on RBAC administration screen"
participants:
  - "rbacUi_webUi"
  - "rbacUi_sessionMiddleware"
  - "rbacUi_bffApi"
  - "continuumRbacService"
  - "continuumUsersService"
  - "rbacUi_metricsLogging"
architecture_ref: "dynamic-rbac-rbacUi_webUi-role-management-flow"
---

# Role Management Request Flow

## Summary

This flow covers all RBAC administration operations (viewing roles, permissions, categories, or submitting access requests) initiated from the browser. A request from the React UI passes through the Next.js Session Middleware for authentication, is forwarded to the BFF API, which then calls `continuumRbacService` for RBAC domain operations and `continuumUsersService` for user identity resolution. Client telemetry is sent in parallel to the Metrics Logging component.

## Trigger

- **Type**: user-action
- **Source**: Operator or merchant admin interacts with the RBAC administration screens in the browser
- **Frequency**: On-demand (per user interaction)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| RBAC Web UI | Initiates requests; renders response data in administration screens | `rbacUi_webUi` |
| Session Middleware | Validates auth cookie/JWT; injects RBAC identity headers | `rbacUi_sessionMiddleware` |
| RBAC BFF API | Orchestrates RBAC operations; calls downstream services | `rbacUi_bffApi` |
| continuumRbacService | Executes RBAC v2 role/permission/category/request operations | `continuumRbacService` |
| continuumUsersService | Resolves user identities for display and ownership data | `continuumUsersService` |
| Metrics Logging API | Receives browser telemetry; writes structured server logs | `rbacUi_metricsLogging` |

## Steps

1. **Sends request with RBAC auth cookie**: Browser sends an HTTP request to a BFF API route (`/api/rbac`) with the auth cookie.
   - From: `rbacUi_webUi`
   - To: `rbacUi_sessionMiddleware`
   - Protocol: HTTP (Next.js request pipeline)

2. **Validates token and injects requester headers**: Session Middleware parses the auth cookie, validates the JWT (using `jose`), and injects RBAC identity headers into the request context.
   - From: `rbacUi_sessionMiddleware`
   - To: `rbacUi_bffApi`
   - Protocol: HTTP (internal Next.js middleware chain)

3. **Performs RBAC role/permission/category operations**: BFF API calls `continuumRbacService` RBAC v2 endpoints using the generated `@vpcs/rbac-client`, passing the RBAC client ID and identity headers.
   - From: `rbacUi_bffApi`
   - To: `continuumRbacService`
   - Protocol: REST/HTTP

4. **Resolves user identities for display and ownership data**: BFF API calls `continuumUsersService` via `@vpcs/users-client` to resolve user names and ownership data needed by the UI.
   - From: `rbacUi_bffApi`
   - To: `continuumUsersService`
   - Protocol: REST/HTTP

5. **Returns composed response to browser**: BFF API assembles the response and returns it to the RBAC Web UI, which renders the updated administration screen.
   - From: `rbacUi_bffApi`
   - To: `rbacUi_webUi`
   - Protocol: HTTP/JSON

6. **Sends client telemetry** (parallel): Browser posts client-side log events to `/api/metrics/log`.
   - From: `rbacUi_webUi`
   - To: `rbacUi_metricsLogging`
   - Protocol: REST/HTTP (POST)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JWT validation failure in middleware | Session Middleware rejects request; redirects to login | User is redirected to re-authenticate |
| `continuumRbacService` returns 5xx | BFF propagates error to browser | Admin screen displays error state |
| `continuumUsersService` returns error | BFF propagates error or returns partial response | User identity fields may be missing in UI |
| Network timeout to downstream service | HTTP timeout propagated by BFF | Browser receives 5xx error |

## Sequence Diagram

```
rbacUi_webUi -> rbacUi_sessionMiddleware: Sends request with RBAC auth cookie
rbacUi_sessionMiddleware -> rbacUi_bffApi: Validates token and injects requester headers
rbacUi_bffApi -> continuumRbacService: Performs RBAC role/permission/category operations
rbacUi_bffApi -> continuumUsersService: Resolves user identities for display and ownership data
continuumRbacService --> rbacUi_bffApi: RBAC data response
continuumUsersService --> rbacUi_bffApi: User identity data
rbacUi_bffApi --> rbacUi_webUi: Composed JSON response
rbacUi_webUi -> rbacUi_metricsLogging: Sends client telemetry
```

## Related

- Architecture dynamic view: `dynamic-rbac-rbacUi_webUi-role-management-flow`
- Related flows: [Session Validation Flow](session-validation.md), [User Provisioning Flow](user-provisioning.md)
