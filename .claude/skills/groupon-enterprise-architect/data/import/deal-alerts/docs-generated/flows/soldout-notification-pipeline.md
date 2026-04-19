---
service: "deal-alerts"
title: "SoldOut Notification Pipeline"
generated: "2026-03-03"
type: flow
flow_name: "soldout-notification-pipeline"
flow_type: batch
trigger: "Scheduled timer in n8n"
participants:
  - "continuumDealAlertsWorkflows_soldOutNotifications"
  - "continuumDealAlertsWorkflows_smsSender"
  - "continuumDealAlertsWorkflows_getContacts"
  - "continuumDealAlertsDb_alertLifecycle"
  - "continuumDealAlertsDb_notifications"
  - "salesForce"
  - "twilio"
architecture_ref: "dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle"
---

# SoldOut Notification Pipeline

## Summary

The SoldOut Notification Pipeline processes SoldOut alerts by resolving merchant contacts via Salesforce, selecting appropriate message templates, creating notification records scheduled according to region business hours, and then sending SMS messages via Twilio. The pipeline also handles delivery status callbacks, inbound reply processing (including opt-out STOP/START commands), and maintains a full conversation history per phone number.

## Trigger

- **Type**: schedule
- **Source**: n8n scheduled timer
- **Frequency**: Periodic (configured in n8n)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SoldOut Notifications | Processes SoldOut alerts, resolves contacts, selects templates, creates notifications | `continuumDealAlertsWorkflows_soldOutNotifications` |
| SMS Notifications Sender | Sends SMS via Twilio, handles delivery callbacks and inbound replies | `continuumDealAlertsWorkflows_smsSender` |
| Get Contacts Resolver | Resolves merchant contact details from Salesforce | `continuumDealAlertsWorkflows_getContacts` |
| Alert Lifecycle Tables | Source of SoldOut alerts and mute state | `continuumDealAlertsDb_alertLifecycle` |
| Notification & Reply Tables | Stores notification records, delivery status, and reply history | `continuumDealAlertsDb_notifications` |
| Salesforce | Source of merchant contact phone numbers and account details | `salesForce` |
| Twilio | SMS delivery provider | `twilio` |

## Steps

1. **Select SoldOut alerts**: Query alerts with type SoldOut/OptionSoldOut that have not yet been processed for notifications. Check mute state.
   - From: `continuumDealAlertsWorkflows_soldOutNotifications`
   - To: `continuumDealAlertsDb_alertLifecycle`
   - Protocol: SQL

2. **Resolve merchant contacts**: Query Salesforce for the merchant associated with the deal to get contact phone numbers and account/opportunity context.
   - From: `continuumDealAlertsWorkflows_getContacts`
   - To: `salesForce`
   - Protocol: HTTPS/REST

3. **Select message template**: Choose the appropriate template from `templates` table based on the alert-action mapping configuration. Render the template with deal and alert context variables.
   - From: `continuumDealAlertsWorkflows_soldOutNotifications`
   - To: `continuumDealAlertsDb_notifications`
   - Protocol: SQL

4. **Create notification records**: Insert notification records with channel (SMS), recipient phone number, rendered message, and `scheduled_at` based on region business hours.
   - From: `continuumDealAlertsWorkflows_soldOutNotifications`
   - To: `continuumDealAlertsDb_notifications`
   - Protocol: SQL

5. **Send SMS notifications**: The SMS Sender workflow queries for due notifications (where `scheduled_at <= now()` and status = 'Created'), sends each via the Twilio Messaging API, and updates status to 'Sent'.
   - From: `continuumDealAlertsWorkflows_smsSender`
   - To: `twilio`
   - Protocol: HTTPS

6. **Process delivery callbacks**: Twilio posts delivery status webhooks which update `notification_status_history` and the notification's current status (Delivered, Failed, Undelivered).
   - From: `twilio`
   - To: `continuumDealAlertsWorkflows_smsSender`
   - Protocol: HTTPS (webhook)

7. **Process inbound replies**: Twilio posts inbound SMS webhooks. The workflow parses the message for commands (replenishment actions) and opt-out signals (STOP/START), then inserts `notification_replies` records with direction, command, and opt_out_type.
   - From: `twilio`
   - To: `continuumDealAlertsWorkflows_smsSender`
   - Protocol: HTTPS (webhook)

8. **Record reply outcomes**: Reply processing results (including any task_error for failed command execution) are persisted to the notification_replies table.
   - From: `continuumDealAlertsWorkflows_smsSender`
   - To: `continuumDealAlertsDb_notifications`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce contact not found | Notification not created for that alert | Alert remains without notification |
| Twilio send failure | Notification status set to Failed; error recorded | Visible in SMS analytics and Logs API |
| Recipient unsubscribed (error 21610) | Status recorded in notification_status_history | Recipient excluded from future sends |
| Inbound reply parse failure | Reply recorded with task_error | Visible in Logs API (source: notification_replies) |
| Region business hours not configured | Notification scheduled immediately | May arrive outside business hours |

## Sequence Diagram

```
SoldOutNotifications -> AlertLifecycle: Select SoldOut alerts (check mute state)
SoldOutNotifications -> Salesforce: Resolve merchant contacts
SoldOutNotifications -> Notifications: Select template, render message
SoldOutNotifications -> Notifications: Create notification records (scheduled_at)
SMSSender -> Notifications: Fetch due notifications
SMSSender -> Twilio: Send SMS messages
Twilio --> SMSSender: Delivery status callbacks
SMSSender -> Notifications: Update notification_status_history
Twilio --> SMSSender: Inbound reply webhooks
SMSSender -> Notifications: Insert notification_replies
```

## Related

- Architecture dynamic view: `dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle`
- Related flows: [Action Orchestration](action-orchestration.md), [Attribution Correlation](attribution-correlation.md)
