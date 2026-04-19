---
service: "api-proxy"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. API Proxy operates as a purely synchronous gateway. All interactions — request routing, rate-limit counter operations, client identity lookups, reCAPTCHA validation, and BEMOD data retrieval — are performed via synchronous HTTP or direct in-process calls.

## Published Events

> Not applicable — API Proxy publishes no async events to any message bus or topic.

## Consumed Events

> Not applicable — API Proxy consumes no async events from any message bus or topic.

## Dead Letter Queues

> Not applicable — No async messaging is used by this service.
