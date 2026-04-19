---
service: "mdi-dashboard-v2"
title: "Feed Creation and Generation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "feed-creation-generation"
flow_type: synchronous
trigger: "User creates a feed configuration and/or triggers feed generation via the /feeds route"
participants:
  - "continuumMarketingDealServiceDashboard"
  - "mdiDashboardPostgres"
  - "apiProxy"
architecture_ref: "dynamic-mdi-feed-creation-generation"
---

# Feed Creation and Generation

## Summary

The feed creation and generation flow enables Merchandising users to define deal feed configurations and trigger feed export jobs. Users create and manage feed configurations (stored in PostgreSQL) that specify deal selection criteria and output format. When a user triggers generation, the dashboard reads the configuration from PostgreSQL and dispatches a generation request to the MDS Feed Service for execution.

## Trigger

- **Type**: user-action
- **Source**: User interacts with the feed builder UI at `GET /feeds`, `POST /feeds`, `PUT /feeds`, `DELETE /feeds`, or `POST /feeds/generate`
- **Frequency**: on-demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MDI Dashboard | Receives user requests; manages feed configuration CRUD; dispatches generation jobs | `continuumMarketingDealServiceDashboard` |
| MDI Dashboard PostgreSQL | Persists feed configuration records | `mdiDashboardPostgres` |
| API Proxy | Routes outbound HTTP calls to MDS Feed Service | `apiProxy` |
| MDS Feed Service | Executes feed generation jobs based on the provided configuration | > No Structurizr ID confirmed in inventory |

## Steps

### Create Feed Configuration

1. **Receives creation request**: User submits `POST /feeds` with feed name and configuration payload.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Validates feed configuration**: Dashboard validates the configuration payload structure.
   - From: `continuumMarketingDealServiceDashboard`
   - To: in-process validation
   - Protocol: in-process

4. **Persists feed configuration**: Dashboard inserts a new row into the `feeds` table via Sequelize.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `mdiDashboardPostgres`
   - Protocol: PostgreSQL

5. **Returns confirmation**: Dashboard renders the feed detail page with the newly created configuration.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML or JSON response)

### Trigger Feed Generation

1. **Receives generation request**: User submits `POST /feeds/generate` with the feed ID to generate.
   - From: `Browser (internal user)`
   - To: `continuumMarketingDealServiceDashboard`
   - Protocol: REST / HTTP

2. **Authenticates request**: itier-user-auth middleware validates user session.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `itier-user-auth middleware`
   - Protocol: in-process

3. **Reads feed configuration from PostgreSQL**: Dashboard retrieves the feed configuration row for the given feed ID via Sequelize.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `mdiDashboardPostgres`
   - Protocol: PostgreSQL

4. **Submits generation job to MDS Feed Service**: Dashboard constructs a generation request from the feed configuration and sends it to the MDS Feed Service via the API Proxy.
   - From: `continuumMarketingDealServiceDashboard`
   - To: `apiProxy` -> MDS Feed Service
   - Protocol: REST / HTTP

5. **Returns generation status**: MDS Feed Service acknowledges the job submission; dashboard renders status confirmation to the user.
   - From: MDS Feed Service -> `apiProxy` -> `continuumMarketingDealServiceDashboard`
   - To: `Browser (internal user)`
   - Protocol: HTTP (HTML or JSON response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL connection failure on write | Sequelize error propagated | Feed configuration not saved; user sees error |
| Feed configuration not found on generation | Sequelize returns null; 404 returned | User informed the feed does not exist |
| MDS Feed Service returns 5xx | HTTP error propagated to user | Generation job not submitted; user sees error; configuration unchanged |
| MDS Feed Service timeout | HTTP client timeout | Generation status unknown; user advised to retry |
| Authentication failure | itier-user-auth redirects to login | User redirected to Groupon SSO login |
| Invalid configuration payload | Validation error returned | User sees validation error; no write to PostgreSQL |

## Sequence Diagram

```
User -> continuumMarketingDealServiceDashboard: POST /feeds/generate { feedId: "abc" }
continuumMarketingDealServiceDashboard -> mdiDashboardPostgres: SELECT * FROM feeds WHERE id = 'abc'
mdiDashboardPostgres --> continuumMarketingDealServiceDashboard: { id: "abc", config: {...} }
continuumMarketingDealServiceDashboard -> apiProxy: POST /feeds/generate { config: {...} }
apiProxy -> MdsFeedService: POST /generate { config: {...} }
MdsFeedService --> apiProxy: 202 Accepted { jobId: "xyz" }
apiProxy --> continuumMarketingDealServiceDashboard: 202 Accepted { jobId: "xyz" }
continuumMarketingDealServiceDashboard --> User: 200 OK (generation submitted, jobId: "xyz")
```

## Related

- Architecture dynamic view: `dynamic-mdi-feed-creation-generation`
- Related flows: [API Key Management](api-key-management.md), [Deal Intelligence Search](deal-intelligence-search.md)
