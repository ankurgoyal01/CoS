---
service: "relevance-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Based on the architecture DSL, the Relevance Service primarily operates as a synchronous request/response service. Its main interaction pattern is REST-based query orchestration -- receiving search requests, delegating to search providers, and returning ranked results.

The Indexer component performs batch ingestion from the Enterprise Data Warehouse (EDW), which may involve event-driven triggers for index rebuild operations, but no explicit message bus topics or async event contracts are defined in the architecture model.

## Published Events

No async events published by this service are defined in the architecture model.

> If the service publishes search analytics events, index-update notifications, or ranking model refresh signals, these should be documented by the service owner once identified in the source repository.

## Consumed Events

No async events consumed by this service are defined in the architecture model.

> The Indexer component's batch ingestion from EDW may be triggered by scheduled jobs or external signals. Service owners should document the exact triggering mechanism.

## Dead Letter Queues

No dead letter queues are defined in the architecture model.

> This service does not publish or consume async events based on the available architecture DSL. If async messaging exists in the implementation, service owners should update this document with topic/queue details.
