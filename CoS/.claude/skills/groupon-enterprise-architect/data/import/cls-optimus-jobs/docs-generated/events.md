---
service: "cls-optimus-jobs"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

CLS Optimus Jobs does not publish or consume async events via a message broker. All data movement is achieved through scheduled Hive SQL batch operations orchestrated by the Optimus control plane. Source data is read from Teradata transactional databases and the Janus event dataset via direct SQL queries; transformed records are written directly to partitioned Hive tables in `grp_gdoop_cls_db`. There is no Kafka, RabbitMQ, SQS, or internal message bus integration in this service.

## Published Events

> Not applicable. This service does not publish async events.

## Consumed Events

> Not applicable. This service does not consume async events. It reads source data directly from Teradata (via Optimus `SQLExport` tasks) and from Hive tables in `grp_gdoop_cls_db` and `grp_gdoop_pde`.

## Dead Letter Queues

> Not applicable. No message queuing is used by this service.
