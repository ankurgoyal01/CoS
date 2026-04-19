---
service: "lavatoryRunner"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Lavatory Runner does not use any asynchronous messaging system. It is a scheduled batch container that operates synchronously: it connects to Artifactory, evaluates retention policies, and deletes matching artifacts within a single execution. All output is written to log files and forwarded to Splunk; no events are published to or consumed from Kafka, RabbitMQ, SQS, or any other message bus.

## Published Events

> No evidence found in codebase. This service does not publish async events.

## Consumed Events

> No evidence found in codebase. This service does not consume async events.

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events.
