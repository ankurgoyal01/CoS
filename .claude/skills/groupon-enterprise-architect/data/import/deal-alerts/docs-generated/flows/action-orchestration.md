---
service: "deal-alerts"
title: "Action Orchestration"
generated: "2026-03-03"
type: flow
flow_name: "action-orchestration"
flow_type: batch
trigger: "Scheduled timer in n8n"
participants:
  - "continuumDealAlertsWorkflows_executeActions"
  - "continuumDealAlertsWorkflows_executeAlertActions"
  - "continuumDealAlertsWorkflows_getContacts"
  - "continuumDealAlertsDb_alertLifecycle"
  - "continuumDealAlertsDb_actionMapping"
  - "continuumDealAlertsDb_notifications"
  - "salesForce"
architecture_ref: "dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle"
---

# Action Orchestration

## Summary

The action orchestration flow is a two-stage process run by n8n workflows. First, the Execute Actions workflow selects pending alerts, applies deal-level and GP30-based filters, resolves severity using severity matrices, and assigns actions based on the alert-action mapping configuration. Second, the Execute Alert Actions workflow executes the prepared actions by creating Salesforce tasks, sending chat messages, and then resolving the alerts. This is the core decision engine that translates alert signals into merchant-facing actions.

## Trigger

- **Type**: schedule
- **Source**: n8n scheduled timer
- **Frequency**: Periodic (configured in n8n)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Execute Actions | Selects pending alerts, applies filters, resolves severity, assigns actions | `continuumDealAlertsWorkflows_executeActions` |
| Execute Alert Actions | Executes assigned actions (Salesforce tasks, chat messages) and resolves alerts | `continuumDealAlertsWorkflows_executeAlertActions` |
| Get Contacts Resolver | Queries Salesforce for merchant contact information | `continuumDealAlertsWorkflows_getContacts` |
| Alert Lifecycle Tables | Source of pending alerts and statuses | `continuumDealAlertsDb_alertLifecycle` |
| Action & Attribution Tables | Stores action assignments, Salesforce task data, and action outcomes | `continuumDealAlertsDb_actionMapping` |
| Notification & Reply Tables | Checked for existing SoldOut notification state | `continuumDealAlertsDb_notifications` |
| Salesforce | Target for task creation and contact resolution | `salesForce` |

## Steps

1. **Load pending alerts**: Execute Actions queries alerts with `status = 'Pending'` from the alert lifecycle tables.
   - From: `continuumDealAlertsWorkflows_executeActions`
   - To: `continuumDealAlertsDb_alertLifecycle`
   - Protocol: SQL

2. **Apply filters**: For each alert, apply deal-level filters, check GP30 thresholds, verify Salesforce account status, and check muted_alerts rules. Alerts that don't pass filters are marked as 'Filtered' with a `filtered_reason`.
   - From: `continuumDealAlertsWorkflows_executeActions`
   - To: `continuumDealAlertsDb_alertLifecycle`, `continuumDealAlertsDb_actionMapping`
   - Protocol: SQL

3. **Resolve severity**: Look up the GP30 value against the active severity matrix for the alert type to determine severity level (low/medium/high/critical).
   - From: `continuumDealAlertsWorkflows_executeActions`
   - To: `continuumDealAlertsDb_actionMapping`
   - Protocol: SQL

4. **Assign actions**: Match alert type + severity against `alert_action_map` to determine which actions to create (e.g., salesforce_task, chat_message). Create `actions` records with associated `alert_action_data` (GP30, owner/manager emails, severity).
   - From: `continuumDealAlertsWorkflows_executeActions`
   - To: `continuumDealAlertsDb_actionMapping`
   - Protocol: SQL

5. **Check notification state**: For SoldOut alerts, check whether a notification already exists to avoid duplicates.
   - From: `continuumDealAlertsWorkflows_executeActions`
   - To: `continuumDealAlertsDb_notifications`
   - Protocol: SQL

6. **Resolve contacts**: Query Salesforce for merchant contact details and statuses needed to execute actions.
   - From: `continuumDealAlertsWorkflows_getContacts`
   - To: `salesForce`
   - Protocol: HTTPS/REST

7. **Execute Salesforce tasks**: For actions of type `salesforce_task`, create task records in Salesforce and store the task ID in `salesforce_tasks`.
   - From: `continuumDealAlertsWorkflows_executeAlertActions`
   - To: `salesForce`
   - Protocol: HTTPS/REST

8. **Execute chat messages**: For actions of type `chat_message`, send messages and record in `chat_actions`.
   - From: `continuumDealAlertsWorkflows_executeAlertActions`
   - To: External chat system
   - Protocol: HTTPS

9. **Resolve alerts**: Mark processed alerts as resolved and update action statuses.
   - From: `continuumDealAlertsWorkflows_executeAlertActions`
   - To: `continuumDealAlertsDb_alertLifecycle`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API failure | Action recorded with error_message and retry_count incremented | Action remains in error state; visible in Logs API |
| Chat message delivery failure | Action recorded with error_message | Alert may remain unresolved |
| Severity matrix entry missing | Default severity applied or alert filtered | Alert processed with available configuration |
| Muted alert detected | Alert marked as Filtered with filtered_reason | No actions created |

## Sequence Diagram

```
ExecuteActions -> AlertLifecycle: SELECT pending alerts
ExecuteActions -> ActionMapping: Apply filters, resolve severity, assign actions
ExecuteActions -> Notifications: Check existing SoldOut notification state
GetContacts -> Salesforce: Query merchant contacts
ExecuteAlertActions -> Salesforce: Create tasks for salesforce_task actions
ExecuteAlertActions -> ActionMapping: Record action outcomes
ExecuteAlertActions -> AlertLifecycle: Mark alerts resolved
```

## Related

- Architecture dynamic view: `dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle`
- Related flows: [Deal Snapshot Ingestion](deal-snapshot-ingestion.md), [SoldOut Notification Pipeline](soldout-notification-pipeline.md), [Attribution Correlation](attribution-correlation.md)
