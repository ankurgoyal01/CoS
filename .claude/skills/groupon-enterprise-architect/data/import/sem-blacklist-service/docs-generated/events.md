---
service: "sem-blacklist-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The SEM Blacklist Service does not use an asynchronous message bus. All integrations are synchronous: the service exposes a REST API for real-time read/write operations, polls the Asana REST API on a Quartz schedule to detect pending denylist change requests, and polls the Google Sheets API on a Quartz schedule to refresh PLA blacklists. No Kafka, RabbitMQ, SQS, or other message broker is used.

## Published Events

> No evidence found in codebase. This service does not publish async events to any message bus.

## Consumed Events

> No evidence found in codebase. This service does not consume async events from any message bus.

## Dead Letter Queues

> Not applicable. No async messaging is configured.
