---
service: "ultron-ui"
title: "View Job List"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "view-job-list"
flow_type: synchronous
trigger: "Operator selects a job group in the browser UI"
participants:
  - "continuumUltronUiWeb"
  - "continuumUltronApi"
architecture_ref: "dynamic-ultron-ui-view-job-list"
---

# View Job List

## Summary

When an operator selects a job group in the Ultron UI, the AngularJS application requests the list of jobs for that group. The Play controller authenticates the request via LDAP and forwards it to `continuumUltronApi`. The returned job list is rendered in the browser as a table of job entries.

## Trigger

- **Type**: user-action
- **Source**: Operator clicks or selects a group in the Ultron UI browser application
- **Frequency**: On demand, per operator navigation action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Initiates the request by selecting a group | — |
| Ultron UI Web | Authenticates the request (LDAP) and proxies it to the API | `continuumUltronUiWeb` |
| Ultron API | Returns the list of jobs for the requested group | `continuumUltronApi` |

## Steps

1. **Operator selects group**: The operator clicks a group entry in the UI; the AngularJS application sends `GET /job/list/:groupId` to Ultron UI Web.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP

2. **LDAP authentication**: The Play controller (`playControllers`) validates the operator's LDAP credentials.
   - From: `continuumUltronUiWeb`
   - To: LDAP server
   - Protocol: LDAP

3. **Forward request to Ultron API**: The Play controller proxies `GET /job/list/:groupId` to `continuumUltronApi`.
   - From: `continuumUltronUiWeb`
   - To: `continuumUltronApi`
   - Protocol: HTTP/JSON

4. **Receives job list**: `continuumUltronApi` returns a JSON array of job records for the given group.
   - From: `continuumUltronApi`
   - To: `continuumUltronUiWeb`
   - Protocol: HTTP/JSON

5. **Returns response to browser**: Ultron UI Web passes the JSON response back to the AngularJS application.
   - From: `continuumUltronUiWeb`
   - To: Browser
   - Protocol: REST HTTP/JSON

6. **Renders job table**: The AngularJS application binds the response data and renders the job list in the browser.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LDAP authentication failure | Play controller rejects request | Operator sees authentication error; no API call is made |
| `continuumUltronApi` returns error | Error response passed through to browser | AngularJS displays error message to operator |
| `continuumUltronApi` unreachable | HTTP timeout or connection error | AngularJS displays connectivity error to operator |

## Sequence Diagram

```
Operator -> continuumUltronUiWeb: GET /job/list/:groupId
continuumUltronUiWeb -> LDAP: Validate operator credentials
LDAP --> continuumUltronUiWeb: Credentials valid
continuumUltronUiWeb -> continuumUltronApi: GET /job/list/:groupId (HTTP/JSON)
continuumUltronApi --> continuumUltronUiWeb: 200 OK — JSON array of jobs
continuumUltronUiWeb --> Operator: 200 OK — JSON array of jobs
```

## Related

- Architecture dynamic view: `dynamic-ultron-ui-view-job-list`
- Related flows: [Create Job](create-job.md), [View Job Dependency Graph](view-job-dependency-graph.md), [Manage User Groups](manage-user-groups.md)
