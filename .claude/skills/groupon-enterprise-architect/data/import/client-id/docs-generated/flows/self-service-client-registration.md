---
service: "client-id"
title: "Self-Service Client Registration"
generated: "2026-03-03"
type: flow
flow_name: "self-service-client-registration"
flow_type: synchronous
trigger: "Developer submits self-service form"
participants:
  - "continuumClientIdService"
  - "continuumClientIdApiResources"
  - "continuumClientIdJiraGateway"
  - "continuumClientIdPersistence"
  - "continuumClientIdDatabase"
architecture_ref: "dynamic-continuum-client-id"
---

# Self-Service Client Registration

## Summary

The self-service flow allows internal Groupon developers to request a new API client and access token without requiring an admin to manually create the records. The developer fills out the `/self-service/newClientToken` form; Client ID Service creates the client and token records in MySQL and simultaneously creates a Jira issue via the Jira REST API to provide a support ticket for admin review. The Jira ticket identifies the requesting user via internal SSO headers.

## Trigger

- **Type**: user-action (developer via self-service UI)
- **Source**: Authenticated internal Groupon developer via browser
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Developer | Requests new client + token via self-service form | External actor |
| API Resources | Handles HTTP request; orchestrates persistence and Jira calls | `continuumClientIdApiResources` |
| Jira Gateway | Creates Jira issue for support tracking | `continuumClientIdJiraGateway` |
| Persistence Layer | Inserts client and token records into MySQL | `continuumClientIdPersistence` |
| MySQL Primary | Stores new client and token records | `continuumClientIdDatabase` |
| Jira REST API | Receives issue creation request | `jiraServiceApi` (external) |

## Steps

1. **Developer loads self-service form**: Developer navigates to `GET /self-service/newClientToken`. Client ID Service renders the `SelfServiceClientView` HTML form showing available client roles and token status options.
   - From: Developer browser
   - To: `continuumClientIdService`
   - Protocol: REST (HTTP, `text/html`)

2. **Developer submits registration request**: Developer fills out the form with their intended client configuration and submits `POST /self-service/newClientToken`.
   - From: Developer browser
   - To: `continuumClientIdApiResources`
   - Protocol: REST (HTTP form POST)

3. **Create client and token records**: API Resources delegates to the Persistence Layer to insert the new client record (via `ClientDao`) and a corresponding token record (via `TokenDao`) into the primary MySQL instance.
   - From: `continuumClientIdApiResources`
   - To: `continuumClientIdPersistence` → `continuumClientIdDatabase`
   - Protocol: JDBI / MySQL

4. **Create Jira support ticket**: API Resources delegates to the Jira Gateway component. The Jira Gateway builds a JSON payload and calls `POST {jiraServiceClientHost}/rest/api/2/issue` with internal SSO headers (`X-GRPN-SamAccountName`, `X-Remote-User`, `X-OpenID-Extras`) identifying the requesting developer.
   - From: `continuumClientIdApiResources`
   - To: `continuumClientIdJiraGateway`
   - Protocol: In-process

5. **Jira issue created**: Jira REST API returns the created issue key (`IssueResponse`). The Jira Gateway returns the issue reference to API Resources.
   - From: `continuumClientIdJiraGateway`
   - To: Jira REST API
   - Protocol: HTTPS / JSON (`rest/api/2/issue`)

6. **Response returned to developer**: API Resources returns confirmation to the developer with the newly created client/token information.
   - From: `continuumClientIdApiResources`
   - To: Developer browser
   - Protocol: REST (HTTP)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jira API returns 400 Bad Request | `JiraRestClient` throws `WebApplicationException` with error message from `JiraError` response | HTTP 400 returned to developer |
| Jira API unavailable (connection timeout 2s / read timeout 1s) | `WebApplicationException` thrown | HTTP 5xx returned; client/token records may already be persisted in MySQL |
| MySQL primary unavailable | HikariCP connection timeout | HTTP 500; no records created |
| Unauthorised developer | OGWall filter blocks request | HTTP 403 before any processing |

## Sequence Diagram

```
Developer -> continuumClientIdService: GET /self-service/newClientToken
continuumClientIdService --> Developer: HTML form (SelfServiceClientView)
Developer -> continuumClientIdApiResources: POST /self-service/newClientToken (clientConfig)
continuumClientIdApiResources -> continuumClientIdPersistence: insertClient(client)
continuumClientIdPersistence -> continuumClientIdDatabase: INSERT INTO api_clients
continuumClientIdDatabase --> continuumClientIdPersistence: new client id
continuumClientIdApiResources -> continuumClientIdPersistence: insertToken(token)
continuumClientIdPersistence -> continuumClientIdDatabase: INSERT INTO api_tokens
continuumClientIdDatabase --> continuumClientIdPersistence: new token id
continuumClientIdApiResources -> continuumClientIdJiraGateway: createIssue(reporter, payload)
continuumClientIdJiraGateway -> jiraServiceApi: POST /rest/api/2/issue (X-GRPN-SamAccountName: <user>)
jiraServiceApi --> continuumClientIdJiraGateway: IssueResponse (issue key)
continuumClientIdJiraGateway --> continuumClientIdApiResources: IssueResponse
continuumClientIdApiResources --> Developer: HTTP 200 (client + token + Jira issue ref)
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [Client and Token Registration](client-token-registration.md)
- Integrations: [Jira REST API](../integrations.md)
