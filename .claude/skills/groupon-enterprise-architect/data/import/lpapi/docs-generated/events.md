---
service: "lpapi"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. LPAPI and its companion workers (`continuumLpapiAutoIndexer`, `continuumLpapiUgcWorker`) operate exclusively over synchronous REST calls and direct JDBC connections to PostgreSQL. There is no evidence of a message bus, Kafka, RabbitMQ, SQS, or any other async messaging system in the federated architecture model.

All inter-process coordination is synchronous:

- `continuumLpapiApp` triggers worker runs via application-level orchestration hooks (`appAutoIndexCoordinator`, `appUgcOrchestrator`)
- Workers read configuration and write results directly to `continuumLpapiPrimaryPostgres` over JDBC
- Downstream services (`continuumRelevanceApi`, `continuumUgcService`, `continuumTaxonomyService`) are called over HTTP

## Published Events

> Not applicable. No async events are published by this service.

## Consumed Events

> Not applicable. No async events are consumed by this service.

## Dead Letter Queues

> Not applicable. No message queues are in use.
