---
service: "jira"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Jira.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [SSO Authentication and User Provisioning](sso-authentication-user-provisioning.md) | synchronous | Inbound HTTPS request from `apiProxy` with SSO headers | GwallAuthenticator reads identity headers, resolves or auto-creates the Jira user, and establishes a session |
| [Issue Lifecycle](issue-lifecycle.md) | synchronous | Authenticated user creates or transitions an issue via web UI or REST API | Full issue creation-to-resolution workflow including status transitions and notifications |
| [JQL Search](jql-search.md) | synchronous | Authenticated user or API client submits a JQL query | Jira parses JQL, queries MySQL and/or Lucene index, and returns paginated results |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The SSO Authentication flow spans `apiProxy` (Okta/Gwall), `continuumJiraService`, and `continuumJiraDatabase`. See [SSO Authentication and User Provisioning](sso-authentication-user-provisioning.md).
- All flows require `continuumJiraDatabase` to be reachable. Database connectivity is not optional.
