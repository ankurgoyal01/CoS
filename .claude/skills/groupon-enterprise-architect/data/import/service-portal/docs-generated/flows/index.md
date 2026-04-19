---
service: "service-portal"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 7
---

# Flows

Process and flow documentation for Service Portal.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Service Registration and Metadata Sync](service-registration-and-metadata-sync.md) | synchronous | API call (POST /api/v2/services) | An engineering team registers a new service and populates its metadata in the catalog |
| [Scheduled Service Checks Execution](scheduled-service-checks-execution.md) | scheduled | Sidekiq-Cron schedule | Sidekiq workers periodically evaluate all registered services against governance checks and record results |
| [Service Dependency Graph Query](service-dependency-graph-query.md) | synchronous | API call (GET /api/v2/services/{id}/dependencies) | A consumer queries the declared dependency graph for a specific service |
| [Operational Readiness Review](operational-readiness-review.md) | event-driven | API action / check result changes | An ORR workflow is initiated and progressed for a service approaching production |
| [Cost Tracking and Alerting](cost-tracking-and-alerting.md) | scheduled | Sidekiq-Cron schedule | Workers collect per-service cost data, evaluate against thresholds, and send alerts via Google Chat |
| [GitHub Repository Validation and Sync](github-repository-validation-and-sync.md) | event-driven | GitHub Enterprise webhook (push / pull_request) | Inbound GitHub webhook events trigger repository metadata sync and governance data updates |
| [Service Inactivity Report Generation](service-inactivity-report-generation.md) | scheduled | Sidekiq-Cron schedule | Workers identify inactive services and generate inactivity reports served via the reports endpoint |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

- The [GitHub Repository Validation and Sync](github-repository-validation-and-sync.md) flow spans GitHub Enterprise and Service Portal, triggered by GitHub Enterprise webhook events.
- The [Operational Readiness Review](operational-readiness-review.md) flow involves Jira Cloud for issue tracking (stub) and Google Chat for notifications.
- The [Cost Tracking and Alerting](cost-tracking-and-alerting.md) and [Scheduled Service Checks Execution](scheduled-service-checks-execution.md) flows emit notifications to Google Chat spaces, spanning Service Portal and Google Chat.

For cross-service architecture context, see the central architecture model under the `continuum` system.
