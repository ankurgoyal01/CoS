---
service: "deal-management-api"
title: "Write Request Tracking"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "write-request-tracking"
flow_type: synchronous
trigger: "Any write operation (POST/PUT/DELETE) against deal resources"
participants:
  - "continuumDealManagementApi"
  - "continuumDealManagementMysql"
architecture_ref: "dynamic-writeRequestTracking"
---

# Write Request Tracking

## Summary

Write request tracking is a cross-cutting audit capability that records every tracked write operation against deal resources into a persistent log. For every state-mutating request (create, update, delete, publish, unpublish, pause, approve), DMAPI writes an entry to the `write_requests` table in MySQL capturing the operation type, the target resource, the actor, and a timestamp. This log is subsequently queryable via `GET /write_requests` and contributes to deal change history accessible via `GET /history`.

## Trigger

- **Type**: api-call (cross-cutting — applied to all write paths)
- **Source**: Any caller performing a write operation via the DMAPI REST API
- **Frequency**: Per write request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Captures write context and persists audit record | `continuumDealManagementApi` |
| Deal Management MySQL | Stores write_requests and history records | `continuumDealManagementMysql` |

## Steps

1. **Intercepted write request**: A state-mutating request (POST, PUT, DELETE) arrives at the API on any deal resource endpoint.
   - From: Calling client
   - To: `continuumDealManagementApi` (`apiControllers`)
   - Protocol: REST/HTTPS

2. **Extract write context**: The API extracts operation metadata — resource type, resource ID, operation name, requesting actor identity, and request timestamp.
   - From: `apiControllers` (internal middleware or concern)
   - To: in-process
   - Protocol: in-process

3. **Execute primary operation**: The primary domain operation (create, update, delete, state transition) is performed as normal.
   - From: `continuumDealManagementApi` (`persisterServices`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

4. **Persist write_request record**: Repositories write an audit entry to the `write_requests` table recording the operation details.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

5. **Persist history record (if applicable)**: For significant state changes, a diff entry is appended to the `history` table.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

6. **Return primary operation response**: API Controllers return the response from the primary operation to the caller.
   - From: `continuumDealManagementApi`
   - To: Calling client
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Primary operation fails | Primary operation error returned; audit write may or may not complete depending on transaction scope | Depends on transaction boundary design |
| write_requests insert fails | Log error; do not surface audit failure to caller (audit is best-effort) | Primary operation succeeds; audit record may be missing |
| history insert fails | Log error; non-blocking | Primary operation succeeds; history record may be incomplete |

## Sequence Diagram

```
Client -> continuumDealManagementApi: POST/PUT/DELETE /v1/deals/:id/{action}
continuumDealManagementApi -> continuumDealManagementApi: extract write context (resource, actor, timestamp)
continuumDealManagementApi -> continuumDealManagementMysql: execute primary domain operation
continuumDealManagementMysql --> continuumDealManagementApi: result
continuumDealManagementApi -> continuumDealManagementMysql: INSERT write_requests (resource_type, resource_id, operation, actor, timestamp)
continuumDealManagementMysql --> continuumDealManagementApi: write_request_id
continuumDealManagementApi -> continuumDealManagementMysql: INSERT history (entity diff, changed_by, changed_at)
continuumDealManagementMysql --> continuumDealManagementApi: history_id
continuumDealManagementApi --> Client: primary operation response
```

## Related

- Architecture dynamic view: `dynamic-writeRequestTracking`
- Related flows: [Deal Create (Sync)](deal-create-sync.md), [Deal Publish Workflow](deal-publish-workflow.md), [Deal Approval Workflow](deal-approval-workflow.md)
