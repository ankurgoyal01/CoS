---
service: "ultron-api"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

ultron-api does not use asynchronous message-broker-based events as part of its primary flows. It is a synchronous, request/response service for API consumers and an HTML UI for operators. The internal Quartz Scheduler fires timed events internally (watchdog checks) that result in synchronous SMTP email dispatch via the Email Manager component — these are internal scheduler triggers, not external message bus events.

## Published Events

> No evidence found in codebase. ultron-api does not publish events to any external message broker or queue.

## Consumed Events

> No evidence found in codebase. ultron-api does not consume events from any external message broker or queue.

## Internal Scheduling Events

While not external async events, the Quartz Scheduler within `continuumUltronApi` fires internal triggers on a configurable schedule:

| Trigger | Type | Handler | Side Effect |
|---------|------|---------|-------------|
| Watchdog check | Quartz cron/interval trigger | `scheduler` component | Queries `repositoryLayer` for overdue jobs; if found, invokes `emailManager` to send alert emails via SMTP |

See [Watchdog Alerting Flow](flows/watchdog-alerting.md) for the full process.

## Dead Letter Queues

> Not applicable. This service does not use async messaging and has no dead letter queues.
