---
service: "HotzoneGenerator"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

HotzoneGenerator does not use any asynchronous messaging system. It is a cron-triggered batch job that communicates exclusively via synchronous HTTPS/JSON calls to internal Continuum services and the Proximity Notifications API. There are no Kafka topics, RabbitMQ queues, SQS queues, or any other message bus integrations.

## Published Events

> No evidence found in codebase. This service does not publish any async events.

## Consumed Events

> No evidence found in codebase. This service does not consume any async events.

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events.
