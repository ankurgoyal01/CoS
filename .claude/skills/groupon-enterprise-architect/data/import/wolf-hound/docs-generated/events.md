---
service: "wolf-hound"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

Wolfhound Editor UI does not publish or consume async events. All communication between this service and its upstream dependencies is synchronous HTTP request/response. The service is a BFF layer; editorial state changes (e.g., publish actions) are delivered synchronously to `continuumWolfhoundApi` rather than via a message bus.

## Published Events

> Not applicable

This service does not publish any async events.

## Consumed Events

> Not applicable

This service does not consume any async events.

## Dead Letter Queues

> Not applicable

No message queues or dead letter queues are configured for this service.
