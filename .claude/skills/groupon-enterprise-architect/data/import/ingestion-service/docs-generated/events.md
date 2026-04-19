---
service: "ingestion-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

The ingestion-service declares a dependency on `jtier-messagebus-client` (Groupon's internal message bus library) in `pom.xml`, indicating the infrastructure capability exists. However, no active event publication or consumption was observed in the source code — all current cross-service interactions are synchronous REST calls. The service also lists `tsd_aggregator` as an infrastructure dependency in `.service.yml`, which handles metrics aggregation. Background jobs (Quartz) are internally scheduled and do not produce or consume external async events.

## Published Events

> No evidence found in codebase. The service does not publish events to any message bus topic.

## Consumed Events

> No evidence found in codebase. The service does not subscribe to any message bus topics.

## Dead Letter Queues

> No evidence found in codebase.

> This service does not publish or consume async events. All integrations are synchronous HTTPS/REST. Failed Salesforce ticket creation requests are queued in MySQL (`sf_ticket_creation_requests` table) and retried via an internal Quartz job rather than a message bus DLQ.
