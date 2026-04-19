---
service: "amsJavaScheduler"
title: "EDW Feedback Push"
generated: "2026-03-03"
type: flow
flow_name: "edw-feedback-push"
flow_type: scheduled
trigger: "cron4j scheduler — nightly, region-specific cron expression"
participants:
  - "continuumAmsJavaScheduler"
  - "continuumAudienceManagementService"
architecture_ref: "dynamic-ams-scheduler-edw-amsScheduler_edwFeedback"
---

# EDW Feedback Push

## Summary

The EDW Feedback Push flow delivers published audience data from the Audience Management Service to the Enterprise Data Warehouse (Teradata). Nightly, the EDW Feedback Runner retrieves the list of published audiences from the AMS REST API and then, for each audience, executes remote EDW feedback push scripts over SSH on the Hadoop EDW Feedback Host. The Teradata Warehouse receives the pushed data for downstream analytics and reporting use cases.

## Trigger

- **Type**: schedule
- **Source**: `cron4j` scheduler fires the `EDWFeedbackPushAction` class; in cloud deployments this action is invoked via the launcher class specified by `CLASS_TO_RUN`
- **Frequency**: Nightly — specific time depends on region and environment configuration; governed by the `jobSchedule` and `TIME_OF_RUN` Helm values for each deployment

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| EDW Feedback Runner | Orchestrates retrieval of published audiences and SSH-based push execution | `amsScheduler_edwFeedback` |
| AMS REST Client Adapter | Calls AMS `searchPublishedAudiences` API | `amsScheduler_amsRestClient` |
| SSH EDW Executor | Builds and executes remote EDW feedback push commands over SSH (keyless) | `amsScheduler_sshEdwExecutor` |
| Audience Management Service | Provides the list of published audiences for EDW delivery | `continuumAudienceManagementService` |
| EDW Feedback Host | Remote Hadoop host that runs the EDW push script and loads data into Teradata | `hadoopEdwFeedbackHost` (stub) |

## Steps

1. **Cron Trigger**: `cron4j` fires the EDW Feedback action at the configured schedule time
   - From: `amsScheduler_actionDispatchers`
   - To: `amsScheduler_edwFeedback`
   - Protocol: Direct (in-process)

2. **Retrieve Published Audiences**: The AMS REST Client calls the AMS `searchPublishedAudiences` API to get the list of audiences that have been published and are ready for EDW delivery
   - From: `amsScheduler_edwFeedback` via `amsScheduler_amsRestClient`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP/JSON

3. **Build EDW Push Commands**: The SSH EDW Executor constructs the remote shell command for each published audience, including the audience identifier and any required parameters
   - From: `amsScheduler_edwFeedback`
   - To: `amsScheduler_sshEdwExecutor`
   - Protocol: Direct (in-process)

4. **Execute EDW Feedback Push over SSH**: The SSH EDW Executor opens a keyless SSH session (via JSch `KeylessSshCallWrapper`) to the EDW Feedback Host and executes the feedback push script for each audience
   - From: `amsScheduler_sshEdwExecutor`
   - To: `hadoopEdwFeedbackHost`
   - Protocol: SSH

5. **EDW Data Load**: The EDW Feedback Host script runs on the Hadoop cluster and publishes the audience feedback tables into the Teradata Warehouse
   - From: `hadoopEdwFeedbackHost`
   - To: `teradataWarehouse` (stub)
   - Protocol: Internal Hadoop/Teradata connector

6. **Job Complete**: After all published audiences are processed, the runner exits; the pod exits normally
   - From: `amsScheduler_edwFeedback`
   - To: Kubernetes CronJob controller (via pod exit code)
   - Protocol: Kubernetes pod lifecycle

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS `searchPublishedAudiences` API error | HTTP error logged; runner exits with failure | Pod fails; next scheduled run retries; no SSH commands executed |
| SSH connection failure to EDW Feedback Host | `JSchException` logged; push for affected audience fails | EDW data not delivered for that audience; no automatic retry within the same run; next nightly run will attempt again |
| Remote EDW script execution error (non-zero exit code) | SSH remote exit code captured; error logged | EDW push fails for that audience; job continues processing remaining audiences if possible |
| No published audiences found | AMS returns empty list | Runner exits normally; no SSH commands executed; this is a valid no-op state |

## Sequence Diagram

```
cron4j -> EdwFeedbackRunner: Fire EDWFeedbackPushAction
EdwFeedbackRunner -> AmsRestClient: searchPublishedAudiences
AmsRestClient -> AudienceManagementService: GET /searchPublishedAudiences
AudienceManagementService --> AmsRestClient: Published audience list
AmsRestClient --> EdwFeedbackRunner: Published audience list
EdwFeedbackRunner -> SshEdwExecutor: Build and execute EDW push command (per audience)
SshEdwExecutor -> EdwFeedbackHost: SSH exec feedback push script
EdwFeedbackHost -> TeradataWarehouse: Load audience feedback tables
EdwFeedbackHost --> SshEdwExecutor: Script exit code
SshEdwExecutor --> EdwFeedbackRunner: Push result
EdwFeedbackRunner --> cron4j: Job complete
```

## Related

- Architecture dynamic view: `dynamic-ams-scheduler-edw-amsScheduler_edwFeedback`
- Related flows: [Scheduler Startup and Schedule Loading](scheduler-startup.md), [SAD Materialization](sad-materialization.md)
