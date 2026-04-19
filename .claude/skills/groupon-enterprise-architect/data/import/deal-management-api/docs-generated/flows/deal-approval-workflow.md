---
service: "deal-management-api"
title: "Deal Approval Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-approval-workflow"
flow_type: synchronous
trigger: "HTTP POST to /v1/deals/:id/approve"
participants:
  - "continuumDealManagementApi"
  - "continuumDealManagementMysql"
  - "salesForce"
architecture_ref: "dynamic-dealApprovalWorkflow"
---

# Deal Approval Workflow

## Summary

The deal approval workflow handles the submission of a deal for internal review and approval. When invoked, the API validates that the deal is in an approvable state, transitions the deal's state to an approval-pending status in MySQL, and notifies Salesforce so that the CRM reflects the updated deal status. Approved deals are subsequently eligible for publish via the [Deal Publish Workflow](deal-publish-workflow.md).

## Trigger

- **Type**: api-call
- **Source**: Deal setup tooling or operator submitting a deal for review
- **Frequency**: On demand (per approval submission)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Validates eligibility, transitions state | `continuumDealManagementApi` |
| Deal Management MySQL | Stores updated deal approval state | `continuumDealManagementMysql` |
| Salesforce | Receives CRM update reflecting approval status change | `salesForce` |

## Steps

1. **Receive approval request**: API Controllers accept POST `/v1/deals/:id/approve`.
   - From: Calling client
   - To: `continuumDealManagementApi` (`apiControllers`)
   - Protocol: REST/HTTPS

2. **Load current deal state**: Repositories read the deal record from MySQL to verify current state.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

3. **Validate approval eligibility**: Validators confirm the deal is in a state that permits approval submission (e.g., not already approved, not published, not deleted).
   - From: `validationLayer` (internal)
   - To: in-process
   - Protocol: in-process

4. **Transition deal state**: Repositories update the deal's approval state in MySQL (e.g., to `pending_approval` or `approved`).
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

5. **Sync approval state to Salesforce**: Remote Clients push the updated deal status to Salesforce CRM.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: `salesForce`
   - Protocol: REST/HTTPS

6. **Return updated deal**: API Controllers return HTTP 200 with the updated deal payload.
   - From: `continuumDealManagementApi`
   - To: Calling client
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not found | Return HTTP 404 | Approval not performed |
| Deal in ineligible state | Return HTTP 422 with state constraint error | Deal state unchanged |
| MySQL update failure | Return HTTP 500; transaction rolled back | Deal state unchanged |
| Salesforce sync failure | Return HTTP 500 or log and surface error | Deal state updated in MySQL but CRM may be out of sync |

## Sequence Diagram

```
Client -> continuumDealManagementApi: POST /v1/deals/:id/approve
continuumDealManagementApi -> continuumDealManagementMysql: SELECT deal by id
continuumDealManagementMysql --> continuumDealManagementApi: deal record
continuumDealManagementApi -> validationLayer: validate approval eligibility
validationLayer --> continuumDealManagementApi: valid / errors
continuumDealManagementApi -> continuumDealManagementMysql: UPDATE deal state = pending_approval
continuumDealManagementMysql --> continuumDealManagementApi: updated
continuumDealManagementApi -> salesForce: PATCH deal CRM record (approval status)
salesForce --> continuumDealManagementApi: 200 OK
continuumDealManagementApi --> Client: 200 OK {updated deal}
```

## Related

- Architecture dynamic view: `dynamic-dealApprovalWorkflow`
- Related flows: [Deal Publish Workflow](deal-publish-workflow.md), [Deal Create (Sync)](deal-create-sync.md)
