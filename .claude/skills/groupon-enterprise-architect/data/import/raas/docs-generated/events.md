---
service: "raas"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

> This service does not publish or consume async events. RaaS operates on a scheduled synchronization model: background daemons poll external APIs (Redislabs, AWS ElastiCache) on a schedule, write results to filesystem cache and MySQL/PostgreSQL stores, and expose the synchronized data via REST API. There is no event bus, message queue, or pub/sub integration in the architecture model.

## Published Events

> Not applicable

## Consumed Events

> Not applicable

## Dead Letter Queues

> Not applicable
