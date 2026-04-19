---
service: "seer-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Seer Service does not use asynchronous messaging. All data ingestion is performed synchronously via Retrofit HTTP clients, either triggered by Quartz scheduled jobs or by manual REST API calls from operators. There are no Kafka, RabbitMQ, SQS, or other message-bus integrations present in the codebase.

## Published Events

> No evidence found in codebase. This service does not publish any async events.

## Consumed Events

> No evidence found in codebase. This service does not consume any async events.

## Dead Letter Queues

> Not applicable. No async messaging is used by this service.
