---
service: "image-service-config"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. The Image Service operates as a synchronous request/response system: clients send HTTP GET requests to the Nginx cache proxy, which either serves from disk cache or synchronously forwards to the Python app backend and AWS S3. No message-bus, Kafka, RabbitMQ, SQS, or similar messaging infrastructure is referenced in any configuration file in this repository.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> Not applicable — this service does not use asynchronous messaging.
