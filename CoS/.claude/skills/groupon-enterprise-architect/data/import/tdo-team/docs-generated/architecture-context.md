---
service: "tdo-team"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumTdoTeamIrAutomationJob"
    - "continuumTdoTeamAdvisoryActionsRemindersJob"
    - "continuumTdoTeamSubtaskRemindersJob"
    - "continuumTdoTeamCloseLogbooksJob"
    - "continuumTdoTeamSev4RemindersJob"
    - "continuumTdoTeamWeekendOncallJob"
    - "continuumTdoTeamPingdomShiftReportJob"
    - "continuumTdoTeamImocOooWeekendJob"
---

# Architecture Context

## System Context

The tdo-team service is part of the `continuumSystem` (Continuum Platform) and runs entirely as a set of Kubernetes CronJobs on GCP. It does not expose any HTTP endpoints or serve user traffic. Instead, it acts as an outbound automation layer: each cronjob wakes on a schedule, queries or mutates external systems (Jira, Google Workspace, OpsGenie, Pingdom, Service Portal), and posts notifications to messaging platforms (Google Chat, Slack). The service bridges Groupon's incident management toolchain — connecting structured incident data in Jira with IR documentation in Google Drive and shift awareness in Google Chat.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| TDO IR Automation Job | `continuumTdoTeamIrAutomationJob` | CronJob | Python, Kubernetes CronJob | 3.12 | Runs the tdo ir automation workflow; creates and links IR Google Docs for resolved GPROD incidents |
| Advisory Actions Reminders Job | `continuumTdoTeamAdvisoryActionsRemindersJob` | CronJob | Shell, Kubernetes CronJob | - | Adds Jira reminders for advisory action items at 30-day intervals |
| Subtask Reminders Job | `continuumTdoTeamSubtaskRemindersJob` | CronJob | Shell, Kubernetes CronJob | - | Reminds owners about GPROD subtasks nearing due date (3, 10, 30 days) |
| Close Logbooks Job | `continuumTdoTeamCloseLogbooksJob` | CronJob | Shell, Kubernetes CronJob | - | Closes GPROD logbook tickets older than 10 days past planned start date |
| SEV4 Reminders Job | `continuumTdoTeamSev4RemindersJob` | CronJob | Shell, Kubernetes CronJob | - | Posts SLA reminders for open SEV4 incidents to Jira tickets |
| Weekend Oncall Job | `continuumTdoTeamWeekendOncallJob` | CronJob | Shell, Kubernetes CronJob | - | Retrieves weekend on-call from OpsGenie and posts to Google Chat |
| Pingdom Shift Report Job | `continuumTdoTeamPingdomShiftReportJob` | CronJob | Shell, Kubernetes CronJob | - | Generates 4-hour Pingdom shift reports and posts to Google Chat |
| IMOC OOO Weekend Job | `continuumTdoTeamImocOooWeekendJob` | CronJob | Shell, Kubernetes CronJob | - | Posts IMOC out-of-office weekend coverage notice to Production Google Chat |

## Components by Container

### TDO IR Automation Job (`continuumTdoTeamIrAutomationJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| IR Automation CLI (`irAutomationCli`) | Entry point for the `tdo ir` command; orchestrates the full IR document workflow | Python (click) |
| Jira Helper (`irAutomationJiraHelper`) | Queries GPROD Jira for resolved incidents missing IR docs; posts comment with IR doc link | Python (jira library) |
| Google Helper (`irAutomationGoogleHelper`) | Creates IR document directories in Google Drive; copies IR template; renames and updates doc | Python (google-api-python-client) |
| Slack Helper (`irAutomationSlackHelper`) | Sends notifications to the "Incident Management" Slack/Google Chat channel on IR doc creation | Python (requests) |
| Service Portal Helper (`irAutomationServicePortalHelper`) | Fetches service owner metadata from Service Portal API v2 (`/api/v2/services/{name}`) | Python (requests) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `irAutomationCli` | `irAutomationJiraHelper` | Uses Jira helper to query and update incident tickets | Python direct call |
| `irAutomationCli` | `irAutomationGoogleHelper` | Uses Google helper to create and update IR documents | Python direct call |
| `irAutomationCli` | `irAutomationSlackHelper` | Notifies Slack/Google Chat channel on completion | Python direct call |
| `irAutomationCli` | `irAutomationServicePortalHelper` | Fetches service owner data from Service Portal | Python direct call / REST |
| `continuumTdoTeamAdvisoryActionsRemindersJob` | Jira REST API | Reads advisory action filters and posts comments to tickets | REST (curl, Basic Auth) |
| `continuumTdoTeamSubtaskRemindersJob` | Jira REST API | Reads subtask/IA filters and posts due-date reminder comments | REST (curl, Basic Auth) |
| `continuumTdoTeamCloseLogbooksJob` | Jira REST API | Queries open logbook tickets; transitions and comments | REST (curl, Basic Auth) |
| `continuumTdoTeamSev4RemindersJob` | Jira REST API | Queries open SEV4 tickets and posts SLA reminder comments | REST (curl, Basic Auth) |
| `continuumTdoTeamWeekendOncallJob` | OpsGenie API v2 | Retrieves on-call schedule participants for weekend window | REST (curl, GenieKey Auth) |
| `continuumTdoTeamWeekendOncallJob` | Google Chat webhook | Posts on-call roster to IMOC Google Chat space | HTTPS webhook POST |
| `continuumTdoTeamPingdomShiftReportJob` | Pingdom API v2.1 | Retrieves all checks, results, and summaries for 4-hour window | REST (curl, Basic Auth) |
| `continuumTdoTeamPingdomShiftReportJob` | Google Chat webhook | Posts shift report and user mentions to two Google Chat spaces | HTTPS webhook POST |
| `continuumTdoTeamImocOooWeekendJob` | Google Chat webhook | Posts weekend IMOC coverage notice to Production space | HTTPS webhook POST |
| Shell cronjobs | Service Portal (`/api/v2/services/{name}`) | Resolves service owner name and Jira account ID | REST (curl, GRPN-Client-ID header) |

## Architecture Diagram References

- Container: `tdo-team-containers`
- Component: `components-tdo-team-containers`
