---
service: "itier-mobile"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

`itier-mobile` does not use an asynchronous messaging system (Kafka, RabbitMQ, SQS, or similar). All interactions are synchronous HTTP request/response cycles. The one outbound side-effect that resembles async delivery — SMS sending — is performed synchronously via the Twilio REST SDK during the `POST /mobile/send_sms_message` request lifecycle. No event topics, queues, or dead-letter queues were found in the codebase.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.

> This service does not publish or consume async events. All outbound integrations (Twilio SMS, layout-service) are synchronous HTTP calls made within the request lifecycle.
