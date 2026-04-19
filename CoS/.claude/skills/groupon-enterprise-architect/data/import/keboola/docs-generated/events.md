---
service: "keboola"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Keboola Connection does not use a traditional message broker (Kafka, RabbitMQ, SQS, etc.) for async event publishing or consumption. Internal pipeline stage transitions are managed by the `kbcPipelineOrchestrator` component, which coordinates stage-to-stage handoffs within the Keboola platform. Operational status events (run success, failure, escalation) are emitted to Google Chat via the `kbcOpsNotifier` component using outbound webhooks.

## Published Events

> No evidence found in codebase. No message-bus topic or queue publications are defined. Operational alerts are delivered to Google Chat via webhook (see [Integrations](integrations.md)) rather than a pub/sub system.

## Consumed Events

> No evidence found in codebase. Keboola Connection does not subscribe to any external message queues or event streams. Pipeline runs are triggered by internal schedules configured within the Keboola orchestrator.

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events via a message broker.
