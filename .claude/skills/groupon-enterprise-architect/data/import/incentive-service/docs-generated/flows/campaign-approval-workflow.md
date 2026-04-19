---
service: "incentive-service"
title: "Campaign Approval Workflow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "campaign-approval-workflow"
flow_type: synchronous
trigger: "API call — POST /admin/campaigns/:id/approve"
participants:
  - "continuumIncentiveService"
  - "incentiveApi"
  - "incentiveAdminUi"
  - "incentiveDataAccess"
  - "incentiveMessaging"
  - "incentiveExternalClients"
  - "continuumIncentivePostgres"
  - "messageBus"
  - "continuumMessagingService"
architecture_ref: "dynamic-incentive-request-flow"
---

# Campaign Approval Workflow

## Summary

The campaign approval workflow allows authorised admin users to review and activate incentive campaigns through the admin UI. An admin visits the campaign detail page, reviews campaign configuration, and submits an approval action. The service transitions the campaign state from `pending` to `active` in PostgreSQL, publishes a `campaign.status_changed` event to MBus, and notifies the Messaging Service to activate the campaign for delivery. The multi-step approval path is gated by the `incentive.campaignApprovalWorkflow` feature flag. This flow is only active when `SERVICE_MODE=admin`.

## Trigger

- **Type**: user-action
- **Source**: Authorised admin user via the campaign management UI
- **Frequency**: On-demand; once per campaign approval action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Admin User | Reviews campaign details and submits approval | — |
| Incentive Admin UI | Renders campaign detail and approval form | `incentiveAdminUi` |
| Incentive Service (API) | Processes approval request, orchestrates state transition and notifications | `incentiveApi` |
| Incentive Data Access | Reads and writes campaign state and approval workflow records in PostgreSQL | `incentiveDataAccess` |
| Incentive Messaging | Publishes `campaign.status_changed` event to MBus | `incentiveMessaging` |
| Incentive External Clients | Calls Messaging Service to activate campaign delivery | `incentiveExternalClients` |
| Incentive PostgreSQL | Holds campaign state and approval workflow records | `continuumIncentivePostgres` |
| Message Bus | Receives `campaign.status_changed` event for downstream consumers | `messageBus` |
| Messaging Service | Activated to begin campaign delivery to the qualified audience | `continuumMessagingService` |

## Steps

1. **Load campaign detail page**: Admin user navigates to `GET /admin/campaigns/:id`; `incentiveAdminUi` renders the campaign detail view with current state, configuration, and approval history from PostgreSQL.
   - From: Admin User
   - To: `incentiveAdminUi`
   - Protocol: REST/HTTP (browser)

2. **Read campaign record**: `incentiveDataAccess` queries PostgreSQL for the full campaign record, approval workflow state, and pending approval steps.
   - From: `incentiveAdminUi` (via `incentiveDataAccess`)
   - To: `continuumIncentivePostgres`
   - Protocol: JDBC/PostgreSQL

3. **Submit approval**: Admin user submits the approval action; browser calls `POST /admin/campaigns/:id/approve`.
   - From: Admin User
   - To: `incentiveApi`
   - Protocol: REST/HTTP

4. **Validate approval authorisation**: `incentiveApi` verifies the requesting user has the required approval authority for this campaign and that the campaign is in an approvable state (`pending`).
   - From: `incentiveApi`
   - To: internal
   - Protocol: in-process

5. **Record approval step**: If `incentive.campaignApprovalWorkflow` is enabled, `incentiveDataAccess` records the approval step in the `campaign_approval` table, associating the approver and timestamp with the campaign.
   - From: `incentiveApi` (via `incentiveDataAccess`)
   - To: `continuumIncentivePostgres`
   - Protocol: JDBC/PostgreSQL

6. **Transition campaign state to active**: `incentiveDataAccess` updates the campaign record in PostgreSQL, setting `state = active` and recording the activation timestamp.
   - From: `incentiveApi` (via `incentiveDataAccess`)
   - To: `continuumIncentivePostgres`
   - Protocol: JDBC/PostgreSQL

7. **Publish `campaign.status_changed` event**: `incentiveMessaging` publishes a `campaign.status_changed` event to MBus with payload including campaign ID, previous state (`pending`), new state (`active`), and transition timestamp.
   - From: `incentiveMessaging`
   - To: `messageBus`
   - Protocol: MBus/STOMP

8. **Notify Messaging Service**: `incentiveExternalClients` calls `continuumMessagingService` to activate the campaign for delivery, providing campaign ID and the qualified audience reference.
   - From: `incentiveApi` (via `incentiveExternalClients`)
   - To: `continuumMessagingService`
   - Protocol: REST/HTTP

9. **Return approval confirmation**: `incentiveApi` returns a success response; `incentiveAdminUi` displays the updated campaign state to the admin user.
   - From: `incentiveApi`
   - To: Admin User
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Campaign not in approvable state | Return 400/409 error; no state change | Admin user informed of invalid transition |
| Insufficient approval authority | Return 403 Forbidden | Admin user cannot proceed; escalation required |
| PostgreSQL write failure (state update) | Return 500 error; no partial state change | Campaign remains in `pending` state; admin retries |
| MBus publish failure | Retry; if exhausted, log for manual reconciliation | `campaign.status_changed` event delayed; campaign is `active` in PostgreSQL but MBus consumers not yet notified |
| Messaging Service call failure | Return partial success or retry; campaign is active but delivery not yet triggered | Messaging Service must be notified separately; admin is informed |
| `incentive.campaignApprovalWorkflow` flag off | Approval step record is skipped; campaign transitions directly | Single-step approval path; no audit trail of approval steps |

## Sequence Diagram

```
AdminUser -> incentiveAdminUi: GET /admin/campaigns/C
incentiveAdminUi -> continuumIncentivePostgres: SELECT * FROM campaigns WHERE id = C
continuumIncentivePostgres --> incentiveAdminUi: campaign record
incentiveAdminUi --> AdminUser: campaign detail page
AdminUser -> incentiveApi: POST /admin/campaigns/C/approve
incentiveApi -> incentiveApi: validate authorisation and state
incentiveApi -> continuumIncentivePostgres: INSERT INTO campaign_approval (campaign_id: C, approver: U, step: 1)
incentiveApi -> continuumIncentivePostgres: UPDATE campaigns SET state = "active" WHERE id = C
continuumIncentivePostgres --> incentiveApi: OK
incentiveMessaging -> messageBus: publish campaign.status_changed { campaignId: C, from: "pending", to: "active" }
incentiveApi -> continuumMessagingService: POST /messaging/campaigns/C/activate
continuumMessagingService --> incentiveApi: OK
incentiveApi --> AdminUser: 200 OK { campaignId: C, state: "active" }
```

## Related

- Architecture dynamic view: `dynamic-incentive-request-flow`
- Related flows: [Audience Qualification](audience-qualification.md), [Incentive Redemption](incentive-redemption.md)
