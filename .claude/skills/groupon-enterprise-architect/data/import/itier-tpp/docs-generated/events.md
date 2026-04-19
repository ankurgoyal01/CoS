---
service: "itier-tpp"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found of asynchronous messaging in this service.

I-Tier TPP operates exclusively through synchronous HTTP request/response flows. All interactions with downstream services (Partner Service, API Lazlo, Deal Catalog, Booker, Mindbody, Geo Details) are synchronous REST calls initiated by incoming HTTP requests. The service does not publish to or consume from any message bus, Kafka topic, SQS queue, or event stream.

## Published Events

> Not applicable. This service does not publish async events.

## Consumed Events

> Not applicable. This service does not consume async events.

## Dead Letter Queues

> Not applicable. No async messaging is configured.

> This service does not publish or consume async events. All data flows are synchronous REST over HTTP.
