---
service: "itier-3pip-docs"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

`itier-3pip-docs` is a synchronous request/response web application. It does not directly publish or consume asynchronous events via a message bus (Kafka, RabbitMQ, SQS, or similar). All operations are performed via synchronous HTTP and GraphQL calls at request time. Log shipping to Kafka is handled by the infrastructure-level Filebeat sidecar (configured via `filebeatKafkaEndpoint` in `.deploy-configs/`), which is an operational concern rather than application-level event publishing.

## Published Events

> This service does not publish async events.

## Consumed Events

> This service does not consume async events.

## Dead Letter Queues

> Not applicable. No async messaging is used by this service.
