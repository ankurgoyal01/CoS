---
service: "ad-inventory"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Ad Inventory does not use a traditional async messaging system (no Kafka, RabbitMQ, SQS, or Pub/Sub consumers or producers were found in the codebase). Asynchronous work is driven entirely by the embedded Quartz scheduler, which triggers internal batch jobs on cron schedules. External data ingestion from Rokt is performed by polling S3 rather than subscribing to a push-based event stream.

## Published Events

> No evidence found in codebase. Ad Inventory does not publish events to any message bus or topic. Metrics are emitted synchronously to SMA via HTTP.

## Consumed Events

> No evidence found in codebase. Ad Inventory does not subscribe to any external event topic or queue.

## Scheduled Internal Triggers (Quartz)

While not asynchronous messaging events, the following Quartz-triggered jobs constitute the service's internal scheduling model:

| Job | Schedule | Trigger Description |
|-----|----------|---------------------|
| `ReportGeneratorJob` | Configured per report definition | Runs the full report generation pipeline for a given report ID (DFP, LiveIntent, or Rokt source type) |
| `DFPScheduleImportJob` | Quartz cron | Polls Google Ad Manager for scheduled report completion and stages CSVs to GCS |
| `AudienceLoadJob` | Quartz cron | Refreshes audience bloom filters from GCS into the in-memory and Redis cache |
| `ReportBackfillJob` | On-demand / manual trigger | Executes historical report backfills for specified date ranges |
| `ReportMonitoringJob` | Quartz cron | Monitors report run status and sends alert emails for stalled or failed runs |
| `ReportVerification` | Quartz cron | Validates completed report instances against expected row counts and schema |

## Dead Letter Queues

> Not applicable. No message broker is used; Quartz handles retry and failure tracking internally via MySQL job state.
