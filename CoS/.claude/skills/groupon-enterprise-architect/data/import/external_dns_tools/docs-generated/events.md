---
service: "external_dns_tools"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message bus, queue, or streaming platform (no Kafka, RabbitMQ, SQS, or equivalent). The closest equivalent to event-driven behavior is the DNS NOTIFY mechanism inherent to BIND: when a zone is updated (SOA serial incremented), BIND may send a DNS NOTIFY message to configured secondaries, prompting Akamai Zone Transfer Agents to initiate a fresh zone transfer. However, this is part of the DNS protocol itself, not an application-level messaging system.

## Published Events

> No evidence found in codebase. This service does not publish application-level async events.

## Consumed Events

> No evidence found in codebase. This service does not consume application-level async events.

## Dead Letter Queues

> No evidence found in codebase. No async messaging infrastructure is used.
