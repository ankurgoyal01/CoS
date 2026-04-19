---
service: "tdo-team"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for TDO Team.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [IR Automation](ir-automation.md) | scheduled | Every 30 minutes (Kubernetes CronJob) | Creates and links Google Doc IR documents for resolved GPROD incidents missing an IR review |
| [Advisory Actions Reminders](advisory-actions-reminders.md) | scheduled | Monthly on the 1st at 07:00 UTC | Posts 30-day due-date reminder comments to advisory action Jira tickets |
| [Subtask and IA Reminders](subtask-and-ia-reminders.md) | scheduled | Daily at 08:00 UTC | Posts 3-, 10-, and 30-day due-date reminder comments to GPROD subtask and Immediate Action tickets |
| [Close Old Logbooks](close-old-logbooks.md) | scheduled | Daily at 08:00 UTC | Closes GPROD logbook tickets open more than 10 days past planned start date and adds an explanatory comment |
| [SEV4 Reminders](sev4-reminders.md) | scheduled | Mondays at 09:00 UTC | Posts SLA reminder comments to open SEV4 Jira incidents requiring bi-daily updates |
| [Pingdom Shift Report](pingdom-shift-report.md) | scheduled | Every 4 hours | Queries Pingdom API for monitor flaps, downtime, and response time anomalies and posts shift report to Google Chat |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 6 |

## Cross-Service Flows

All flows in this service span multiple external systems. Key cross-service data paths:

- All Jira-targeting flows resolve service owner data from the internal Service Portal (`http://service-portal.production.service`) before posting comments — see [Integrations](../integrations.md) for details.
- The [IR Automation](ir-automation.md) flow bridges Jira GPROD incident records, Google Drive document storage, and Google Chat/Slack notifications in a single scheduled execution.
- The [Pingdom Shift Report](pingdom-shift-report.md) flow is the most complex, making N+2 API calls per Pingdom monitor check (results + summary) plus user-targeted Google Chat mentions based on time-of-day.
