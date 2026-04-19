---
service: "nifi-3pip"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase of async event publishing or consumption by nifi-3pip itself. The service is a NiFi cluster deployment; any message-bus integration (e.g., Kafka, PubSub) would be configured within NiFi flow definitions via the NiFi UI, not in the service's infrastructure code. No Kafka, RabbitMQ, SQS, or Pub/Sub client configuration is present in the repository source files.

## Published Events

> No evidence found in codebase. Event publishing, if any, is defined within NiFi processor flows managed via the NiFi UI and not captured in this repository's infrastructure layer.

## Consumed Events

> No evidence found in codebase. Event consumption, if any, is defined within NiFi processor flows managed via the NiFi UI and not captured in this repository's infrastructure layer.

## Dead Letter Queues

> No evidence found in codebase.
