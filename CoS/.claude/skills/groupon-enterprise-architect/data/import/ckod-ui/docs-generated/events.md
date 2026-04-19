---
service: "ckod-ui"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

ckod-ui does not use any asynchronous messaging system (no Kafka, RabbitMQ, Pub/Sub, or similar). All communication is synchronous — either HTTP REST calls from the browser to the Next.js API routes, or server-side HTTP calls from API routes to external services (JIRA, Keboola, Vertex AI, Google Chat, etc.).

Notifications to Google Chat (deployment updates, handover notes) are sent as synchronous HTTP POST webhook calls from the server, not via a message broker.

## Published Events

> No evidence found in codebase. ckod-ui does not publish events to any message broker or topic.

## Consumed Events

> No evidence found in codebase. ckod-ui does not subscribe to any message broker topics or queues.

## Dead Letter Queues

> Not applicable. No asynchronous messaging is used by this service.
