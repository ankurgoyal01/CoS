---
service: "corpAD"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message broker. corpAD is an infrastructure directory service. Identity synchronization from Workday is performed via a scheduled import/pull mechanism rather than event-driven messaging. Consuming services interact with corpAD synchronously via LDAP/LDAPS.

## Published Events

> No evidence found in codebase. corpAD does not publish events to any message broker or event bus.

## Consumed Events

> No evidence found in codebase. corpAD does not consume events from any message broker or event bus.

## Dead Letter Queues

> Not applicable. No async messaging is used by this service.
