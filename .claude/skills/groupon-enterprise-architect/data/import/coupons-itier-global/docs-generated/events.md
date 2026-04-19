---
service: "coupons-itier-global"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. All integrations are synchronous REST calls. The only background processing is an internal cron job (`redirectCacheCron`) that refreshes Redis cache entries on a schedule — this is an internal scheduled task, not a messaging system consumer or producer.

## Published Events

> Not applicable. `coupons-itier-global` does not publish events to any message bus or queue.

## Consumed Events

> Not applicable. `coupons-itier-global` does not consume events from any message bus or queue.

## Dead Letter Queues

> Not applicable. No async messaging is used by this service.
