---
service: "ckod-worker"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

CKOD Worker does not publish or consume async events via a message broker. All integration with external systems is performed through direct HTTPS API calls (Jira, JSM, Keboola, Vertex AI, Google Chat) and direct database reads (MySQL, PostgreSQL). Notifications are sent synchronously as Google Chat webhook calls. There is no evidence of Kafka, RabbitMQ, SQS, or any other message bus integration in the architecture model.

## Published Events

> No evidence found in codebase. This service does not publish async events to a message broker.

## Consumed Events

> No evidence found in codebase. This service does not consume async events from a message broker.

## Dead Letter Queues

> Not applicable. No message broker integration is present.
