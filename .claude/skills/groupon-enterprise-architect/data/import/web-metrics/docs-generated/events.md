---
service: "web-metrics"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

Web Metrics does not use any message bus, event queue (Kafka, RabbitMQ, SQS, GCP Pub/Sub, or Mbus). It is a batch CronJob that runs on a fixed schedule, calls the Google PageSpeed Insights API synchronously, and writes results directly to Telegraf using the Influx Line Protocol. There are no published or consumed async events.

## Published Events

> No evidence found in codebase.

This service does not publish async events. Metric data points are written synchronously to Telegraf via `lib/telegraph.js` using the `influx` client.

## Consumed Events

> No evidence found in codebase.

This service does not subscribe to or consume async events from any message broker.

## Dead Letter Queues

> No evidence found in codebase.

No dead-letter queues are configured. Failed Lighthouse or PSI API runs are logged via `itier-tracing` and the CronJob's `OnFailure` restart policy handles pod-level retries (up to 6 backoff attempts by default).
