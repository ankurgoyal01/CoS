---
service: "tdo-team"
title: "IR Automation"
generated: "2026-03-03"
type: flow
flow_name: "ir-automation"
flow_type: scheduled
trigger: "Kubernetes CronJob every 30 minutes"
participants:
  - "continuumTdoTeamIrAutomationJob"
  - "irAutomationCli"
  - "irAutomationJiraHelper"
  - "irAutomationGoogleHelper"
  - "irAutomationSlackHelper"
  - "irAutomationServicePortalHelper"
architecture_ref: "dynamic-tdo-team-ir-automation"
---

# IR Automation

## Summary

The IR Automation flow runs every 30 minutes and automatically creates Incident Review (IR) Google documents for resolved GPROD Jira incidents that are missing an IR document link. It queries Jira for eligible incidents, checks whether an IR document already exists in the TDO Drive, creates one from a standard template if it does not, and posts the document link as a Jira comment while notifying the Incident Management Slack/Google Chat channel.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`ir-automation` component)
- **Frequency**: Every 30 minutes (`*/30 * * * *` in production)
- **Entry point**: `/usr/local/bin/tdo ir --confirm`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| TDO IR Automation Job | CronJob host; invokes the `tdo ir --confirm` command | `continuumTdoTeamIrAutomationJob` |
| IR Automation CLI | Orchestrates all sub-steps of the IR workflow | `irAutomationCli` |
| Jira Helper | Queries GPROD Jira for incidents needing IR docs; posts IR doc link as comment | `irAutomationJiraHelper` |
| Google Helper | Checks TDO Drive for existing IR docs; creates directory; copies template; renames doc | `irAutomationGoogleHelper` |
| Slack Helper | Sends notification to "Incident Management" channel on successful IR doc creation | `irAutomationSlackHelper` |
| Service Portal Helper | Looks up service owner from Service Portal for use in Jira comment | `irAutomationServicePortalHelper` |
| Jira (external) | Source of GPROD incident tickets; receives IR document link comment | external |
| Google Drive / Docs API (external) | Stores IR Template and produced IR documents | external |
| Slack / Google Chat webhook (external) | Receives IR creation notification | external |

## Steps

1. **Query Jira for incidents missing IR documents**: Executes JQL `project = GPROD and type=Incident and sev in (1,2,3,4,5) and status in ('Done','Mitigated') and 'IR Complete' not in ('Yes','Meeting Not Needed') and 'IR Document Link' is EMPTY and created >= startOfDay(-180)` against `https://groupondev.atlassian.net`
   - From: `irAutomationJiraHelper`
   - To: Jira REST API
   - Protocol: REST (HTTPS, Basic Auth)

2. **Check TDO Drive for existing IR document**: For each returned incident, searches the Google Drive IR directory (`1TFPzaVdHjAg552ebDGTw1tLLsprqPiur`) for an existing document matching the incident key; if found, skips to step 6
   - From: `irAutomationGoogleHelper`
   - To: Google Drive API
   - Protocol: REST (HTTPS, OAuth 2.0)

3. **Create IR directory path**: Creates a folder structure inside the IR Review folder for the incident (by service/date or incident key)
   - From: `irAutomationGoogleHelper`
   - To: Google Drive API
   - Protocol: REST (HTTPS, OAuth 2.0)

4. **Copy IR template document**: Makes a copy of the master IR template (`17RdOoak4QWMOHQ2Adu649eOQ0ZIlOpYz0cJbSkdCy0o`) into the newly created directory
   - From: `irAutomationGoogleHelper`
   - To: Google Drive API
   - Protocol: REST (HTTPS, OAuth 2.0)

5. **Populate and rename the IR document**: Replaces template variables (incident data, service name, date) and renames the document to match the incident
   - From: `irAutomationGoogleHelper`
   - To: Google Docs API
   - Protocol: REST (HTTPS, OAuth 2.0)

6. **Post IR document link to Jira**: Adds a Jira comment on the GPROD incident ticket containing the Google Doc URL and tagging the service owner account; sets the "IR Document Link" field
   - From: `irAutomationJiraHelper`
   - To: Jira REST API (`POST /rest/api/2/issue/{key}/comment`)
   - Protocol: REST (HTTPS, Basic Auth)

7. **Send Slack/Google Chat notification**: Posts a message to the "Incident Management" channel via webhook confirming the IR document was created
   - From: `irAutomationSlackHelper`
   - To: Google Chat webhook (`AAAAnz4axIw`)
   - Protocol: HTTPS webhook POST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jira query returns no results | Script exits cleanly | No documents created; normal completion |
| IR document already exists in TDO Drive | Skips creation; links existing doc to Jira | Jira updated; no duplicate document |
| Google API call fails (OAuth expired, etc.) | Logs exception via Python `logging.exception`; continues to next incident | Affected incident skipped; other incidents processed |
| Jira comment POST fails | Logs error; continues | IR doc created but Jira not updated; may be detected on next 30-min run |
| Slack notification fails | Logs error; does not retry | IR doc created and Jira updated; notification missed |
| Service Portal returns null owner | Owner field omitted from Jira comment | Comment posted without service owner mention |

## Sequence Diagram

```
CronJob -> IR Automation CLI: tdo ir --confirm
IR Automation CLI -> Jira Helper: Query GPROD incidents (JQL)
Jira Helper -> Jira REST API: GET /rest/api/2/search?jql=...
Jira REST API --> Jira Helper: List of incident tickets
IR Automation CLI -> Google Helper: Check for existing IR doc
Google Helper -> Google Drive API: Search in folder 1TFPzaVdHjAg552ebDGTw1tLLsprqPiur
Google Drive API --> Google Helper: Found / Not Found
Google Helper -> Google Drive API: Create directory (if not found)
Google Helper -> Google Drive API: Copy template 17RdOoak4QWMOHQ2Adu649eOQ0ZIlOpYz0cJbSkdCy0o
Google Drive API --> Google Helper: New document ID
Google Helper -> Google Docs API: Replace template variables, rename document
IR Automation CLI -> Jira Helper: Post IR doc link as Jira comment
Jira Helper -> Jira REST API: POST /rest/api/2/issue/{key}/comment
Jira REST API --> Jira Helper: 201 Created
IR Automation CLI -> Slack Helper: Notify channel
Slack Helper -> Google Chat webhook: POST {"text": "IR doc created"}
```

## Related

- Architecture dynamic view: `dynamic-tdo-team-ir-automation`
- Related flows: [Advisory Actions Reminders](advisory-actions-reminders.md), [SEV4 Reminders](sev4-reminders.md)
- IR template document: `17RdOoak4QWMOHQ2Adu649eOQ0ZIlOpYz0cJbSkdCy0o`
- TDO IR documentation: `cronjobs/ir-automation/docs/tdo_ir.md`
