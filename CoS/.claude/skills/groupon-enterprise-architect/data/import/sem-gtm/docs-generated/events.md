---
service: "sem-gtm"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

`sem-gtm` does not publish or consume async events through any Groupon-managed message broker (Kafka, RabbitMQ, Pub/Sub, etc.). Tag event data flows synchronously from client HTTP requests into the GTM tagging server, which processes and forwards to Google's platform in real time. All asynchronous fan-out from tag events (e.g., to Google Analytics, Google Ads, or other GTM tag destinations) is handled internally by the GTM Cloud runtime and is not visible or configurable at the Kubernetes deployment level.

## Published Events

> No evidence found in codebase. This service does not publish async events to any Groupon-managed message bus.

## Consumed Events

> No evidence found in codebase. This service does not consume events from any Groupon-managed message bus.

## Dead Letter Queues

> Not applicable. This service does not use async messaging.
