---
service: "ultron-ui"
title: "Manage User Groups"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "manage-user-groups"
flow_type: synchronous
trigger: "Operator creates, edits, or deletes a job group in the UI"
participants:
  - "continuumUltronUiWeb"
  - "continuumUltronApi"
architecture_ref: "dynamic-ultron-ui-manage-user-groups"
---

# Manage User Groups

## Summary

Operators use the Ultron UI to organise jobs into groups. This flow covers all CRUD operations on job groups: listing existing groups, creating a new group, updating a group's details, and deleting a group. Each operation is authenticated via LDAP and proxied by the Play controllers to `continuumUltronApi`, which owns the group data.

## Trigger

- **Type**: user-action
- **Source**: Operator interacts with the group management section of the browser UI (list, create, edit, or delete a group)
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (browser) | Initiates group CRUD operations | — |
| Ultron UI Web | Authenticates requests (LDAP) and proxies group operations to the API | `continuumUltronUiWeb` |
| Ultron API | Executes group CRUD operations and persists group metadata | `continuumUltronApi` |

## Steps

### List Groups

1. **Operator navigates to groups**: The AngularJS application sends `GET /groups` to Ultron UI Web.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP

2. **LDAP authentication**: The Play controller validates the operator's LDAP credentials.
   - From: `continuumUltronUiWeb`
   - To: LDAP server
   - Protocol: LDAP

3. **Proxies list request to Ultron API**: The Play controller forwards `GET /groups` to `continuumUltronApi`.
   - From: `continuumUltronUiWeb`
   - To: `continuumUltronApi`
   - Protocol: HTTP/JSON

4. **Returns group list**: `continuumUltronApi` responds with a JSON array of group records.
   - From: `continuumUltronApi`
   - To: `continuumUltronUiWeb`
   - Protocol: HTTP/JSON

5. **Renders group list**: Ultron UI Web returns the response to the browser; AngularJS renders the list of groups.

### Create Group

1. **Operator submits new group form**: The AngularJS application sends `POST /groups` with the group definition JSON.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP/JSON

2. **LDAP authentication**: Play controller validates credentials.

3. **Proxies creation to Ultron API**: Play controller forwards `POST /groups` to `continuumUltronApi`.
   - From: `continuumUltronUiWeb`
   - To: `continuumUltronApi`
   - Protocol: HTTP/JSON

4. **Persists new group**: `continuumUltronApi` creates the group and returns the created record.

5. **Confirms creation**: AngularJS displays success and refreshes the group list.

### Update Group

1. **Operator submits group edit form**: The AngularJS application sends `PUT /groups` with the updated group payload.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP/JSON

2. Steps 2–5 follow the same LDAP auth and proxy pattern; `continuumUltronApi` persists the update.

### Delete Group

1. **Operator confirms group deletion**: The AngularJS application sends `DELETE /groups` with the group identifier.
   - From: Browser
   - To: `continuumUltronUiWeb`
   - Protocol: REST HTTP/JSON

2. Steps 2–5 follow the same LDAP auth and proxy pattern; `continuumUltronApi` removes the group.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LDAP authentication failure | Play controller rejects request | Operator sees authentication error; operation is not performed |
| Invalid payload (create/update) | `continuumUltronApi` returns validation error | AngularJS displays validation errors; group is unchanged |
| Delete of non-empty group | `continuumUltronApi` may return conflict error | AngularJS displays error; operator must reassign or remove jobs first |
| `continuumUltronApi` unreachable | HTTP timeout or connection error | AngularJS displays connectivity error; operator must retry |

## Sequence Diagram

```
Operator -> continuumUltronUiWeb: GET /groups (or POST/PUT/DELETE)
continuumUltronUiWeb -> LDAP: Validate operator credentials
LDAP --> continuumUltronUiWeb: Credentials valid
continuumUltronUiWeb -> continuumUltronApi: GET /groups (HTTP/JSON)
continuumUltronApi --> continuumUltronUiWeb: 200 OK — group data JSON
continuumUltronUiWeb --> Operator: 200 OK — group data JSON
```

## Related

- Architecture dynamic view: `dynamic-ultron-ui-manage-user-groups`
- Related flows: [View Job List](view-job-list.md), [Create Job](create-job.md)
