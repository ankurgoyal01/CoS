---
service: "ckod-backend-jtier"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message broker. All inter-service communication is synchronous REST over HTTPS. The service polls Keboola's job queue API at regular intervals from its worker component; this polling is implemented as a scheduled background job rather than an event-driven consumer. Notifications to Google Chat are pushed synchronously during deployment-tracking request handling.

> This service does not publish or consume async events.

## Published Events

> Not applicable

## Consumed Events

> Not applicable

## Dead Letter Queues

> Not applicable
