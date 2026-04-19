---
service: "tdo-team"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The tdo-team service does not use a message broker or event streaming platform. All inter-system communication is synchronous and outbound: cronjobs call Jira REST API, Google Drive/Docs API, OpsGenie API, Pingdom API, and Google Chat/Slack webhooks directly via HTTP. There are no Kafka topics, RabbitMQ queues, SQS queues, or pub/sub subscriptions consumed or published by this service.

## Published Events

> No evidence found in codebase. This service does not publish async events to any message bus or queue.

## Consumed Events

> No evidence found in codebase. This service does not consume async events from any message bus or queue.

## Dead Letter Queues

> No evidence found in codebase. No async messaging is used, so no DLQs exist.
