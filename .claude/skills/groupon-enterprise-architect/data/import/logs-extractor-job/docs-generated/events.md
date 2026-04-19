---
service: "logs-extractor-job"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The Log Extractor Job does not use any asynchronous messaging system. It is a scheduled batch job that communicates synchronously with Elasticsearch (read), BigQuery (write), and MySQL (write). No Kafka, RabbitMQ, SQS, Pub/Sub, or similar messaging infrastructure is used.

## Published Events

> No evidence found in codebase. This service does not publish async events.

## Consumed Events

> No evidence found in codebase. This service does not consume async events.

## Dead Letter Queues

> Not applicable. This service does not use message queues.
