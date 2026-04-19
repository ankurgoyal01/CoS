---
service: "ultron-ui"
title: "Update Job Instance"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "update-job-instance"
flow_type: synchronous
trigger: "Operator updates the status or metadata of a running or completed job instance"
participants:
  - "continuumUltronUiWeb"
  - "continuumUltronApi"
architecture_ref: "dynamic-ultron-ui-update-job-instance"
---

# Update Job Instance

## Summary

An operator makes a status or metadata change to an existing job execution instance via the Ultron UI. The AngularJS application submits the update to Ultron UI Web, which authenticates the operator via LDAP and forwards the update payload to `continuumUltronApi`. The API applies the change and returns the updated instance record.

## Trigger

- **Type**: user-action
- **Source**: Operator submits an instance update action in the browser (e.g., marking an instance as resolved or updating its metadata)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Submits an update to a job instance | — |
| Ultron UI Web | Authenticates the request (LDAP) and proxies the update to the API | `continuumUltronUiWeb` |
| Ultron API | Applies the instance update and returns the updated record | `continuumUltronApi` |

## Steps

1. **Operator submits instance update**: The operator modifies instance fields and submits; the AngularJS application sends `PUT /instance/update` with the update payload to Ultron UI Web.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP/JSON

2. **LDAP authentication**: The Play controller validates the operator's LDAP credentials.
   - From: `continuumUltronUiWeb`
   - To: LDAP server
   - Protocol: LDAP

3. **Proxies update to Ultron API**: The Play controller forwards `PUT /instance/update` with the payload to `continuumUltronApi`.
   - From: `continuumUltronUiWeb`
   - To: `continuumUltronApi`
   - Protocol: HTTP/JSON

4. **Applies instance update**: `continuumUltronApi` validates and persists the change; returns the updated instance record.
   - From: `continuumUltronApi`
   - To: `continuumUltronUiWeb`
   - Protocol: HTTP/JSON

5. **Returns result to browser**: Ultron UI Web passes the API response back to the AngularJS application.
   - From: `continuumUltronUiWeb`
   - To: Browser
   - Protocol: REST HTTP/JSON

6. **Reflects updated instance state**: The AngularJS application updates the displayed instance record with the latest data.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LDAP authentication failure | Play controller rejects request | Operator sees authentication error; update is not applied |
| Invalid update payload | `continuumUltronApi` returns validation error | AngularJS displays validation error; instance is unchanged |
| `continuumUltronApi` returns error | Error response passed through to browser | AngularJS displays error message; operator must retry |
| `continuumUltronApi` unreachable | HTTP timeout or connection error | AngularJS displays connectivity error; update is not applied |

## Sequence Diagram

```
Operator -> continuumUltronUiWeb: PUT /instance/update (JSON body)
continuumUltronUiWeb -> LDAP: Validate operator credentials
LDAP --> continuumUltronUiWeb: Credentials valid
continuumUltronUiWeb -> continuumUltronApi: PUT /instance/update (HTTP/JSON)
continuumUltronApi --> continuumUltronUiWeb: 200 OK — updated instance record
continuumUltronUiWeb --> Operator: 200 OK — updated instance record
```

## Related

- Architecture dynamic view: `dynamic-ultron-ui-update-job-instance`
- Related flows: [View Job List](view-job-list.md), [Monitor Job Performance](monitor-job-performance.md)
