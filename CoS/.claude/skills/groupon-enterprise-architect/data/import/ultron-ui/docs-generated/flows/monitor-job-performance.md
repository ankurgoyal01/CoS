---
service: "ultron-ui"
title: "Monitor Job Performance"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "monitor-job-performance"
flow_type: synchronous
trigger: "Operator opens the performance or trend view for a job"
participants:
  - "continuumUltronUiWeb"
  - "continuumUltronApi"
architecture_ref: "dynamic-ultron-ui-monitor-job-performance"
---

# Monitor Job Performance

## Summary

An operator opens the performance monitoring view for a job in the Ultron UI to inspect execution trend data. The AngularJS application requests trend data from Ultron UI Web, which authenticates via LDAP and proxies the request to `continuumUltronApi`. The returned historical execution metrics are rendered as charts or trend tables in the browser.

## Trigger

- **Type**: user-action
- **Source**: Operator selects the performance or trend view for a job in the browser
- **Frequency**: On demand, per operator navigation action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Opens the performance trend view for a job | — |
| Ultron UI Web | Authenticates the request (LDAP) and proxies it to the API | `continuumUltronUiWeb` |
| Ultron API | Returns historical execution trend data for the job | `continuumUltronApi` |

## Steps

1. **Operator opens performance view**: The operator navigates to the trend/performance view for a specific job; the AngularJS application sends `GET /job/trend` (with job identifier as query parameter) to Ultron UI Web.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP

2. **LDAP authentication**: The Play controller validates the operator's LDAP credentials.
   - From: `continuumUltronUiWeb`
   - To: LDAP server
   - Protocol: LDAP

3. **Proxies trend request to Ultron API**: The Play controller forwards `GET /job/trend` to `continuumUltronApi`.
   - From: `continuumUltronUiWeb`
   - To: `continuumUltronApi`
   - Protocol: HTTP/JSON

4. **Returns trend data**: `continuumUltronApi` responds with JSON containing historical execution metrics (e.g., run durations, success/failure counts over time).
   - From: `continuumUltronApi`
   - To: `continuumUltronUiWeb`
   - Protocol: HTTP/JSON

5. **Returns response to browser**: Ultron UI Web passes the JSON response back to the AngularJS application.
   - From: `continuumUltronUiWeb`
   - To: Browser
   - Protocol: REST HTTP/JSON

6. **Renders trend visualisation**: The AngularJS application renders the trend data as charts or tables for the operator to review.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LDAP authentication failure | Play controller rejects request | Operator sees authentication error; trend data is not loaded |
| `continuumUltronApi` returns error | Error response passed through to browser | AngularJS displays error message; no trend data is shown |
| `continuumUltronApi` unreachable | HTTP timeout or connection error | AngularJS displays connectivity error to operator |

## Sequence Diagram

```
Operator -> continuumUltronUiWeb: GET /job/trend
continuumUltronUiWeb -> LDAP: Validate operator credentials
LDAP --> continuumUltronUiWeb: Credentials valid
continuumUltronUiWeb -> continuumUltronApi: GET /job/trend (HTTP/JSON)
continuumUltronApi --> continuumUltronUiWeb: 200 OK — trend data JSON
continuumUltronUiWeb --> Operator: 200 OK — trend data JSON
```

## Related

- Architecture dynamic view: `dynamic-ultron-ui-monitor-job-performance`
- Related flows: [View Job List](view-job-list.md), [View Job Dependency Graph](view-job-dependency-graph.md), [Update Job Instance](update-job-instance.md)
