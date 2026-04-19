---
service: "metro-ui"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. Metro UI is a stateless frontend service — all state transitions (deal creation, publication, updates) are delegated synchronously to downstream Continuum backend services via HTTPS/JSON calls. There is no direct event bus integration in the service inventory.

## Published Events

> Not applicable — Metro UI does not publish to any message bus or event topic.

## Consumed Events

> Not applicable — Metro UI does not consume from any message bus or event topic.

## Dead Letter Queues

> Not applicable — no async messaging is used by this service.
