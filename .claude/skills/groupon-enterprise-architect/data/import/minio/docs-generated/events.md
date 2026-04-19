---
service: "minio"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase. This service does not publish or consume async events via any message bus (Kafka, RabbitMQ, SQS, Pub/Sub, or similar). MinIO is a synchronous object storage service that responds to direct S3 API calls. No event producer or consumer configuration is present in this repository.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.

> Note: MinIO does support bucket notifications (webhooks, Kafka, AMQP, etc.) as a built-in feature, but no such notification targets are configured in this repository's deployment manifests. If bucket notifications are required, they must be configured post-deployment via the MinIO console or `mc` CLI.
