---
service: "amsJavaScheduler"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for AMS Java Scheduler.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Scheduler Startup and Schedule Loading](scheduler-startup.md) | scheduled | Kubernetes CronJob pod start | Bootstraps configuration, loads cron schedule definitions, and registers actions with the cron4j engine |
| [SAD Materialization](sad-materialization.md) | scheduled | cron4j — nightly per region | Finds eligible Scheduled Audience Definitions and creates Scheduled Audience Instances via the AMS REST API |
| [EDW Feedback Push](edw-feedback-push.md) | scheduled | cron4j — nightly per region | Retrieves published audiences from AMS and executes EDW feedback push scripts over SSH to deliver data to Teradata |
| [SAD Integrity Check](sad-integrity-check.md) | scheduled | cron4j — nightly | Detects stale SADs whose next-materialized timestamps are overdue and resets them via the AMS REST API |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

The SAD Materialization flow and EDW Feedback Push flow both cross into `continuumAudienceManagementService`. These are documented in the central architecture dynamic views:

- `dynamic-ams-scheduler-sad-amsScheduler_sadMaterialization` — SAD Materialization Execution Flow
- `dynamic-ams-scheduler-edw-amsScheduler_edwFeedback` — EDW Feedback Push Flow
