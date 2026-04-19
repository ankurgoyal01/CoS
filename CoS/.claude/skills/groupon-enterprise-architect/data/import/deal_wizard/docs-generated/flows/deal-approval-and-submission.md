---
service: "deal_wizard"
title: "Deal Approval & Submission"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-approval-and-submission"
flow_type: synchronous
trigger: "Sales representative submits a completed deal wizard for approval"
participants:
  - "dealWizardWebUi"
  - "salesforceClient"
  - "salesForce"
architecture_ref: "dynamic-dealApprovalAndSubmission"
---

# Deal Approval & Submission

## Summary

The Deal Approval & Submission flow is triggered when a sales representative completes all wizard steps and submits the deal for review. The Web UI validates deal completeness, calls `POST /api/v1/create_salesforce_deal` to persist the finalized deal data to Salesforce, and submits it to the configured approval workflow via `POST /api/v1/approvals`. Approval status is tracked in Salesforce as the system of record. Salesforce write failures are captured for admin review and may be retried via `delayed_job`.

## Trigger

- **Type**: user-action
- **Source**: Sales representative clicks "Submit for Approval" after completing all wizard steps
- **Frequency**: On-demand; once per completed deal wizard session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Sales Representative (User) | Initiates approval submission | — |
| Deal Wizard Web UI | Validates deal completeness; orchestrates Salesforce write and approval submission | `dealWizardWebUi` |
| Salesforce Client | Writes finalized deal data to Salesforce Opportunity; submits approval request | `salesforceClient` |
| Salesforce | Persists deal data; hosts approval workflow | `salesForce` |

## Steps

1. **Initiate Submission**: Sales representative clicks "Submit for Approval" on the wizard summary/review page.
   - From: `Sales Representative`
   - To: `dealWizardWebUi`
   - Protocol: HTTPS / `POST /api/v1/create_salesforce_deal`

2. **Validate Deal Completeness**: Web UI verifies all required wizard steps are complete and all required fields are populated (options, fine prints, payments, merchants, distributions).
   - From: `dealWizardWebUi`
   - To: MySQL (`dealWizardMysql`) — reads persisted step data
   - Protocol: Direct (ActiveRecord)

3. **Persist Deal to Salesforce**: Salesforce Client maps wizard deal data to Salesforce Opportunity field structure and writes the completed deal via Salesforce APEX API.
   - From: `dealWizardWebUi` via `salesforceClient`
   - To: `salesForce`
   - Protocol: REST / APEX API

4. **Submit Approval Request**: Web UI calls `POST /api/v1/approvals` to initiate the deal approval workflow in Salesforce.
   - From: `dealWizardWebUi` via `salesforceClient`
   - To: `salesForce`
   - Protocol: REST / APEX API

5. **Confirm Submission**: Salesforce returns confirmation of the deal write and approval submission. Web UI renders a success page with deal ID and approval status.
   - From: `salesForce`
   - To: `salesforceClient` -> `dealWizardWebUi`
   - Protocol: REST response

6. **Surface Confirmation**: Web UI displays submission confirmation to the sales representative with Salesforce Opportunity ID and pending approval status.
   - From: `dealWizardWebUi`
   - To: `Sales Representative`
   - Protocol: HTTPS (browser)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal completeness validation failure | Web UI re-renders with list of incomplete steps | Sales rep is directed back to incomplete wizard steps |
| Salesforce write failure (transient) | Error captured; `delayed_job` enqueues retry; error recorded for `/admin/salesforce_errors` | Deal data is queued for retry; sales rep sees pending status |
| Salesforce write failure (permanent) | Error displayed in UI; recorded in `/admin/salesforce_errors` | Admin review required; manual Salesforce data entry may be needed |
| Approval submission failure | Error displayed; deal write succeeded but approval not initiated | Sales rep or admin must manually trigger approval in Salesforce |
| Salesforce API timeout | Request fails; `delayed_job` retry scheduled | Submission delayed; sales rep sees error and retry guidance |

## Sequence Diagram

```
Sales Rep -> dealWizardWebUi: POST /api/v1/create_salesforce_deal
dealWizardWebUi -> MySQL: Validate all wizard steps complete
MySQL --> dealWizardWebUi: Deal data (all steps)
dealWizardWebUi -> salesforceClient: Map and write deal to Salesforce
salesforceClient -> salesForce: PATCH Opportunity (APEX REST)
salesForce --> salesforceClient: Opportunity updated
salesforceClient --> dealWizardWebUi: Write confirmation
dealWizardWebUi -> salesforceClient: Submit for approval
salesforceClient -> salesForce: POST /services/data/vXX.0/process/approvals
salesForce --> salesforceClient: Approval submitted
salesforceClient --> dealWizardWebUi: Approval confirmation
dealWizardWebUi --> Sales Rep: Render success page (deal ID, approval status)
```

## Related

- Architecture dynamic view: `dynamic-dealApprovalAndSubmission`
- Related flows: [Deal Creation Wizard](deal-wizard-creation.md), [Deal Status Monitoring](deal-status-monitoring.md)
