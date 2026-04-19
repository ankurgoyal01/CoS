---
service: "ultron-ui"
title: "View Job Dependency Graph"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "view-job-dependency-graph"
flow_type: synchronous
trigger: "Operator opens the dependency view for a specific job"
participants:
  - "continuumUltronUiWeb"
  - "continuumUltronApi"
architecture_ref: "dynamic-ultron-ui-view-job-dependency-graph"
---

# View Job Dependency Graph

## Summary

An operator navigates to the dependency view for a job in the Ultron UI. The AngularJS application requests the dependency graph data from Ultron UI Web, which authenticates via LDAP and proxies the request to `continuumUltronApi`. The returned dependency data is rendered as an interactive directed graph in the browser, allowing the operator to inspect upstream and downstream job relationships.

## Trigger

- **Type**: user-action
- **Source**: Operator selects the dependency graph view for a job in the browser
- **Frequency**: On demand, per operator navigation action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Opens the dependency graph view for a job | — |
| Ultron UI Web | Authenticates the request (LDAP) and proxies it to the API | `continuumUltronUiWeb` |
| Ultron API | Returns the dependency graph structure for the requested job | `continuumUltronApi` |

## Steps

1. **Operator opens dependency view**: The operator selects the dependency graph option for a job; the AngularJS application sends `GET /job/dependency` (with job identifier as query parameter) to Ultron UI Web.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP

2. **LDAP authentication**: The Play controller validates the operator's LDAP credentials.
   - From: `continuumUltronUiWeb`
   - To: LDAP server
   - Protocol: LDAP

3. **Proxies dependency request to Ultron API**: The Play controller forwards `GET /job/dependency` to `continuumUltronApi`.
   - From: `continuumUltronUiWeb`
   - To: `continuumUltronApi`
   - Protocol: HTTP/JSON

4. **Returns dependency graph data**: `continuumUltronApi` responds with JSON representing the nodes and edges of the job dependency graph.
   - From: `continuumUltronApi`
   - To: `continuumUltronUiWeb`
   - Protocol: HTTP/JSON

5. **Returns response to browser**: Ultron UI Web passes the JSON response back to the AngularJS application.
   - From: `continuumUltronUiWeb`
   - To: Browser
   - Protocol: REST HTTP/JSON

6. **Renders dependency graph**: The AngularJS application visualises the dependency data as an interactive directed graph in the browser.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LDAP authentication failure | Play controller rejects request | Operator sees authentication error; dependency graph is not loaded |
| `continuumUltronApi` returns error | Error response passed through to browser | AngularJS displays error message; graph is not rendered |
| `continuumUltronApi` unreachable | HTTP timeout or connection error | AngularJS displays connectivity error to operator |

## Sequence Diagram

```
Operator -> continuumUltronUiWeb: GET /job/dependency
continuumUltronUiWeb -> LDAP: Validate operator credentials
LDAP --> continuumUltronUiWeb: Credentials valid
continuumUltronUiWeb -> continuumUltronApi: GET /job/dependency (HTTP/JSON)
continuumUltronApi --> continuumUltronUiWeb: 200 OK — dependency graph JSON
continuumUltronUiWeb --> Operator: 200 OK — dependency graph JSON
```

## Related

- Architecture dynamic view: `dynamic-ultron-ui-view-job-dependency-graph`
- Related flows: [View Job List](view-job-list.md), [Monitor Job Performance](monitor-job-performance.md)
