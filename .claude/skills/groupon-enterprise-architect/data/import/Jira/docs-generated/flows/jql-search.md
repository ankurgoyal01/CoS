---
service: "jira"
title: "JQL Search"
generated: "2026-03-03"
type: flow
flow_name: "jql-search"
flow_type: synchronous
trigger: "Authenticated user or API client submits a JQL query via the issue navigator or REST API"
participants:
  - "continuumJiraService"
  - "continuumJiraDatabase"
architecture_ref: "components-continuum-jira-service"
---

# JQL Search

## Summary

Jira provides a structured query language (JQL) that allows users and API clients to search for issues using field conditions, functions, and ordering clauses. Queries are parsed by the JQL engine, resolved against the Lucene full-text index and/or MySQL for structured field predicates, and returned as paginated result sets. Result size is capped at 3,000 rows by server configuration. Slow queries are logged separately for performance analysis.

## Trigger

- **Type**: user-action or api-call
- **Source**: Authenticated user in the Issue Navigator (`/secure/IssueNavigator.jspa`) or API client via `GET /rest/api/2/search?jql=...`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `continuumJiraService` | Parses JQL, executes search against Lucene index and MySQL, returns results | `continuumJiraService` |
| `continuumJiraDatabase` | Provides structured field data for non-text predicates and issue metadata | `continuumJiraDatabase` |

## Steps

1. **Authenticates request**: Seraph/GwallAuthenticator verifies the user session or credentials before processing the search request. See [SSO Authentication and User Provisioning](sso-authentication-user-provisioning.md).
   - From: `apiProxy`
   - To: `continuumJiraService`
   - Protocol: HTTPS

2. **Receives JQL query**: The WebWork Issue Navigator action or REST `SearchResource` receives the raw JQL string from the request parameter.
   - From: Authenticated user or API client
   - To: `continuumJiraService`
   - Protocol: HTTPS (GET or POST with `jql` parameter)

3. **Parses JQL**: The JQL parser (`com.atlassian.jira.jql`) tokenizes and parses the query string into an abstract syntax tree. Field names are resolved to Jira field identifiers by `JqlResolver`.
   - From: `continuumJiraService` (JQL engine, internal)
   - To: `continuumJiraService` (internal)
   - Protocol: In-process

4. **Applies permission filtering**: The search provider (`LuceneSearchProvider`) wraps the user query with a permission-based filter to ensure only issues the caller has permission to view are included in results. Permission data is loaded from `continuumJiraDatabase`.
   - From: `continuumJiraService`
   - To: `continuumJiraDatabase`
   - Protocol: JDBC/MySQL

5. **Executes search against Lucene index**: Full-text and most field searches are executed against the on-disk Lucene index in the Jira home directory. Slow queries (exceeding configured threshold) are logged to `atlassian-jira-slow-queries.log` by `LuceneSearchProvider_SLOW`.
   - From: `continuumJiraService`
   - To: Jira home Lucene index (filesystem)
   - Protocol: In-process (Lucene API)

6. **Fetches issue details from database**: For each matched issue ID, `continuumJiraService` fetches full issue data from `continuumJiraDatabase` via OFBiz entity engine for rendering (summary, status, assignee, etc.).
   - From: `continuumJiraService`
   - To: `continuumJiraDatabase`
   - Protocol: JDBC/MySQL

7. **Applies result limits**: Results are capped at `jira.search.views.default.max=3000` (default view) and `jira.search.views.max.limit=3000` (hard cap), as configured in `sys_config/jira-config.properties`.
   - From: `continuumJiraService` (internal)
   - To: `continuumJiraService` (internal)
   - Protocol: In-process

8. **Returns paginated results**: For web UI, renders the Issue Navigator results page. For REST API, returns a JSON object with `issues` array, `total`, `startAt`, and `maxResults` fields.
   - From: `continuumJiraService`
   - To: Caller
   - Protocol: HTTPS (HTML or JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JQL parse error | Returns error message indicating parse failure | No results; user sees JQL syntax error |
| Permission filter excludes all results | Returns empty result set | 0 issues returned; no error |
| Result set exceeds hard limit | Truncated at `jira.search.views.max.limit=3000` | First 3,000 matching issues returned; caller must refine query |
| Slow query detected | Logged to `atlassian-jira-slow-queries.log` | Query completes but performance impact is recorded |
| Lucene index out of sync | Stale or missing results | Admin must trigger a full reindex via Admin > System > Indexing |
| Database connectivity failure | Exception; HTTP 500 or error page | Search unavailable until DB connectivity restored |

## Sequence Diagram

```
User -> continuumJiraService: GET /rest/api/2/search?jql=project=FOO+AND+status=Open
continuumJiraService -> continuumJiraService: Parse JQL (com.atlassian.jira.jql)
continuumJiraService -> continuumJiraDatabase: SELECT permission scheme for user
continuumJiraDatabase --> continuumJiraService: permission data
continuumJiraService -> LuceneIndex: Execute permission-filtered Lucene query
LuceneIndex --> continuumJiraService: issue ID list (max 3000)
continuumJiraService -> continuumJiraDatabase: SELECT issue details for matched IDs
continuumJiraDatabase --> continuumJiraService: issue rows
continuumJiraService --> User: JSON { issues: [...], total: N, startAt: 0, maxResults: 3000 }
```

## Related

- Architecture component view: `components-continuum-jira-service`
- Related flows: [SSO Authentication and User Provisioning](sso-authentication-user-provisioning.md), [Issue Lifecycle](issue-lifecycle.md)
