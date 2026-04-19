---
service: "merchant-preview"
title: "Comment Workflow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "comment-workflow"
flow_type: synchronous
trigger: "Merchant or account manager submits a comment or approval action"
participants:
  - "continuumMerchantPreviewService"
  - "mpCommentWorkflow"
  - "mpSalesforceApiClient"
  - "mpPreviewMailer"
  - "continuumMerchantPreviewDatabase"
  - "salesForce"
  - "smtpRelay"
architecture_ref: "components-continuum-merchant-preview-service"
---

# Comment Workflow

## Summary

This flow describes the lifecycle of a comment or approval action submitted by a merchant or account manager on a deal preview. The Comment Workflow Engine validates and persists the action to the database, updates the corresponding Salesforce Opportunity or Task record, and dispatches email notifications to relevant parties via ActionMailer.

## Trigger

- **Type**: user-action
- **Source**: Merchant or account manager submits a comment, resolves a comment, approves, or rejects deal creative via the preview web UI
- **Frequency**: On demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Preview Service | Receives and dispatches the user action | `continuumMerchantPreviewService` |
| Preview Web Controller Layer | Receives HTTP action, delegates to domain logic | `mpPreviewWebController` |
| Comment Workflow Engine | Executes comment create/update/resolve and approval logic | `mpCommentWorkflow` |
| Salesforce API Client | Submits state updates to Salesforce | `mpSalesforceApiClient` |
| Preview Mailer | Sends notification emails to merchant and/or account manager | `mpPreviewMailer` |
| Merchant Preview Database | Persists comment and workflow state | `continuumMerchantPreviewDatabase` |
| Salesforce | Stores Opportunity/Task approval workflow state | `salesForce` |
| SMTP Relay | Delivers notification emails | `smtpRelay` |

## Steps

1. **Receive user action**: Preview Web Controller receives the HTTP POST for comment submission or approval action.
   - From: `merchant` or `salesRep`
   - To: `mpPreviewWebController`
   - Protocol: HTTP

2. **Execute comment workflow logic**: Controller delegates to Comment Workflow Engine to validate and process the action.
   - From: `mpPreviewWebController`
   - To: `mpCommentWorkflow`
   - Protocol: direct (in-process)

3. **Persist to database**: Comment Workflow Engine writes the new comment or updated approval state to the database.
   - From: `mpCommentWorkflow`
   - To: `continuumMerchantPreviewDatabase`
   - Protocol: MySQL

4. **Update Salesforce**: Comment Workflow Engine calls Salesforce API Client to reflect the state change in Salesforce.
   - From: `mpCommentWorkflow`
   - To: `mpSalesforceApiClient`
   - Protocol: direct (in-process)

5. **Write to Salesforce**: Salesforce API Client submits the mutation to Salesforce.
   - From: `mpSalesforceApiClient`
   - To: `salesForce`
   - Protocol: HTTPS (databasedotcom)

6. **Send notification email**: Comment Workflow Engine triggers Preview Mailer to dispatch email to merchant and/or account manager.
   - From: `mpCommentWorkflow`
   - To: `mpPreviewMailer`
   - Protocol: direct (in-process)

7. **Deliver email**: Preview Mailer sends the notification email via SMTP relay.
   - From: `mpPreviewMailer`
   - To: `smtpRelay`
   - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database write fails | Transaction rollback | Comment not persisted; error returned to user |
| Salesforce API unavailable | API error from `salesForce` | Comment persisted locally; Salesforce state is stale until next cron sync |
| SMTP relay unavailable | ActionMailer delivery failure | Email not delivered; comment/approval action still persisted |

## Sequence Diagram

```
User (Merchant/AccountManager) -> mpPreviewWebController: Submits comment or approval (HTTP POST)
mpPreviewWebController -> mpCommentWorkflow: Delegates action
mpCommentWorkflow -> continuumMerchantPreviewDatabase: Writes comment/approval state (MySQL)
continuumMerchantPreviewDatabase --> mpCommentWorkflow: Confirms write
mpCommentWorkflow -> mpSalesforceApiClient: Updates Salesforce state (direct)
mpSalesforceApiClient -> salesForce: Mutation request (HTTPS)
salesForce --> mpSalesforceApiClient: Confirmation
mpCommentWorkflow -> mpPreviewMailer: Triggers notification email (direct)
mpPreviewMailer -> smtpRelay: Delivers email (SMTP)
mpPreviewWebController --> User: Returns confirmation response (HTTP)
```

## Related

- Architecture dynamic view: `dynamic-merchant-preview-request-mpCommentWorkflow`
- Related flows: [Merchant Preview Review](merchant-preview-review.md), [Cron Salesforce Sync](cron-salesforce-sync.md)
