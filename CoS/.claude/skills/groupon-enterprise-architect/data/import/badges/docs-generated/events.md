---
service: "badges-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

The Badges Service does not publish or consume asynchronous events via a message bus (Kafka, RabbitMQ, SQS, or similar). All badge state updates are performed synchronously through REST API calls and direct Redis writes. Background badge refresh is driven by scheduled Quartz jobs rather than event subscriptions.

## Published Events

> No evidence found in codebase.

This service does not publish async events.

## Consumed Events

> No evidence found in codebase.

This service does not consume async events.

## Dead Letter Queues

> No evidence found in codebase.

No DLQs are configured. Retry and fallback handling for failed outbound calls to dependencies (Janus, DCS, Localization, Taxonomy, Watson KV) is performed inline within the request thread, returning zero/default values on timeout or error.
