---
service: "seo-local-proxy"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

SEO Local Proxy does not publish or consume async events via a message bus (no Kafka, RabbitMQ, SQS, or Pub/Sub integration found in the codebase). All coordination between components is via direct file system operations (cron job writes to S3; Nginx reads from S3 via HTTP proxy). The cron job is triggered by a Kubernetes CronJob schedule, not by an event.

## Published Events

> No evidence found in codebase.

This service does not publish async events.

## Consumed Events

> No evidence found in codebase.

This service does not consume async events.

## Dead Letter Queues

> No evidence found in codebase.

No message queues are used; therefore no dead letter queues exist.
