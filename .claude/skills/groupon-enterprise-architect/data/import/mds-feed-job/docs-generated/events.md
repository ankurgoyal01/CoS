---
service: "mds-feed-job"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. MDS Feed Job is a Spark batch job that interacts with its dependencies via direct API calls (HTTPS/JSON, BigQuery API, JDBC) and file I/O (GCS/HDFS). There is no Kafka, RabbitMQ, SQS, Pub/Sub, or other message-bus integration.

## Published Events

> No evidence found. This service publishes no async events or messages to any topic or queue.

## Consumed Events

> No evidence found. This service consumes no async events or messages from any topic or queue.

## Dead Letter Queues

> Not applicable. No messaging system is used.
