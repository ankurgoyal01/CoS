---
service: "pricing-control-center-ui"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

This service does not publish or consume async events. It is a synchronous, request-driven web application. All operations are performed via HTTP calls to the downstream `pricing-control-center-jtier` service in direct response to user browser actions. No Kafka, RabbitMQ, SQS, Pub/Sub, or other message-bus integration was found.

The Filebeat/Kafka pipeline referenced in deploy configs (`filebeatKafkaEndpoint`) is solely for log shipping (steno application logs to the ELK stack), not for application-level event messaging.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.
