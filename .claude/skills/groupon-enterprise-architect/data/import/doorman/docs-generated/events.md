---
service: "doorman"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Doorman does not use asynchronous messaging. The service is entirely synchronous and request-driven: all interactions are browser-initiated HTTP flows involving Okta SAML callbacks, Users Service REST calls, and HTML form POSTs to destination tools. No Kafka, RabbitMQ, SQS, Pub/Sub, or any other message bus integration is present in the codebase.

## Published Events

> No evidence found in codebase. This service does not publish or consume async events.

## Consumed Events

> No evidence found in codebase. This service does not publish or consume async events.

## Dead Letter Queues

> No evidence found in codebase. No async messaging is used.
