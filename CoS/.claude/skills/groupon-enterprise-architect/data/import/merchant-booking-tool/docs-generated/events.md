---
service: "merchant-booking-tool"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. The Merchant Booking Tool is a synchronous I-tier web application that operates exclusively via request/response cycles over HTTPS. All booking data reads and writes are performed synchronously through the `continuumUniversalMerchantApi`. There is no evidence of Kafka, RabbitMQ, SQS, or any other message bus integration in the architecture DSL or component definitions for this service.

## Published Events

> No evidence found in codebase. This service does not publish async events.

## Consumed Events

> No evidence found in codebase. This service does not consume async events.

## Dead Letter Queues

> Not applicable. This service does not use async messaging.
