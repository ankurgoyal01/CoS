---
service: "b2b-ui"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. The RBAC UI is a request-driven Next.js application. All interactions with downstream services (`continuumRbacService`, `continuumUsersService`) occur synchronously via REST HTTP calls initiated by BFF API routes in response to browser requests. No Kafka, RabbitMQ, SQS, Pub/Sub, or other message-bus integrations are present in the codebase.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> Not applicable — this service does not use async messaging.
