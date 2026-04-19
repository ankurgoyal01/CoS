---
service: "coffee-to-go"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message broker (Kafka, RabbitMQ, SQS, etc.).

Usage tracking events are submitted synchronously via the REST API (`POST /api/usage/events`) and written directly to the `usage_events` PostgreSQL table. These are not brokered events but rather HTTP-based telemetry ingestion.

Data ingestion from external sources (Salesforce, EDW, DeepScout S3) is performed by n8n workflows via scheduled batch pulls, not event-driven messaging.
