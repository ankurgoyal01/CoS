---
service: "itier-merchant-inbound-acquisition"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message bus (no Kafka, RabbitMQ, SQS, or Pub/Sub integration is present in the codebase). All inter-service communication is synchronous HTTP. Analytics events are emitted directly to Google Analytics via the `universal-analytics` library on the server side and via Google Tag Manager on the client side — these are fire-and-forget tracking calls, not durable messages.

## Published Events

> No evidence found in codebase. The service does not publish to any message bus topic.

## Analytics Tracking Calls (Non-Durable)

The following Google Analytics events are fired server-side using `universal-analytics` on lead submission outcomes. These are not durable async messages.

| GA Event Category | GA Event Action | Trigger |
|-------------------|----------------|---------|
| `web2lead-submit-draft` | `success` / `err` | After Metro draft merchant creation response |
| `web2lead-submit-salesforce` | `success` / `error` | After Salesforce lead creation response |
| `web2dedupe-submit-draft` | `success` / `error` | After Metro validateField (dedupe) response |

GA codes are country-specific and resolved at runtime via the `ga-helper` module. GTM tags are similarly country-specific and injected into page HTML at render time.

## Consumed Events

> No evidence found in codebase. The service does not consume from any message bus topic.

## Dead Letter Queues

> No evidence found in codebase.
