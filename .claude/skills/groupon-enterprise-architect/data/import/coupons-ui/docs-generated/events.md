---
service: "coupons-ui"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Coupons UI does not publish or consume asynchronous events via a message broker. The service is request/response oriented: it reads pre-populated data from Redis (written by an upstream coupon worker pipeline) and calls VoucherCloud API synchronously. Metrics are emitted to Telegraf/InfluxDB in a fire-and-forget buffered pattern, but this is observability telemetry rather than domain event messaging.

## Published Events

> No evidence found in codebase. This service does not publish domain events to any message bus or queue.

## Consumed Events

> No evidence found in codebase. This service does not subscribe to any message bus topics or queues. Redis data is treated as a read-through cache, not as an event stream.

## Dead Letter Queues

> Not applicable. No async messaging is used.
