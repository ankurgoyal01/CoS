---
service: "elit-github-app"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message broker (no Kafka, RabbitMQ, SQS, or similar). The service operates exclusively over synchronous HTTP: it receives GitHub webhook POST requests and calls back to the GitHub Enterprise API synchronously. The only asynchronous behaviour within the service is internal — check scanning work is submitted to a fixed thread pool (`Executors.newFixedThreadPool(20)`) after the initial check run creation, but this is in-process concurrency, not external messaging.

## Published Events

> No evidence found in codebase. This service does not publish to any external message topic or queue.

## Consumed Events

> No evidence found in codebase. This service does not consume from any external message topic or queue. Inbound GitHub webhook calls are received over HTTPS POST to `/elit-github-app/webhook`, not via a message broker.

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration exists.
