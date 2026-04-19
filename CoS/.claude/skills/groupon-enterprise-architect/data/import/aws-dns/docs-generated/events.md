---
service: "aws-dns"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. AWS DNS is a managed infrastructure service that operates exclusively via the synchronous DNS protocol (UDP/TCP port 53). There is no message bus, Kafka topic, SQS queue, or other async messaging integration. DNS query resolution is entirely request/response, and all operational alerting is delivered through Nagios/Monitord checks and Wavefront alerts rather than event streams.

## Published Events

> No evidence found in codebase. AWS DNS does not publish events to any message bus or queue.

## Consumed Events

> No evidence found in codebase. AWS DNS does not consume events from any message bus or queue.

## Dead Letter Queues

> Not applicable. No async messaging is used by this service.
