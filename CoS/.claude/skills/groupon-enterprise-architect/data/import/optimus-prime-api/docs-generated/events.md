---
service: "optimus-prime-api"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. All inter-service interactions are synchronous: REST calls to NiFi, LDAP queries, SMTP delivery, and cloud storage SDK calls. Internal scheduling is handled by Quartz Scheduler (in-process), not an external message bus.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> Not applicable. This service does not use async messaging and has no dead letter queues.
