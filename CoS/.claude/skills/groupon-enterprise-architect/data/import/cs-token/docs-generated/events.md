---
service: "cs-token"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

CS Token Service does not publish or consume async events. All interactions are synchronous request/response over HTTPS. The `resque` gem is present in the Gemfile and is used solely as a Redis connection namespace (`Resque.tokenizer_redis`) — no background jobs or Resque queues are defined in the codebase.

## Published Events

> No evidence found in codebase.

This service does not publish any async events.

## Consumed Events

> No evidence found in codebase.

This service does not consume any async events.

## Dead Letter Queues

> No evidence found in codebase.

No DLQs configured. The service does not use any message bus.
