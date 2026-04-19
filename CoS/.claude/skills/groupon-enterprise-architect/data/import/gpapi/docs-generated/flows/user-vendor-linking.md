---
service: "gpapi"
title: "User-Vendor Linking"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "user-vendor-linking"
flow_type: synchronous
trigger: "Admin or vendor user submits a user-to-vendor association request"
participants:
  - "continuumGpapiService"
  - "continuumGpapiDb"
  - "Users Service"
architecture_ref: "dynamic-vendorOnboardingFlow"
---

# User-Vendor Linking

## Summary

User-vendor linking associates a Goods Vendor Portal user account with one or more vendor records, enabling the user to operate within the portal on behalf of those vendors. gpapi manages the association records in its own database and synchronizes user identity with the downstream Users Service. This flow supports both initial onboarding (first-time link) and subsequent additions of users to additional vendors.

## Trigger

- **Type**: api-call
- **Source**: Admin or vendor user submitting a user-vendor association request via the Vendor Portal UI
- **Frequency**: On demand (per user-vendor association action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Vendor Portal UI | Initiates user-vendor link request | — |
| Goods Product API | Validates and persists user-vendor association; coordinates with Users Service | `continuumGpapiService` |
| gpapi Database | Stores user-vendor association records | `continuumGpapiDb` |
| Users Service | Manages user identity and vendor permissions | — |

## Steps

1. **Receive link request**: Vendor Portal UI submits user-vendor association payload (user_id, vendor_id, role).
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v1/users/:id/vendors` or `POST /api/v1/vendors/:id/users`
   - Protocol: REST

2. **Validate association request**: gpapi checks that both the user and vendor exist and that the requester has permission to create the link.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb` (existence and permission check)
   - Protocol: PostgreSQL

3. **Persist association record**: gpapi writes the user-vendor link record to its database.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

4. **Synchronize with Users Service**: gpapi notifies Users Service of the new vendor permission for the user.
   - From: `continuumGpapiService`
   - To: Users Service (update user vendor permissions)
   - Protocol: REST

5. **Return link result**: gpapi returns the created association record to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 201 Created)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not found | Return 404 Not Found | Link not created |
| Vendor not found | Return 404 Not Found | Link not created |
| Duplicate link | Return 422 Unprocessable Entity | Link not created; existing link preserved |
| Insufficient permission | Return 403 Forbidden | Link not created |
| Users Service unavailable | Return 503 or propagate error | Link may be persisted in gpapi but not synchronized |

## Sequence Diagram

```
VendorPortalUI -> continuumGpapiService: POST /api/v1/vendors/:id/users (user_id, role)
continuumGpapiService -> continuumGpapiDb: SELECT user, vendor (validate existence)
continuumGpapiDb --> continuumGpapiService: records found
continuumGpapiService -> continuumGpapiDb: INSERT user-vendor association
continuumGpapiService -> UsersService: PATCH /users/:id (add vendor permission)
UsersService --> continuumGpapiService: 200 OK
continuumGpapiService --> VendorPortalUI: 201 Created (association record)
```

## Related

- Architecture dynamic view: `dynamic-vendorOnboardingFlow`
- Related flows: [Vendor Onboarding](vendor-onboarding.md), [Session Auth 2FA](session-auth-2fa.md)
