---
service: "mobilebot"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Mobilebot does not use a traditional async messaging system (no Kafka, RabbitMQ, SQS, or similar). Its event model is entirely driven by chat messages received and sent through Hubot adapters (Slack, Google Chat). Internal structured log events are emitted via `groupon-steno` but these are logging events, not inter-service messages.

One passive Hubot `robot.hear` listener acts as an inbound event subscription: mobilebot listens for branch-cut announcement messages in chat and auto-updates its internal Redis cache accordingly.

## Published Events

> This service does not publish async events to a message broker. All outbound communication is synchronous: chat replies via Hubot adapters and HTTP API calls to external services.

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| Chat room (Slack/GChat) | Branch-cut announcement message | `robot.hear` in `current_release_branch.js` | Updates `mobilebot:internal:ios:current_release_branch` key in Redis cache |

### Branch-Cut Announcement Detail

- **Topic**: Any chat room where mobilebot is present
- **Handler**: Passive `robot.hear` listener matching pattern `/HURRAY\.\. New release branch "([a-zA-Z0-9_\/.-]*)" has been cut/`
- **Idempotency**: Last-write-wins on the Redis cache key; re-processing the same message sets the same value
- **Error handling**: No explicit error handling; Redis write failure results in stale cache (which can be reset with `release_branch reset`)
- **Processing order**: Unordered (single instance; message arrival order from chat)

## Dead Letter Queues

> Not applicable — this service does not use a message broker.

## Structured Log Events (Internal)

Mobilebot emits structured events via `groupon-steno` to `/app/log/steno.log`. These are not inter-service events but are captured by Filebeat for log aggregation.

| Event Type | Trigger | Key Fields |
|-----------|---------|-----------|
| `app.start` | Service startup | — |
| `app.heartbeat` | Each `/heartbeat` HTTP request | — |
| `app.action` | Entry point of any Hubot command | `action`, `data` |
| `app.log` | Info or success milestones within a command | `message`, `level`, `action`, `data` |
| `app.error` | Failure within a command | `message`, `level` (fatal), `action`, `data` |
