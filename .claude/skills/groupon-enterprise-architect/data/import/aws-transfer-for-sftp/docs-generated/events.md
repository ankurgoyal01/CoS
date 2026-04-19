---
service: "aws-transfer-for-sftp"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

AWS Transfer for SFTP does not publish or consume asynchronous events through a message broker (Kafka, SQS, SNS, MBus, or similar). File transfer activity is a synchronous SFTP operation. Observability is achieved through CloudWatch Logs (session, authentication, and transfer events written to `/aws/transfer/<server-id>`) and S3 server access logs forwarded to the centralised logging bucket `groupon-transfer-s3-bucket-log`. No event-driven integrations are configured in this repository.

## Published Events

> No evidence found in codebase. This service does not publish async events to any message broker.

## Consumed Events

> No evidence found in codebase. This service does not consume async events from any message broker.

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration exists; the service does not use async messaging.
