---
service: "cs-api"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. CS API is a fully synchronous request/response service. All interactions — both inbound from the Cyclops agent UI and outbound to downstream Continuum services and external platforms — are performed via synchronous REST over HTTPS. There is no evidence of Kafka, RabbitMQ, SQS, or any other message bus integration in the architecture model or the inventory summary.

## Published Events

> Not applicable. CS API does not publish any asynchronous events.

## Consumed Events

> Not applicable. CS API does not consume any asynchronous events.

## Dead Letter Queues

> Not applicable. No messaging infrastructure is used.
