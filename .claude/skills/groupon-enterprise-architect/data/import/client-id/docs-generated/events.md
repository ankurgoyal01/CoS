---
service: "client-id"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Client ID Service does not use asynchronous messaging. All data exchange with consumers (API Proxy, API Lazlo) is performed via synchronous HTTP polling. Consumers call the service's REST endpoints on a periodic basis to pull updated client and token data. The only background processing is the internal scheduled-change task, which runs on a time-based executor within the service process itself and writes directly to MySQL.

## Published Events

> No evidence found in codebase. Client ID Service does not publish to any message bus, Kafka topic, or queue.

## Consumed Events

> No evidence found in codebase. Client ID Service does not subscribe to any message bus, Kafka topic, or queue.

## Dead Letter Queues

> Not applicable. No async messaging is used.
