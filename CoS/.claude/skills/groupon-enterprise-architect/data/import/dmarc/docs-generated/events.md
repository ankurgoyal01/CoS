---
service: "dmarc"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The DMARC service does not use any asynchronous messaging system (Kafka, RabbitMQ, SQS, mbus, or Pub/Sub). Internal concurrency is coordinated entirely through Go channels between the Gmail Poller, Report Processor, and Log Writer components within a single process. The "output event" of the service is a JSON log line written to the rotating file `/app/logs/dmarc_log.log`, which is then picked up by the Filebeat sidecar and transported to ELK — this is a log-shipping pattern, not a message-bus pattern.

## Published Events

> This service does not publish or consume async events. Output is produced as structured JSON log records shipped via Filebeat to ELK.

## Consumed Events

> This service does not publish or consume async events.

## Dead Letter Queues

> Not applicable. No message bus is used.
