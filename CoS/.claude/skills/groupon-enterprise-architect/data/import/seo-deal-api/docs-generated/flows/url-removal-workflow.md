---
service: "seo-deal-api"
title: "URL Removal Workflow"
generated: "2026-03-03"
type: flow
flow_name: "url-removal-workflow"
flow_type: synchronous
trigger: "POST /url-removal/request called by seo-admin-ui; approval or rejection via subsequent POST calls"
participants:
  - "seo-admin-ui"
  - "continuumSeoDealApiService"
  - "seoDealApi_apiResources"
  - "orchestrator"
  - "seoDataDao"
  - "continuumSeoDealPostgres"
  - "indexNowClient"
architecture_ref: "components-seoDealApiServiceComponents"
---

# URL Removal Workflow

## Summary

The URL Removal Workflow manages the lifecycle of requests to remove deal URLs from search engine indexes. SEO analysts initiate removal requests via `seo-admin-ui`, which calls SEO Deal API to create, search, approve, reject, or update the status of URL removal requests. Requests are persisted to `continuumSeoDealPostgres`. Upon approval, the service may trigger downstream actions such as submitting removal URLs to IndexNow or creating Jira issues. The workflow is entirely synchronous and operator-driven.

## Trigger

- **Type**: api-call
- **Source**: `seo-admin-ui` DealServerClient (`createUrlRemovalRequests`, `getUrlRemovalsRequests`, `approveUrlRemovalRequests`, `rejectUrlRemovalRequests`, `updateUrlRemovalRequestStatus`) — initiated by SEO analyst actions in the admin UI
- **Frequency**: On-demand, per SEO analyst URL removal action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `seo-admin-ui` | Initiates all URL removal API calls on behalf of SEO analysts | External consumer |
| `continuumSeoDealApiService` | Receives, persists, and processes URL removal requests | `continuumSeoDealApiService` |
| API Resources (`seoDealApi_apiResources`) | Handles all inbound HTTP requests for URL removal | `seoDealApi_apiResources` |
| Orchestrator (`orchestrator`) | Coordinates database reads and writes for removal requests | `orchestrator` |
| SEO Data DAO (`seoDataDao`) | Persists URL removal request state to PostgreSQL | `seoDataDao` |
| SEO Deal Database | Stores URL removal requests and their status | `continuumSeoDealPostgres` |
| IndexNow Client (`indexNowClient`) | Submits removed URLs to IndexNow upon approval (inferred from component model) | `indexNowClient` |

## Steps

### Phase 1: Create URL Removal Request

1. **Analyst initiates removal**: SEO analyst selects deal URLs for removal in `seo-admin-ui`; the console calls `POST /url-removal/request` with `{ user: { username }, urls: [...] }`
   - From: `seo-admin-ui`
   - To: `continuumSeoDealApiService`
   - Protocol: REST/HTTP

2. **Validates request**: API Resources validates that `user.username` is present in the request body
   - From: `seoDealApi_apiResources`
   - To: In-process validation
   - Protocol: Direct (in-process)

3. **Persists removal request**: SEO Data DAO inserts a new URL removal request record with status `pending`
   - From: `orchestrator` -> `seoDataDao`
   - To: `continuumSeoDealPostgres`
   - Protocol: JDBC/SQL

4. **Returns created request**: API Resources returns HTTP 200 with the created request data
   - From: `continuumSeoDealApiService`
   - To: `seo-admin-ui`
   - Protocol: REST/HTTP

### Phase 2: Search and Review

5. **Analyst searches requests**: `seo-admin-ui` calls `GET /url-removal/search?limit={n}&offset={n}&requestedBy={user}&status={status}` to list pending requests
   - From: `seo-admin-ui`
   - To: `continuumSeoDealApiService`
   - Protocol: REST/HTTP

6. **Queries PostgreSQL**: SEO Data DAO queries removal requests filtered by `requestedBy` and `status` with `limit`/`offset` pagination
   - From: `seoDataDao`
   - To: `continuumSeoDealPostgres`
   - Protocol: JDBC/SQL

7. **Returns request list**: API Resources returns the matching URL removal requests
   - From: `continuumSeoDealApiService`
   - To: `seo-admin-ui`
   - Protocol: REST/HTTP

### Phase 3: Approve or Reject

8. **Analyst approves requests**: `seo-admin-ui` calls `POST /url-removal/approve` with approval params
   - From: `seo-admin-ui`
   - To: `continuumSeoDealApiService`
   - Protocol: REST/HTTP

   OR

   **Analyst rejects requests**: `seo-admin-ui` calls `POST /url-removal/reject` with rejection params
   - From: `seo-admin-ui`
   - To: `continuumSeoDealApiService`
   - Protocol: REST/HTTP

9. **Updates request status**: SEO Data DAO updates the removal request status to `approved` or `rejected`
   - From: `seoDataDao`
   - To: `continuumSeoDealPostgres`
   - Protocol: JDBC/SQL

10. **Submits to IndexNow (on approval)**: Upon approval, the IndexNow Client submits the approved URLs for removal from search engine indexes
    - From: `indexNowClient`
    - To: `indexNowService`
    - Protocol: REST/HTTP

### Phase 4: Status Update

11. **Analyst updates request status**: `seo-admin-ui` calls `PATCH /url-removal/requests/{requestId}` with `{ requestStatus, observation, user }` to update individual request status
    - From: `seo-admin-ui`
    - To: `continuumSeoDealApiService`
    - Protocol: REST/HTTP

12. **Persists status update**: SEO Data DAO updates the request record with the new status and observation
    - From: `seoDataDao`
    - To: `continuumSeoDealPostgres`
    - Protocol: JDBC/SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `user.username` in create request | `seo-admin-ui` client returns `{ error: true, msg: "You must supply a value for 'username'" }` before calling API | Request not sent |
| API returns HTTP 4xx or 5xx on create | `seo-admin-ui` parses error response body if available, returns `{ error: true, err, responseBody }` | UI shows error to analyst |
| API returns HTTP 4xx on approve/reject | `seo-admin-ui` parses error response, returns `{ error: true, err, responseBody }` | Approval/rejection not persisted |
| IndexNow submission failure on approval | Non-critical; evidenced by side-effect pattern in component model | URL removal request approved in DB; search engine notification may be delayed |

## Sequence Diagram

```
seo-admin-ui -> continuumSeoDealApiService: POST /url-removal/request { user: {username}, urls: [...] }
continuumSeoDealApiService -> continuumSeoDealPostgres: INSERT url_removal_request (status=pending)
continuumSeoDealPostgres --> continuumSeoDealApiService: Request created
continuumSeoDealApiService --> seo-admin-ui: HTTP 200 { request_id, status: "pending" }

seo-admin-ui -> continuumSeoDealApiService: GET /url-removal/search?limit=N&offset=N&status=pending
continuumSeoDealApiService -> continuumSeoDealPostgres: SELECT removal requests WHERE status=pending
continuumSeoDealPostgres --> continuumSeoDealApiService: Matching requests
continuumSeoDealApiService --> seo-admin-ui: HTTP 200 { requests: [...] }

seo-admin-ui -> continuumSeoDealApiService: POST /url-removal/approve { request_ids: [...] }
continuumSeoDealApiService -> continuumSeoDealPostgres: UPDATE url_removal_request SET status=approved
continuumSeoDealPostgres --> continuumSeoDealApiService: Updated
continuumSeoDealApiService -> indexNowClient: Submit approved URLs for removal
indexNowClient -> indexNowService: POST URL removal request
continuumSeoDealApiService --> seo-admin-ui: HTTP 200 (approved)
```

## Related

- Architecture dynamic view: `components-seoDealApiServiceComponents`
- Related flows: [Deal SEO Attribute Update](deal-seo-attribute-update.md), [Deal SEO Attribute Read](deal-seo-attribute-read.md)
