---
service: "AudienceCalculationSpark"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

AudienceCalculationSpark does not publish or consume any asynchronous events via a message broker (no Kafka, RabbitMQ, SQS, or similar). All inter-service communication is synchronous: jobs are triggered by `spark-submit` with a JSON payload, and results are reported back to `continuumAudienceManagementService` via HTTPS PUT/POST calls.

> This service does not publish or consume async events. All communication is synchronous — see [Integrations](integrations.md) for the outbound AMS callback pattern.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.
