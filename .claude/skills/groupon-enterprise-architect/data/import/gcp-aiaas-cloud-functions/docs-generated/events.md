---
service: "gcp-aiaas-cloud-functions"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. All communication is synchronous HTTP request/response. The functions are invoked on-demand by callers (Salesforce tooling, merchant advisor dashboards, data pipelines) via direct HTTP calls to GCP Cloud Function or Cloud Run endpoints. There is no message broker, Kafka topic, Pub/Sub subscription, or queue-based trigger in the codebase.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.
