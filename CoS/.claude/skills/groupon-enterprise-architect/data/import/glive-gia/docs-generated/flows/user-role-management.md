---
service: "glive-gia"
title: "User Role Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "user-role-management"
flow_type: synchronous
trigger: "Admin user creates, updates, or deactivates a GIA user account"
participants:
  - "continuumGliveGiaWebApp"
  - "continuumGliveGiaMysqlDatabase"
architecture_ref: "dynamic-glive-gia-user-roles"
---

# User Role Management

## Summary

GIA maintains its own user accounts and role assignments stored in MySQL. An authorized admin (with appropriate Pundit policy permissions) can create new GIA users, assign or change roles, and deactivate users who no longer require access. Authentication is delegated to OGWall; GIA manages authorization through Pundit role policies applied per-action. Paper Trail records all user record changes for audit purposes.

## Trigger

- **Type**: user-action
- **Source**: Admin accessing `/users` routes in the GIA web UI
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GIA Web App | Handles HTTP requests; enforces Pundit authorization; manages user records | `continuumGliveGiaWebApp` |
| OGWall | Authenticates the admin making the request | External (`ogwall_unknown_7f81`) |
| GIA MySQL Database | Stores GIA user accounts and role assignments | `continuumGliveGiaMysqlDatabase` |

## Steps

1. **Admin navigates to user management**: Admin accesses `/users`, `/users/new`, or `/users/:id` in the GIA UI; OGWall session validates the admin's authentication
   - From: Admin browser
   - To: `continuumGliveGiaWebApp` (`gliveGia_webControllers`)
   - Protocol: REST (HTTP GET)

2. **Pundit authorization check**: `gliveGia_webControllers` invokes the Pundit policy for the requested action; confirms the requesting admin has sufficient privileges to manage users
   - From: `continuumGliveGiaWebApp` (`gliveGia_webControllers`)
   - To: Pundit policy (in-process)
   - Protocol: Direct (in-process)

3. **Render user form / list**: `viewPresenters` renders the user list or creation/edit form
   - From: `continuumGliveGiaWebApp` (`viewPresenters`)
   - To: Admin browser
   - Protocol: HTTP 200

4. **Admin submits user changes**: Admin submits `POST /users` (create), `PATCH /users/:id` (update role/attributes), or `DELETE /users/:id` (deactivate)
   - From: Admin browser
   - To: `continuumGliveGiaWebApp` (`gliveGia_webControllers`)
   - Protocol: REST (HTTP POST/PATCH/DELETE)

5. **Pundit re-authorization on mutating action**: Controller re-checks Pundit policy for the mutating action
   - From: `continuumGliveGiaWebApp` (`gliveGia_webControllers`)
   - To: Pundit policy (in-process)
   - Protocol: Direct (in-process)

6. **Validate and persist user record**: `domainModels` validate the user attributes; ActiveRecord writes the create/update/deactivation to MySQL; Paper Trail records the change
   - From: `continuumGliveGiaWebApp` (`businessServices` -> `domainModels`)
   - To: `continuumGliveGiaMysqlDatabase`
   - Protocol: ActiveRecord / MySQL

7. **Render confirmation**: Controller redirects admin to the user list with a success flash
   - From: `continuumGliveGiaWebApp`
   - To: Admin browser
   - Protocol: HTTP 302

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pundit authorization failure | `Pundit::NotAuthorizedError` raised; Rails rescues and renders 403 | Action blocked; admin sees unauthorized error |
| User validation failure (e.g., duplicate email) | ActiveRecord validation error returned to controller | User not created/updated; admin sees inline error |
| MySQL write failure | ActiveRecord exception; Rails error response | User change not persisted; admin can retry |
| Attempt to deactivate own account | Business validation prevents self-deactivation | Admin sees error; account not deactivated |

## Sequence Diagram

```
Admin -> GIA Web App: GET /users (list)
GIA Web App -> Pundit policy: authorize :index, User
Pundit policy --> GIA Web App: authorized
GIA Web App -> GIA MySQL Database: SELECT users
GIA MySQL Database --> GIA Web App: user records
GIA Web App --> Admin: Render user list
Admin -> GIA Web App: POST /users (create) or PATCH /users/:id (update)
GIA Web App -> Pundit policy: authorize :create/:update, User
Pundit policy --> GIA Web App: authorized
GIA Web App -> GIA MySQL Database: INSERT/UPDATE users
GIA MySQL Database --> GIA Web App: user record saved
GIA Web App --> Admin: 302 redirect to user list
```

## Related

- Architecture dynamic view: `dynamic-glive-gia-user-roles`
- Related flows: [Deal Creation from DMAPI](deal-creation-from-dmapi.md)
