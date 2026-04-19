---
service: "ultron-ui"
title: "Create Job"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "create-job"
flow_type: synchronous
trigger: "Operator submits the create-job form in the UI"
participants:
  - "continuumUltronUiWeb"
  - "continuumUltronApi"
architecture_ref: "dynamic-ultron-ui-create-job"
---

# Create Job

## Summary

An operator fills in the create-job form in the Ultron UI and submits it. The AngularJS application posts the job definition to Ultron UI Web, which authenticates the operator via LDAP and forwards the payload to `continuumUltronApi` to persist the new job. A success or error response is surfaced back to the operator.

## Trigger

- **Type**: user-action
- **Source**: Operator completes and submits the create-job form in the browser
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Provides job definition data and initiates submission | — |
| Ultron UI Web | Authenticates the request (LDAP) and proxies creation payload to the API | `continuumUltronUiWeb` |
| Ultron API | Validates and persists the new job definition | `continuumUltronApi` |

## Steps

1. **Operator submits form**: The operator completes the job creation form; the AngularJS application sends `POST /job/create` with the job definition as a JSON body to Ultron UI Web.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP/JSON

2. **LDAP authentication**: The Play controller validates the operator's LDAP credentials.
   - From: `continuumUltronUiWeb`
   - To: LDAP server
   - Protocol: LDAP

3. **Proxies creation request to Ultron API**: The Play controller forwards `POST /job/create` with the job payload to `continuumUltronApi`.
   - From: `continuumUltronUiWeb`
   - To: `continuumUltronApi`
   - Protocol: HTTP/JSON

4. **Persists job definition**: `continuumUltronApi` validates the payload and stores the new job definition; returns a success response (typically the created job record or a confirmation).
   - From: `continuumUltronApi`
   - To: `continuumUltronUiWeb`
   - Protocol: HTTP/JSON

5. **Returns result to browser**: Ultron UI Web passes the API response back to the AngularJS application.
   - From: `continuumUltronUiWeb`
   - To: Browser
   - Protocol: REST HTTP/JSON

6. **Displays confirmation**: The AngularJS application presents a success message and optionally navigates the operator to the new job's detail view.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LDAP authentication failure | Play controller rejects request | Operator sees authentication error; no API call is made |
| Invalid job payload | `continuumUltronApi` returns validation error | AngularJS displays field-level or summary validation errors to operator |
| `continuumUltronApi` returns error | Error response passed through to browser | AngularJS displays error message; no job is created |
| `continuumUltronApi` unreachable | HTTP timeout or connection error | AngularJS displays connectivity error; operator must retry |

## Sequence Diagram

```
Operator -> continuumUltronUiWeb: POST /job/create (JSON body)
continuumUltronUiWeb -> LDAP: Validate operator credentials
LDAP --> continuumUltronUiWeb: Credentials valid
continuumUltronUiWeb -> continuumUltronApi: POST /job/create (HTTP/JSON)
continuumUltronApi --> continuumUltronUiWeb: 201 Created — new job record
continuumUltronUiWeb --> Operator: 201 Created — new job record
```

## Related

- Architecture dynamic view: `dynamic-ultron-ui-create-job`
- Related flows: [View Job List](view-job-list.md), [Manage User Groups](manage-user-groups.md)
