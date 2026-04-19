---
service: "forex-ng"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Forex NG does not use asynchronous event-driven messaging. It operates through synchronous request/response interactions (REST API calls to NetSuite) and a scheduled Quartz cron job that writes output directly to AWS S3 object storage. There is no Kafka, RabbitMQ, SQS, or any other message broker integration in this service.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.

This service does not publish or consume async events.
