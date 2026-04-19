---
service: "booster"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Booster is an external SaaS accessed synchronously over HTTPS. The integration between Groupon's `continuumBoosterService` and the Booster API follows a synchronous request/response pattern. No asynchronous messaging, event topics, or message queues are associated with the Booster integration based on the available architecture model.

## Published Events

> No evidence found in codebase. This service does not publish async events. Booster is called synchronously via HTTPS on the critical consumer request path.

## Consumed Events

> No evidence found in codebase. This service does not consume async events. Requests to Booster originate from synchronous consumer request flows routed through `continuumRelevanceApi`.

## Dead Letter Queues

> No evidence found in codebase. No dead letter queues are applicable to this integration.
