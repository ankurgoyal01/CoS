---
service: "glive-gia"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

GIA does not use a traditional async message bus (e.g., Kafka, RabbitMQ, SQS) for event-driven integration. Asynchronous work is handled internally via Resque background jobs backed by Redis. Data synchronization with external systems (Salesforce, Deal Management API, Ticketmaster, Provenue, AXS) is performed through scheduled and on-demand background jobs rather than consuming published events from a message broker.

## Published Events

> No evidence found. GIA does not publish events to any message bus or event stream. Downstream services receive data changes via direct API calls (e.g., Accounting Service, Inventory Service) initiated by GIA's web app or background workers.

## Consumed Events

> No evidence found. GIA does not subscribe to any external event topics or queues. External system updates are pulled by scheduled Resque jobs (e.g., Salesforce deal sync, Ticketmaster event import) rather than pushed via events.

## Dead Letter Queues

> Not applicable. No message broker DLQ pattern in use. Failed Resque jobs are retried according to Resque retry configuration and can be inspected via the Resque web UI.

---

> This service does not publish or consume async events via a message broker. All async processing is handled through internal Resque job queues. See [Flows](flows/index.md) for scheduled and background job patterns.
