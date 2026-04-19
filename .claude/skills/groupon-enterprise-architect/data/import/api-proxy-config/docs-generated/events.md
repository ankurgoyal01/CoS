---
service: "api-proxy-config"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

`api-proxy-config` does not publish or consume any asynchronous events. It is a configuration repository operated via CLI tooling and Git-based workflows. Configuration changes are applied by mutating JSON files in the repository, committing, and deploying via DeployBot. There is no event bus, message queue, Kafka topic, or pub/sub integration in this service.

> This service does not publish or consume async events.

## Published Events

> No evidence found. This service publishes no events to any messaging system.

## Consumed Events

> No evidence found. This service consumes no events from any messaging system.

## Dead Letter Queues

> Not applicable. No messaging systems are used by this service.
