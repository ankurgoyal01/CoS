---
service: "b2b-ui"
title: "User Provisioning Flow"
generated: "2026-03-03"
type: flow
flow_name: "user-provisioning"
flow_type: synchronous
trigger: "Operator submits create-user form in RBAC administration UI"
participants:
  - "rbacUi_webUi"
  - "rbacUi_sessionMiddleware"
  - "rbacUi_bffApi"
  - "rbacUi_userProvisioning"
  - "rbacUi_metricsLogging"
  - "continuumRbacService"
  - "continuumUsersService"
architecture_ref: "dynamic-rbac-rbacUi_webUi-role-management-flow"
---

# User Provisioning Flow

## Summary

This flow handles the creation of a new user across NA and EMEA regions. The operator submits a create-user form in the RBAC administration UI; the BFF API delegates to the User Provisioning Flow component, which orchestrates permission checks and account creation calls to both `continuumRbacService` and `continuumUsersService`. Audit logs are written throughout by the Metrics Logging component.

## Trigger

- **Type**: user-action
- **Source**: Operator submits the create-user form on the RBAC administration screen
- **Frequency**: On-demand (per operator action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| RBAC Web UI | Renders the create-user form; submits form data to BFF API | `rbacUi_webUi` |
| Session Middleware | Validates auth cookie/JWT; injects identity headers | `rbacUi_sessionMiddleware` |
| RBAC BFF API | Receives `/api/rbac/users/create` request; delegates to User Provisioning component | `rbacUi_bffApi` |
| User Provisioning Flow | Orchestrates multi-region user creation with permission checks | `rbacUi_userProvisioning` |
| Metrics Logging API | Writes user-creation audit logs | `rbacUi_metricsLogging` |
| continuumRbacService | Provides RBAC permission checks for user creation | `continuumRbacService` |
| continuumUsersService | Creates the user account in NA and EMEA regions | `continuumUsersService` |

## Steps

1. **Submits create-user request**: Operator fills in the create-user form and submits. The browser sends a POST to `/api/rbac/users/create` with user details.
   - From: `rbacUi_webUi`
   - To: `rbacUi_sessionMiddleware`
   - Protocol: REST/HTTP (POST)

2. **Validates token and injects identity headers**: Session Middleware validates the JWT from the auth cookie and injects the requester's RBAC identity into request headers.
   - From: `rbacUi_sessionMiddleware`
   - To: `rbacUi_bffApi`
   - Protocol: HTTP (Next.js middleware chain)

3. **Invokes user provisioning orchestration**: BFF API receives the authenticated request at `/api/rbac/users/create` and invokes the User Provisioning Flow component.
   - From: `rbacUi_bffApi`
   - To: `rbacUi_userProvisioning`
   - Protocol: Direct (in-process)

4. **Checks permissions via RBAC service**: User Provisioning Flow calls `continuumRbacService` to verify the requester has permission to create users.
   - From: `rbacUi_userProvisioning` (via `rbacUi_bffApi`)
   - To: `continuumRbacService`
   - Protocol: REST/HTTP

5. **Creates user account in NA region**: User Provisioning Flow calls `continuumUsersService` to create the user account in the NA region.
   - From: `rbacUi_userProvisioning` (via `rbacUi_bffApi`)
   - To: `continuumUsersService`
   - Protocol: REST/HTTP

6. **Creates user account in EMEA region**: User Provisioning Flow calls `continuumUsersService` to create the user account in the EMEA region.
   - From: `rbacUi_userProvisioning` (via `rbacUi_bffApi`)
   - To: `continuumUsersService`
   - Protocol: REST/HTTP

7. **Writes user-creation audit log**: User Provisioning Flow writes a structured audit log entry for the completed provisioning operation.
   - From: `rbacUi_userProvisioning`
   - To: `rbacUi_metricsLogging`
   - Protocol: Direct (in-process)

8. **Returns provisioning result to browser**: BFF API returns the user provisioning result (success or failure) to the RBAC Web UI.
   - From: `rbacUi_bffApi`
   - To: `rbacUi_webUi`
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Permission check fails | User Provisioning Flow aborts; returns 403 to BFF | Operator sees permission denied error |
| `continuumUsersService` failure (NA) | Error propagated by User Provisioning Flow | Provisioning aborted; audit log records failure |
| `continuumUsersService` failure (EMEA) | Error propagated; partial provisioning may have occurred | Audit log records partial state; operator may need manual remediation |
| JWT validation failure | Session Middleware rejects; redirects to login | Operator must re-authenticate |

## Sequence Diagram

```
rbacUi_webUi -> rbacUi_sessionMiddleware: POST /api/rbac/users/create (with auth cookie)
rbacUi_sessionMiddleware -> rbacUi_bffApi: Validates token and injects requester headers
rbacUi_bffApi -> rbacUi_userProvisioning: Invokes create-user orchestration
rbacUi_userProvisioning -> continuumRbacService: Checks create-user permissions
continuumRbacService --> rbacUi_userProvisioning: Permission check result
rbacUi_userProvisioning -> continuumUsersService: Creates user (NA region)
continuumUsersService --> rbacUi_userProvisioning: NA user creation result
rbacUi_userProvisioning -> continuumUsersService: Creates user (EMEA region)
continuumUsersService --> rbacUi_userProvisioning: EMEA user creation result
rbacUi_userProvisioning -> rbacUi_metricsLogging: Writes user-creation audit log
rbacUi_userProvisioning --> rbacUi_bffApi: Provisioning result
rbacUi_bffApi --> rbacUi_webUi: Success/failure response
```

## Related

- Architecture dynamic view: `dynamic-rbac-rbacUi_webUi-role-management-flow`
- Related flows: [Role Management Request Flow](role-management-request.md), [Session Validation Flow](session-validation.md)
