---
service: "optimus-prime-api"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Optimus Prime API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Create and Schedule ETL Job](create-and-schedule-etl-job.md) | synchronous | HTTP POST from API consumer | Creates a new job definition, validates it, persists to PostgreSQL, and registers a Quartz trigger |
| Execute ETL Job via NiFi | scheduled | Quartz Scheduler trigger fires | Loads job config, starts NiFi process group, tracks run status, sends result notification |
| Job Run Tracking and Archival | scheduled | Quartz `MetricsAndArchiveJob` | Calculates run metrics and moves old run records to the archived_runs table |
| User and Connection Management | synchronous | HTTP CRUD from API consumer | Creates/updates data source connections with encrypted credential storage and user/group management |
| Health Check and Dependency Validation | scheduled | Quartz `NiFiHealthcheckMetricsJob` | Polls NiFi health, records metrics, and reports degradation |
| Disabled User Job Cleanup | scheduled | Quartz `DisabledUsersJob` | Queries Active Directory for disabled users, disables their jobs, and unschedules Quartz triggers |

> Flows without links are documented above but flow detail files are pending generation.

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

The **Execute ETL Job via NiFi** flow is the primary cross-service flow. Its representative dynamic view is `dynamic-job-run-orchestration`, defined in `architecture/views/dynamics/job-run-orchestration.dsl`. This view captures the interaction between `apiEndpoints`, `orchestrationEngine`, `opApi_persistenceLayer`, `nifiIntegration`, `continuumOptimusPrimeNifi`, `bigQueryWarehouse`, `notificationAdapter`, and `smtpRelay`.
