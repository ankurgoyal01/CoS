---
service: "ugc-moderation"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

UGC Moderation does not publish or consume asynchronous events. It is a synchronous request/response web application. All interactions with downstream services (`continuumUgcService`, `m3_merchant_service`, Groupon V2 API) are made via synchronous HTTPS calls initiated by browser actions. No Kafka, RabbitMQ, SQS, or other message bus integration was found in the source code or configuration.

## Published Events

> No evidence found in codebase. This service does not publish async events.

## Consumed Events

> No evidence found in codebase. This service does not consume async events.

## Dead Letter Queues

> Not applicable. No async messaging is used.
