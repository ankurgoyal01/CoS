---
service: "crossplane"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

Crossplane does not use traditional message-bus or event-streaming systems (no Kafka, RabbitMQ, SQS, Pub/Sub, or similar). All state changes are communicated through the Kubernetes control-plane event loop: the controller watches for resource changes via the Kubernetes watch API and reconciles asynchronously by acting on observed state changes. Kubernetes `Event` objects are created by the controller to record notable state transitions, but these are not published to an external messaging system.

## Published Events

> No evidence found in codebase.

Crossplane does not publish events to external message buses. Resource lifecycle transitions (e.g., bucket provisioning completion) are surfaced as Kubernetes `status.conditions` updates on the `Bucket` / `XBucket` resources.

## Consumed Events

> No evidence found in codebase.

Crossplane does not consume events from external message buses. It watches Kubernetes resource changes via the standard Kubernetes informer/watch mechanism.

## Dead Letter Queues

> Not applicable. No async messaging queues are configured.
