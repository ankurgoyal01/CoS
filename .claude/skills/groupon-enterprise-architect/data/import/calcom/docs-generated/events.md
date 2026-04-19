---
service: "calcom"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Calcom does not use an external async messaging system such as Kafka, RabbitMQ, SQS, or Groupon's internal message bus. Asynchronous work is coordinated internally between `continuumCalcomService` and `continuumCalcomWorkerService` via an internal job queue backed by the shared `continuumCalcomPostgres` PostgreSQL database. The worker service polls this internal queue to process scheduled reminders, follow-up notifications, and workflow tasks.

## Published Events

> No evidence found in codebase. This service does not publish events to any external message broker.

## Consumed Events

> No evidence found in codebase. This service does not consume events from any external message broker.

## Internal Job Queue

Although not an external event bus, the service uses an internal database-backed job queue:

| Queue | Direction | Participants | Description |
|-------|-----------|-------------|-------------|
| Internal PostgreSQL job queue | `continuumCalcomService` → `continuumCalcomWorkerService` | Cal.com Service, Cal.com Worker Service | The main service creates asynchronous scheduling and reminder jobs; the worker service reads pending jobs and persists workflow state |

## Dead Letter Queues

> No evidence found in codebase. No external DLQ configured.
