---
service: "cls-gcp-dags"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase. `cls-gcp-dags` is a scheduled batch pipeline service. It does not publish to or consume from any message bus, Kafka topics, or queue-based messaging systems. Pipeline execution is triggered by Google Cloud Scheduler through Airflow's native scheduler integration, not via event-driven messaging. No published events or consumed events are modeled in the architecture DSL for this service.

## Published Events

> Not applicable. This service does not publish async events. Pipeline outputs are written directly to curated downstream storage targets by the Curated Load Task (`dagLoadTask`).

## Consumed Events

> Not applicable. This service does not consume async events. Execution is initiated by Cloud Scheduler-based triggers received by the Schedule Trigger component (`dagScheduleTrigger`).

## Dead Letter Queues

> Not applicable. No message bus integration is used by this service.
