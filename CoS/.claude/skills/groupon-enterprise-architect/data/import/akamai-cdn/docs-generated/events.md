---
service: "akamai-cdn"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events through an internal messaging system (e.g., Kafka, RabbitMQ, or SQS). The `akamaiCdnConfiguration` component internally publishes CDN change and health telemetry to the `akamaiCdnObservability` component, but this is a bounded, intra-container telemetry flow rather than an externally consumable event stream. All observable signals flow from Akamai's own DataStream or reporting APIs.

## Published Events

> No evidence found of externally published events. The internal telemetry relationship between `akamaiCdnConfiguration` and `akamaiCdnObservability` is a component-level signal, not a message-bus event.

## Consumed Events

> No evidence found of consumed events from any messaging system.

## Dead Letter Queues

> Not applicable — no async messaging infrastructure is used by this service.
