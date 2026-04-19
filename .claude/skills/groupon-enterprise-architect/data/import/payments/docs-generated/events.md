---
service: "payments"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase for async messaging patterns used by the Payments Service. The architecture DSL model does not define any event publishing or consumption for this service. Payment results are returned synchronously to callers (Orders Service) via the REST API.

## Published Events

> No evidence found in codebase. The Payments Service does not appear to publish async events based on the current architecture model. Payment state changes are communicated synchronously back to the calling service (Orders Service), which then publishes its own order lifecycle events to the Message Bus.

## Consumed Events

> No evidence found in codebase. The Payments Service does not appear to consume async events based on the current architecture model.

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events based on available evidence.
