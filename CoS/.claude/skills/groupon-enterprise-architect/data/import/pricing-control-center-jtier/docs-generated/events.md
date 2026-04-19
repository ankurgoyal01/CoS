---
service: "pricing-control-center-jtier"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [smtp]
---

# Events

## Overview

Pricing Control Center JTier does not publish or consume events via a message broker (no Kafka, RabbitMQ, or SQS integration is present in the codebase). The service uses an internal in-process job queue (Quartz scheduler with a PostgreSQL job store) for async work coordination between its own components. The only outbound async communication is email notification via SMTP for operational alerts and Custom ILS go-live notifications.

## Published Events

> No evidence found in codebase of broker-based event publication (Kafka/SQS/PubSub topics).

## Consumed Events

> No evidence found in codebase of broker-based event consumption.

## Email Notifications (SMTP)

While not a formal event system, the service dispatches transactional emails at key workflow points. These are sent via the configured SMTP relay (`smtp.snc1`, port 25 in dev/staging).

| Trigger | Recipients | Purpose |
|---------|-----------|---------|
| `ILSSchedulingJob` failure | `dp-engg@groupon.com` | Alerts engineering team when a sale scheduling job fails |
| `ILSSchedulingSubJob` error | `dp-engg@groupon.com` | Alerts on sub-job product batch failures |
| `CustomILSFetchDealOptionsJob` error | Configured `confirmerEmailId` (`price-tools@groupon.com` in dev) | Notifies stakeholders when deal option fetch fails for an upcoming Custom ILS |
| `CustomILSGoLiveJob` fires at sale start time | Data Science and sales team | Go-live notification with sale details, algorithm splits, deal counts, and flux run dates |

## Dead Letter Queues

> Not applicable. No broker-based messaging; failed Quartz jobs are tracked in PostgreSQL via task status records and retried by `CheckForPendingSalesJob`.
