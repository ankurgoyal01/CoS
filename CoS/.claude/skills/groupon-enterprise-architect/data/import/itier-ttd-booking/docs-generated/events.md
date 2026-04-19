---
service: "itier-ttd-booking"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. All interactions are synchronous REST request/response. Booking and reservation state changes are driven by polling (`/live/deals/{dealId}/reservation/status.json`) rather than event-driven notification.

## Published Events

> No evidence found. This service does not publish async events.

## Consumed Events

> No evidence found. This service does not consume async events.

## Dead Letter Queues

> Not applicable — no messaging systems are used.
