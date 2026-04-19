---
service: "minos"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [sqs]
---

# Events

## Overview

Minos includes the `amazon-sqs-java-messaging-lib` (v1.0.4) dependency, indicating SQS integration capability. However, the primary interaction pattern for Minos is synchronous REST. The service does not publish deal lifecycle events to external topics. Scoring artifact exchange with the Flux/DS platform is performed through HDFS file uploads rather than message queues. AWS SQS is present in the dependency tree as a transport mechanism supporting the ingestion pipeline integration, but no specific topic or queue names are discoverable from the available source inventory.

## Published Events

> No evidence found in codebase. Minos does not publish domain events to a message queue. Duplicate detection results are returned synchronously to the caller.

## Consumed Events

> No evidence found in codebase. Minos does not subscribe to or consume events from a message queue. Ingestion deals are submitted synchronously via `POST /v1/duplicates`.

## Dead Letter Queues

> No evidence found in codebase.
