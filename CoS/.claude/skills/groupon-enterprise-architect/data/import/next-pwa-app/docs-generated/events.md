---
service: "next-pwa-app"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

This service does not publish or consume async events via message brokers (Kafka, RabbitMQ, SQS, etc.). next-pwa-app is a frontend application that communicates exclusively via synchronous HTTP/GraphQL with backend services. Any event-driven behavior in the broader Groupon ecosystem is handled by the downstream Continuum and Encore backend services.

Client-side analytics events (BloodHound tracking, Sentry events, OpenTelemetry spans) are emitted from the browser and server runtimes but are delivered via HTTP to their respective collection endpoints, not via a message bus.
