---
service: "getaways-accounting-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. All data flows are synchronous: reservation data is read directly from the TIS PostgreSQL database via JDBI, hotel metadata is fetched synchronously from the Content Service via Retrofit HTTP, and generated CSV files are delivered synchronously to the SFTP accounting server via JSch.

> No evidence found of any Kafka, RabbitMQ, SQS, Pub/Sub, or internal message bus integration in the codebase.

## Published Events

> Not applicable. This service does not publish to any message bus or event stream.

## Consumed Events

> Not applicable. This service does not consume from any message bus or event stream.

## Dead Letter Queues

> Not applicable. No async messaging is used.
