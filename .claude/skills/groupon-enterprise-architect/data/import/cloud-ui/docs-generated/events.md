---
service: "cloud-ui"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

Cloud UI and its Cloud Backend API do not publish to or consume from any message bus, Kafka topic, SQS queue, or similar async messaging system. All inter-component communication is synchronous REST over HTTPS. The GitOps deployment pipeline is driven by synchronous API calls from the frontend and polled status checks — not by events.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events.
