---
service: "jira"
title: "Issue Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "issue-lifecycle"
flow_type: synchronous
trigger: "Authenticated user creates, updates, or transitions a Jira issue via web UI or REST API"
participants:
  - "continuumJiraService"
  - "continuumJiraDatabase"
architecture_ref: "components-continuum-jira-service"
---

# Issue Lifecycle

## Summary

An issue in Jira moves through a defined workflow from creation to resolution. Authenticated users interact with the issue through the web UI or REST API. Each state transition is validated by the configured workflow and persisted to the MySQL database. Email notifications are dispatched asynchronously via Jira's mail subsystem. The Lucene full-text index is updated in-process after each write.

## Trigger

- **Type**: user-action or api-call
- **Source**: Authenticated Groupon engineer or automated tool interacting with `http://jira.groupondev.com`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `continuumJiraService` | Processes issue create/update/transition requests; enforces workflow rules; dispatches notifications | `continuumJiraService` |
| `continuumJiraDatabase` | Persists issue state, comments, transitions, and audit log | `continuumJiraDatabase` |

## Steps

1. **Authenticates request**: Every request passes through the Seraph filter and `GwallAuthenticator`. See [SSO Authentication and User Provisioning](sso-authentication-user-provisioning.md) for the full authentication flow.
   - From: `apiProxy`
   - To: `continuumJiraService`
   - Protocol: HTTPS

2. **Receives issue create or transition action**: User submits a WebWork action (e.g., `CreateIssue.jspa`) or REST call (`POST /rest/api/2/issue`). The WebWork dispatcher or Jersey REST layer routes the request to the appropriate action handler.
   - From: Authenticated user
   - To: `continuumJiraService`
   - Protocol: HTTPS (form POST or REST JSON)

3. **Validates input and permissions**: Jira validates required fields (summary, project, issue type), checks the user's project role and permission scheme, and validates any workflow conditions or validators defined for the target transition.
   - From: `continuumJiraService`
   - To: `continuumJiraDatabase` (permission scheme and project config lookups)
   - Protocol: JDBC/MySQL

4. **Persists issue or transition**: Writes the new issue record or updates the existing `jiraissue` row (status, assignee, resolution, etc.) to `continuumJiraDatabase`. Workflow post-functions (e.g., set resolution, assign to reporter) are executed in-process.
   - From: `continuumJiraService`
   - To: `continuumJiraDatabase`
   - Protocol: JDBC/MySQL

5. **Updates Lucene index**: `DefaultIndexManager` updates the on-disk Lucene index to reflect the new or changed issue. This enables JQL full-text search.
   - From: `continuumJiraService` (internal)
   - To: Jira home Lucene index (filesystem)
   - Protocol: In-process

6. **Dispatches email notification**: Jira's mail subsystem evaluates notification schemes and queues outgoing emails (e.g., "Issue Created", "Issue Updated", "Issue Transitioned") for affected watchers, assignees, and reporters. Outgoing mail is logged to `atlassian-jira-outgoing-mail.log`.
   - From: `continuumJiraService`
   - To: Configured SMTP server
   - Protocol: SMTP

7. **Returns response**: For web UI, Jira redirects to the issue view page. For REST API, returns HTTP 201 (create) or 204 (transition) with the issue key and self link.
   - From: `continuumJiraService`
   - To: Caller
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Permission denied | Jira returns HTTP 403 or renders "Permission Violation" page | Issue not created; user informed |
| Workflow transition not allowed | Transition is not shown or returns validation error | Issue state unchanged; user sees error message |
| Database write failure | Exception logged; HTTP 500 or error page returned | Issue not persisted; user must retry |
| Mail delivery failure | Logged to `atlassian-jira-outgoing-mail.log`; retried by mail service | Issue persisted; notification may be delayed or lost |
| XSRF token mismatch | Forwarded to `/secure/XsrfErrorAction.jspa` | Form submission rejected; user must resubmit |

## Sequence Diagram

```
User -> continuumJiraService: POST /secure/CreateIssue.jspa (or REST)
continuumJiraService -> continuumJiraDatabase: SELECT permission scheme, project config
continuumJiraDatabase --> continuumJiraService: permission data
continuumJiraService -> continuumJiraService: Validate fields and permissions
continuumJiraService -> continuumJiraDatabase: INSERT into jiraissue / UPDATE jiraissue
continuumJiraDatabase --> continuumJiraService: OK
continuumJiraService -> continuumJiraService: Update Lucene index (DefaultIndexManager)
continuumJiraService -> SMTPServer: Send notification emails
continuumJiraService --> User: HTTP 201 / redirect to issue view
```

## Related

- Architecture component view: `components-continuum-jira-service`
- Related flows: [SSO Authentication and User Provisioning](sso-authentication-user-provisioning.md), [JQL Search](jql-search.md)
