---
service: "merchant-preview"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

Merchant Preview does not publish or consume async events via a message broker. All async communication is handled through scheduled cron jobs (`continuumMerchantPreviewCronWorker`) that poll and update Salesforce directly, and through SMTP email delivery via `smtpRelay`. There is no evidence of Kafka, RabbitMQ, SQS, or any other message bus integration in the architecture model.

## Published Events

> No evidence found in codebase. This service does not publish async events to a message broker.

## Consumed Events

> No evidence found in codebase. This service does not consume async events from a message broker.

## Dead Letter Queues

> Not applicable. No message broker integration is present.
