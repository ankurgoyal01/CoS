---
service: "seo-deal-redirect"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase. SEO Deal Redirect does not publish or consume async events via any message bus (Kafka, Pub/Sub, RabbitMQ, SQS, or similar). All inter-service communication is synchronous HTTPS (outbound PUT requests to the SEO Deal API). Internal pipeline state is communicated via Airflow XCom and Hive tables.

## Published Events

> No evidence found in codebase. This service does not publish events to any message topic or queue.

## Consumed Events

> No evidence found in codebase. This service does not subscribe to or consume events from any message topic or queue. The pipeline is triggered exclusively by an Airflow schedule (`0 5 15 * *` in production).

## Dead Letter Queues

> No evidence found in codebase. No dead letter queues are configured.
