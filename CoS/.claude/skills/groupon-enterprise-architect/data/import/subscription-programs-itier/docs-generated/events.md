---
service: "subscription-programs-itier"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

subscription-programs-itier does not use asynchronous messaging for its core subscription operations. All integrations — including enrollment, membership status checks, and billing — use synchronous REST calls. Membership status after enrollment initiation is determined by polling via `GET /programs/select/poll` rather than event subscription. Tracking events are emitted synchronously via `tracking-hub-node` to Tracking Hub.

## Published Events

> No evidence found in codebase. This service does not publish async events to a message bus or queue.

## Consumed Events

> No evidence found in codebase. This service does not consume async events. Integration with the Groupon Subscriptions API uses synchronous REST with client-side polling for status updates.

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events.
