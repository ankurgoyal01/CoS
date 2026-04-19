---
service: "command-center"
title: "Workflow Notification"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "workflow-notification"
flow_type: asynchronous
trigger: "A tool job reaches a terminal state (success or failure) within continuumCommandCenterWorker or continuumCommandCenterWeb"
participants:
  - "continuumCommandCenterWeb"
  - "continuumCommandCenterWorker"
  - "continuumCommandCenterMysql"
architecture_ref: "dynamic-cmdcenter-tool-request-processing"
---

# Workflow Notification

## Summary

When a Command Center tool job reaches a terminal state — either successful completion or permanent failure — the Mailer Layer (`cmdCenter_webMailer`) within `continuumCommandCenterWeb` composes and sends an email notification to the requesting operator. This informs operators of large-scale job outcomes without requiring them to poll the web UI. The notification may be triggered by the web layer (for synchronous results) or coordinated via the worker updating job state in MySQL, which the web layer then acts on.

## Trigger

- **Type**: event (job terminal state)
- **Source**: Tool job reaches a terminal state in `continuumCommandCenterMysql`; notification triggered by `cmdCenter_webDomainServices` or `cmdCenter_workerJobs`
- **Frequency**: Per job reaching terminal state (on-demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Command Center Web | Hosts the Mailer Layer that composes and sends notifications | `continuumCommandCenterWeb` |
| Command Center Worker | Updates job terminal state in MySQL; may enqueue notification dispatch | `continuumCommandCenterWorker` |
| Command Center MySQL | Stores job state and outcome data read by the mailer | `continuumCommandCenterMysql` |

## Steps

1. **Job reaches terminal state**: `continuumCommandCenterWorker` completes or permanently fails a job and writes the terminal status to `continuumCommandCenterMysql`.
   - From: `cmdCenter_workerPersistence`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

2. **Trigger notification dispatch**: Terminal state write triggers notification logic — either directly within the worker (via domain service call or enqueued notification job) or via a web-side observer pattern.
   - From: `cmdCenter_workerJobs` or `cmdCenter_webDomainServices`
   - To: `cmdCenter_webMailer`
   - Protocol: direct (in-process) or Delayed Job

3. **Read job outcome for email composition**: Mailer reads the job record and result data from MySQL to compose the notification message.
   - From: `cmdCenter_webMailer` via `cmdCenter_webPersistence`
   - To: `continuumCommandCenterMysql`
   - Protocol: ActiveRecord / MySQL

4. **Compose notification email**: Mailer constructs the workflow status or failure notification message using ActionMailer templates.
   - From: `cmdCenter_webMailer`
   - To: in-process email composition
   - Protocol: direct (in-process, ActionMailer)

5. **Send email**: ActionMailer delivers the composed email to the requesting operator via the configured SMTP server.
   - From: `cmdCenter_webMailer`
   - To: SMTP server (external email delivery)
   - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| SMTP delivery failure | ActionMailer delivery errors logged; retry behavior depends on configuration | Email not delivered; operator must check job status via web UI |
| MySQL read failure during email composition | Mailer raises exception; email not sent | Operator not notified; job status still visible in web UI |
| Missing operator email address | Mailer skips delivery or logs warning | No notification sent for that job |

## Sequence Diagram

```
cmdCenter_workerPersistence -> continuumCommandCenterMysql  : Writes terminal job status (ActiveRecord/MySQL)
cmdCenter_workerJobs        -> cmdCenter_webMailer          : Triggers notification dispatch (in-process or Delayed Job)
cmdCenter_webMailer         -> continuumCommandCenterMysql  : Reads job outcome data (ActiveRecord/MySQL)
cmdCenter_webMailer         -> cmdCenter_webMailer          : Composes notification email (ActionMailer)
cmdCenter_webMailer         -> SMTP Server                  : Sends email to operator (SMTP)
SMTP Server                 --> Operator                    : Delivers workflow notification email
```

## Related

- Architecture dynamic view: `dynamic-cmdcenter-tool-request-processing`
- Related flows: [Tool Request Processing](tool-request-processing.md), [Background Job Execution](background-job-execution.md)
