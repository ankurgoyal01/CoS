---
service: "grouponlive-inventory-service-jtier"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

The Groupon Live Inventory Service JTier does not publish or consume asynchronous messages via a message bus, queue, or event streaming system. The service operates exclusively through synchronous HTTP REST interactions (inbound and outbound). Async processing within the service is performed via internal Quartz job scheduling (in-process), not via external message brokers.

The `janus_message` table exists in the database schema (containing `payload`, `processing_status`, `destination`, `attempts` columns), which indicates a message-relay pattern may have existed or is partially implemented, but no active producer or consumer code was identified for an external messaging system in the current codebase.

## Published Events

> No evidence found in codebase.

This service does not publish events to an external message bus or topic.

## Consumed Events

> No evidence found in codebase.

This service does not consume events from an external message bus or topic.

## Dead Letter Queues

> No evidence found in codebase.

No dead letter queues are configured. Partner API call failures are handled via exception handling and error alerting through the `/v1/alerts/{alert_handler}` endpoint backed by `glive-inventory-rails`.
