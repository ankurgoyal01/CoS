---
service: "mdi-dashboard-v2"
title: "API Key Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "api-key-management"
flow_type: synchronous
trigger: "User creates, lists, or revokes an API key via the /keys route"
participants:
  - "continuumMarketingDealServiceDashboard"
  - "mdiDashboardPostgres"
architecture_ref: "dynamic-mdi-api-key-management"
---

# API Key Management

## Summary

The API key management flow allows authorized internal users to provision and revoke API keys that grant programmatic access to deal intelligence data. The dashboard manages the full API key lifecycle — creation, listing, and revocation — with all key records persisted in the `mdiDashboardPostgres` PostgreSQL database via the Sequelize ORM.

## Trigger

- **Type**: user-action
- **Source**: User interacts with the API key management UI at `GET /keys`, `POST /keys`, or `DELETE /keys`
- **Frequency**: on-demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MDI Dashboard | Receives user requests; validates inputs; performs key CRUD operations | `continuumMarketingDealServiceDashboard` |
| MDI Dashboard PostgreSQL | Persists API key records | `mdiDashboardPostgres` |

## Steps

### List API Keys

1. **Receives list request**: User navigates to `GET /keys`.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Queries API key records**: Dashboard queries the `api_keys` table via Sequelize.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `mdiDashboardPostgres`
   - Protocol: PostgreSQL

4. **Renders key list**: Dashboard renders the API key list page with active and revoked keys.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML response)

### Create API Key

1. **Receives creation request**: User submits `POST /keys` with owner/label metadata.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Generates API key**: Dashboard generates a new unique API key value.
   - From: `continuumMarketingDealServiceDashboard`
   - To: in-process key generator
   - Protocol: in-process

4. **Persists API key record**: Dashboard inserts a new row into the `api_keys` table via Sequelize.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `mdiDashboardPostgres`
   - Protocol: PostgreSQL

5. **Returns confirmation**: Dashboard renders success response with the new key value.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML or JSON response)

### Revoke API Key

1. **Receives revocation request**: User submits `DELETE /keys` with the key ID to revoke.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Marks key as revoked**: Dashboard updates or deletes the `api_keys` record via Sequelize.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `mdiDashboardPostgres`
   - Protocol: PostgreSQL

4. **Returns confirmation**: Dashboard renders revocation confirmation.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML or JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL connection failure | Sequelize throws connection error; propagated to user | Error page shown; key operation not completed |
| Duplicate key ID on creation | Sequelize unique constraint error; retry with new key | New key generated and retried |
| Key not found on revocation | Sequelize returns null; 404 returned | User informed the key does not exist |
| Authentication failure | itier-user-auth redirects to login | User redirected to Groupon SSO login |

## Sequence Diagram

```
User -> continuumMarketingDealServiceDashboard: POST /keys { owner: "team-x" }
continuumMarketingDealServiceDashboard -> continuumMarketingDealServiceDashboard: Generate API key value
continuumMarketingDealServiceDashboard -> mdiDashboardPostgres: INSERT INTO api_keys (key, owner, created_at)
mdiDashboardPostgres --> continuumMarketingDealServiceDashboard: OK (row inserted)
continuumMarketingDealServiceDashboard --> User: 200 OK { key: "<new-key>" }
```

## Related

- Architecture dynamic view: `dynamic-mdi-api-key-management`
- Related flows: [Feed Creation and Generation](feed-creation-generation.md)
