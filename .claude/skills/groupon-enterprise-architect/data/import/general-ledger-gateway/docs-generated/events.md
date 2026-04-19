---
service: "general-ledger-gateway"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. All communication is synchronous over HTTPS — inbound from Accounting Service via REST calls, and outbound to NetSuite ERP via OAuth 1.0 RESTlet calls. Asynchronous job execution is managed internally by Quartz Scheduler (with job state stored in PostgreSQL), not through an external message broker.

> **Note**: The README references an open discussion (FED-10260) about potentially using `messagebus` or Apache Kafka for job enqueueing. As of the current codebase state, no message broker integration has been implemented.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.
