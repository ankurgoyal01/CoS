---
service: "transporter-jtier"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message bus. Background processing is driven by an internal Quartz scheduler (`jtier-quartz-bundle`) rather than an external event or message system. The `sf-upload-worker` Quartz job is triggered on a schedule internal to the JVM; it does not subscribe to or publish Kafka, SQS, RabbitMQ, or any other external messaging topics.

## Published Events

> No evidence found in codebase. No Kafka, SQS, PubSub, or RabbitMQ publishers detected.

## Consumed Events

> No evidence found in codebase. No Kafka, SQS, PubSub, or RabbitMQ consumers detected.

## Dead Letter Queues

> Not applicable. No async messaging system is in use.
