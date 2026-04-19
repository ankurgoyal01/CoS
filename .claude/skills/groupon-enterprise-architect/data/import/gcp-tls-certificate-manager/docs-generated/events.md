---
service: "gcp-tls-certificate-manager"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

This service does not publish or consume async events via any message bus (Kafka, RabbitMQ, SQS, GCP Pub/Sub, or similar). All coordination occurs through git-based GitOps triggers (push events on the `main` branch) and Jenkins cron scheduling. The Jenkins pipeline itself is event-driven from a CI perspective — a GitHub push event triggers DeployBot deployment — but no application-level message bus events are involved.

## Published Events

> Not applicable — this service does not publish to any message bus or event streaming system.

## Consumed Events

> Not applicable — this service does not consume from any message bus or event streaming system.

## Dead Letter Queues

> Not applicable — no message bus integration exists.
