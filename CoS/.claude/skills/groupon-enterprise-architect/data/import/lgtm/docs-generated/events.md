---
service: "lgtm"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase. The LGTM stack does not use asynchronous message brokers (such as Kafka, RabbitMQ, or SQS). All telemetry signal transport between components uses synchronous push protocols: OTLP/gRPC, OTLP/HTTP, and Prometheus remote write. There are no published or consumed async events.

## Published Events

> Not applicable. The LGTM stack does not publish to any message queue or event bus. Telemetry data is pushed synchronously to downstream backends (Tempo, Elastic APM, Thanos) via OTLP and remote write protocols.

## Consumed Events

> Not applicable. The LGTM stack does not consume from any message queue or event bus. Telemetry signals are received synchronously from instrumented workloads over OTLP gRPC (port 4317) and OTLP HTTP (port 4318).

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events. No dead letter queues are configured.
