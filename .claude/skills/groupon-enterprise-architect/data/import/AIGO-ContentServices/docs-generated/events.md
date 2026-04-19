---
service: "AIGO-ContentServices"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

AIGO-ContentServices does not use asynchronous messaging systems (Kafka, RabbitMQ, SQS, Pub/Sub, or similar). All inter-service communication is synchronous HTTP/REST. Content generation tasks are handled within a single synchronous HTTP request using Python `asyncio` for internal concurrency (parallel section processing), but no async messaging infrastructure is involved.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.

> This service does not publish or consume async events. All workflows are driven by synchronous HTTP request/response cycles.
