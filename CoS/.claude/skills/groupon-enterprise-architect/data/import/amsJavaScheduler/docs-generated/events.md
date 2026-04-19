---
service: "amsJavaScheduler"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

AMS Java Scheduler does not use asynchronous messaging systems. It does not publish to or consume from Kafka, RabbitMQ, SQS, or any other message broker. All inter-service communication is synchronous HTTP/REST (calls to `continuumAudienceManagementService`) or SSH (EDW feedback push). Operational alerts are delivered via SMTP email, not through an event bus.

## Published Events

> No evidence found — this service does not publish async events to any message broker.

## Consumed Events

> No evidence found — this service does not consume async events from any message broker.

## Dead Letter Queues

> No evidence found — no DLQs are applicable as no messaging system is used.

> This service does not publish or consume async events.
