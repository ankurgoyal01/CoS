---
service: "janus-ui-cloud"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Janus UI Cloud does not publish or consume asynchronous events. The service is a user-facing web application that communicates exclusively via synchronous HTTPS/JSON calls (proxied to the Janus metadata service) and browser-side WebSocket connections managed by `socket.io`. No Kafka, RabbitMQ, SQS, or other message bus integrations are present in the codebase.

## Published Events

> No evidence found in codebase. This service does not publish async events.

## Consumed Events

> No evidence found in codebase. This service does not consume async events.

## Dead Letter Queues

> Not applicable. No async messaging is used by this service.
