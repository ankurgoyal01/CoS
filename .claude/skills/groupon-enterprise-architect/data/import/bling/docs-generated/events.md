---
service: "bling"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. bling is a client-side single-page application that operates exclusively over synchronous HTTP. All data fetching and mutation is performed via REST calls proxied through `blingNginx` to the Accounting Service and File Sharing Service backends. There is no message broker, event bus, or async queue integration in the bling application layer.

## Published Events

> No evidence found in codebase. bling does not publish to any message bus, queue, or topic.

## Consumed Events

> No evidence found in codebase. bling does not consume from any message bus, queue, or topic.

## Dead Letter Queues

> Not applicable. No async messaging infrastructure is used by this service.
