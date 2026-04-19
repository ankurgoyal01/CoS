---
service: "seo-deal-api"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

No asynchronous event publishing or consumption was identified in the available architecture DSL or cross-referenced source files for seo-deal-api. The service operates as a synchronous REST API: all deal attribute updates, redirect registrations, URL removal workflows, and IndexNow submissions are triggered by direct HTTP calls from consumers, not by event/message bus patterns.

## Published Events

> No evidence found in codebase.

This service does not publish async events. All state changes (deal attribute writes, redirect updates, URL removal status changes) are made synchronously in response to HTTP requests and are persisted directly to `continuumSeoDealPostgres`.

## Consumed Events

> No evidence found in codebase.

This service does not consume async events. Triggers from external workflows (e.g., the `seo-deal-redirect` Airflow DAG) are delivered via direct HTTP PUT calls to the REST API, not through a message bus.

## Dead Letter Queues

> No evidence found in codebase.

This service does not use dead letter queues. No messaging system integration was found in the architecture model or referenced source code.
