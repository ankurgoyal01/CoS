---
service: "calcom"
title: "Admin User Promotion"
generated: "2026-03-03"
type: flow
flow_name: "admin-user-promotion"
flow_type: batch
trigger: "Manual operation: an authorized administrator needs to grant another user admin privileges"
participants:
  - "continuumCalcomPostgres"
architecture_ref: "components-continuum-calcom-service"
---

# Admin User Promotion

## Summary

Because user management is a paid Cal.com feature not available in Groupon's free license, granting admin privileges to a user requires a manual direct database update. This flow describes the process by which an authorized operator connects to the production PostgreSQL database and updates the target user's role field to `ADMIN`. This is a privileged operation requiring database DBA credentials.

## Trigger

- **Type**: manual
- **Source**: An authorized Groupon operator (with DBA database access) performing user administration
- **Frequency**: On-demand, as needed when new admins require access

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Authorized operator | Performs the manual database update | — |
| Cal.com web application | User creates a regular account at meet.groupon.com | `continuumCalcomService` |
| Cal.com PostgreSQL | `users` table is updated to grant ADMIN role | `continuumCalcomPostgres` |

## Steps

1. **User creates regular account**: The target user creates a regular (non-admin) account at `https://meet.groupon.com`.
   - From: User's browser
   - To: `continuumCalcomService`
   - Protocol: HTTPS

2. **User sets password and enables 2FA**: The user sets a password longer than 15 characters and enables two-factor authentication on their account (both are required for admin access).
   - From: User's browser
   - To: `continuumCalcomService`
   - Protocol: HTTPS

3. **Operator obtains database credentials**: The authorized operator retrieves the DBA credentials from the [calcom-secrets repository](https://github.groupondev.com/conveyor-cloud/calcom-secrets/blob/main/database_credentials).
   - From: Operator
   - To: `calcom-secrets` GitHub repository
   - Protocol: HTTPS (GitHub)

4. **Operator connects to production database**: Operator connects to `calcom_prod` on `pg-noncore-us-057-prod` (AWS us-west-1) using the DBA credentials.
   - From: Operator workstation
   - To: `continuumCalcomPostgres`
   - Protocol: PostgreSQL

5. **Operator updates user role**: Operator locates the target user's record in the `users` table by email and updates the `role` field to `ADMIN`.
   - From: Operator (SQL)
   - To: `continuumCalcomPostgres`
   - Protocol: PostgreSQL (SQL UPDATE)

6. **User re-authenticates**: The promoted user logs out and back in to the application. The admin `Settings > Admin` section becomes visible.
   - From: User's browser
   - To: `continuumCalcomService`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Admin section not visible after promotion | Verify user has password > 15 characters AND 2FA enabled | User can re-enable 2FA and retry; no database change needed |
| Database access denied | Ensure DBA user credentials are used (not application user) | Retry with correct credentials from secrets repository |
| Orange banner warning in UI | User does not meet password/2FA requirements | User must update password length and/or enable 2FA |

## Sequence Diagram

```
User -> continuumCalcomService: Create regular account at meet.groupon.com
User -> continuumCalcomService: Set password >15 chars and enable 2FA
Operator -> calcom-secrets-repo: Retrieve DBA database credentials
Operator -> continuumCalcomPostgres: Connect to calcom_prod (PostgreSQL)
Operator -> continuumCalcomPostgres: UPDATE users SET role='ADMIN' WHERE email='<target>'
continuumCalcomPostgres --> Operator: Update successful
User -> continuumCalcomService: Log out and log back in
continuumCalcomService -> continuumCalcomPostgres: Read user record with role=ADMIN
continuumCalcomPostgres --> continuumCalcomService: User has ADMIN role
User -> continuumCalcomService: Admin section visible in Settings
```

## Related

- Architecture dynamic view: `components-continuum-calcom-service`
- Related flows: [Booking Confirmation Flow](booking-confirmation.md)
- Access requirements: ARQ group `grp_conveyor_privileged_calcom` for Kubernetes; DBA database access via calcom-secrets repository
