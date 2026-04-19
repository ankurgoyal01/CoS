---
service: "mls-rin"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

MLS RIN is a synchronous read-only HTTP service. It does not publish or consume any asynchronous events, message queue topics, or Kafka streams. All data retrieval is performed on-demand in response to inbound HTTP requests. Write-side event processing and data pipeline ingestion are handled by MLS Yang and associated pipeline services that populate the PostgreSQL read models that MLS RIN queries.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.

> This service does not publish or consume async events. It is a synchronous HTTP read-only facade.
