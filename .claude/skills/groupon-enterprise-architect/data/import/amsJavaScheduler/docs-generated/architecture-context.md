---
service: "amsJavaScheduler"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAmsJavaScheduler, continuumAmsSchedulerScheduleStore]
---

# Architecture Context

## System Context

AMS Java Scheduler sits within the `continuumSystem` as a backend batch-processing container. It has no inbound callers at runtime — execution is initiated entirely by Kubernetes CronJobs. The service reads schedule definitions from internal text files and calls the Audience Management Service (AMS) REST API (`continuumAudienceManagementService`) to drive audience materialization workflows. It also communicates outbound to YARN for capacity-aware execution and to the EDW Feedback Host over SSH for data delivery. The scheduler operates as a pure orchestration layer: it owns no persistent database of its own, relying on AMS as the system of record for SAD and SAI state.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| AMS Java Scheduler | `continuumAmsJavaScheduler` | Service | Java 8, cron4j | 2.2.3 | Cron-driven scheduler that loads schedule definitions and triggers AMS audience materialization and EDW feedback jobs |
| Scheduler Schedule Store | `continuumAmsSchedulerScheduleStore` | Config Store | Text Files | — | Versioned schedule definition files loaded at runtime to determine which action classes are executed per cron expression |

## Components by Container

### AMS Java Scheduler (`continuumAmsJavaScheduler`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Scheduler Bootstrap (`amsScheduler_bootstrap`) | Initializes config, scheduler timezone, and startup lifecycle | `Main` / `Scheduler` |
| Schedule Definition Loader (`amsScheduler_scheduleLoader`) | Loads and parses cron schedule files into bound runnable actions | `ScheduleFile` / `ScheduleDefinition` |
| Action Dispatchers (`amsScheduler_actionDispatchers`) | Region/flow-specific launchers that resolve job types and dispatch to the appropriate runner | `ActionJobFetcher` / Launchers |
| SAD Materialization Runner (`amsScheduler_sadMaterialization`) | Finds eligible SADs via AMS API and creates Scheduled Audience Instances | `SadScheduledAction` |
| Users Batch Runner (`amsScheduler_usersBatch`) | Triggers AMS batch APIs for users-link SAD optimizations | `UsersBatchSadScheduledAction` |
| SAD Integrity Runner (`amsScheduler_sadIntegrity`) | Detects stale SADs and resets next-materialized timestamps via AMS API | `SADIntegrityCheckAction` |
| EDW Feedback Runner (`amsScheduler_edwFeedback`) | Fetches published audiences from AMS and orchestrates EDW feedback push commands | `EDWFeedbackPushAction` |
| AMS REST Client Adapter (`amsScheduler_amsRestClient`) | Encapsulates all HTTP calls to AMS REST endpoints | `AMSRestClient` |
| YARN Capacity Client (`amsScheduler_yarnCapacity`) | Queries YARN queue usage to compute a safe job launch count before starting new-flow jobs | `YarnClient` |
| SSH EDW Executor (`amsScheduler_sshEdwExecutor`) | Builds and executes remote EDW feedback push commands over SSH | `EdwFeedbackOverSsh` / `KeylessSshCallWrapper` |
| Alerting Notifier (`amsScheduler_alerting`) | Sends operational notification emails for anomalies such as unverified SADs | `EmailUtil` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAmsJavaScheduler` | `continuumAmsSchedulerScheduleStore` | Loads cron schedules and action class mappings at startup | File I/O |
| `continuumAmsJavaScheduler` | `continuumAudienceManagementService` | Calls AMS REST APIs for SAD search, SAI creation, users-batch, and published-audience retrieval | HTTP/JSON |
| `amsScheduler_bootstrap` | `amsScheduler_scheduleLoader` | Bootstraps schedule loading at startup | Direct |
| `amsScheduler_scheduleLoader` | `amsScheduler_actionDispatchers` | Builds runnable actions from configured schedules | Direct |
| `amsScheduler_actionDispatchers` | `amsScheduler_sadMaterialization` | Dispatches SAD materialization jobs | Direct |
| `amsScheduler_actionDispatchers` | `amsScheduler_usersBatch` | Dispatches users batch SAD optimization jobs | Direct |
| `amsScheduler_actionDispatchers` | `amsScheduler_sadIntegrity` | Dispatches stale SAD integrity checks | Direct |
| `amsScheduler_actionDispatchers` | `amsScheduler_edwFeedback` | Dispatches EDW feedback push jobs | Direct |
| `amsScheduler_sadMaterialization` | `amsScheduler_amsRestClient` | Searches SADs and creates SAIs via AMS APIs | Direct |
| `amsScheduler_sadMaterialization` | `amsScheduler_yarnCapacity` | Checks queue headroom before launching new-flow jobs | Direct |
| `amsScheduler_sadMaterialization` | `amsScheduler_alerting` | Emails unverified SAD alerts | Direct |
| `amsScheduler_usersBatch` | `amsScheduler_amsRestClient` | Invokes AMS users-batch scheduled-audience API | Direct |
| `amsScheduler_sadIntegrity` | `amsScheduler_amsRestClient` | Finds stale SADs and resets materialization time | Direct |
| `amsScheduler_edwFeedback` | `amsScheduler_amsRestClient` | Retrieves published audiences to push | Direct |
| `amsScheduler_edwFeedback` | `amsScheduler_sshEdwExecutor` | Submits EDW feedback push commands | Direct |
| `amsScheduler_yarnCapacity` | `amsScheduler_amsRestClient` | Uses AMS API data during queue-aware execution planning | Direct |

## Architecture Diagram References

- Component: `components-continuum-ams-java-scheduler`
- Dynamic — SAD Materialization: `dynamic-ams-scheduler-sad-amsScheduler_sadMaterialization`
- Dynamic — EDW Feedback: `dynamic-ams-scheduler-edw-amsScheduler_edwFeedback`
