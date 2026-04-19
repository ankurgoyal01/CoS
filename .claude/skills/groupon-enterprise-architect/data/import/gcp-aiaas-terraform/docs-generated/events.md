---
service: "gcp-aiaas-terraform"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [gcp-cloud-tasks, gcp-cloud-scheduler]
---

# Events

## Overview

The AIaaS platform does not use a traditional message broker (Kafka, RabbitMQ, Pub/Sub). Asynchronous work is instead coordinated via GCP Cloud Scheduler triggering GCP Cloud Tasks, which in turn invoke Cloud Run services over HTTPS. Cloud Composer (Airflow) orchestrates multi-step batch pipelines via DAG task dependencies rather than event streams. No Pub/Sub topics, Kafka topics, or SQS queues are declared in this Terraform repository.

## Published Events

> No evidence found in codebase. This service does not publish events to a message broker or event streaming system. Async work is delegated via GCP Cloud Tasks (HTTP invocation), not event publishing.

## Consumed Events

> No evidence found in codebase. This service does not consume events from a message broker or event streaming system. The Cloud Scheduler / Cloud Tasks pattern is a push-based HTTPS invocation, not event consumption.

## Scheduled Triggers (Cloud Scheduler Jobs)

These are the closest equivalent to "events" in this platform — scheduled trigger points that initiate asynchronous work:

| Job Name | Schedule (cron) | Timezone | Target | Action |
|----------|----------------|----------|--------|--------|
| `aidg-top-deals-async` | `0 0 * * *` (daily midnight) | UTC | Cloud Tasks queue | Enqueues task that invokes `aidg-top-deals` Cloud Run service at `/top-deals-async` |

### `aidg-top-deals-async` Detail

- **Trigger**: Cloud Scheduler fires at `0 0 * * *` UTC (daily midnight)
- **Target queue**: GCP Cloud Tasks (enqueues HTTP task)
- **Downstream invocation**: `https://aidg-top-deals-364685817243.us-central1.run.app/top-deals-async`
- **Auth**: OIDC token via service account `loc-sa-vertex-ai-pipeline@prj-grp-aiaas-dev-94dd.iam.gserviceaccount.com`
- **Evidence**: `envs/dev/us-central1/gcp-cloud-scheduler/terragrunt.hcl`

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration is declared for Cloud Tasks or any other queue in this repository.
