---
service: "larc"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

LARC does not use an asynchronous message broker (Kafka, RabbitMQ, SQS, or similar). Rate updates are delivered synchronously over HTTP/JSON directly to the Travel Inventory Service (`continuumTravelInventoryService`). The service is triggered by its own internal scheduled workers and by synchronous API calls — not by consuming external event streams.

## Published Events

> No evidence found in codebase. LARC publishes rate updates synchronously via HTTP to `continuumTravelInventoryService`, not through a message bus or event topic.

## Consumed Events

> No evidence found in codebase. LARC does not subscribe to any message bus topics or queues. Ingestion is triggered by the internal FTP monitoring scheduler and by direct API calls.

## Dead Letter Queues

> Not applicable. No async messaging infrastructure is used by this service.
