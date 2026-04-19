---
service: "etorch"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

eTorch is a synchronous REST service. It does not publish or consume asynchronous events via any message bus, queue, or streaming platform. All integrations with downstream services are performed via synchronous HTTP calls. Background work executed by `continuumEtorchWorker` is triggered by an internal Quartz scheduler rather than by external events.

## Published Events

> Not applicable

This service does not publish any async events.

## Consumed Events

> Not applicable

This service does not consume any async events.

## Dead Letter Queues

> Not applicable

This service does not use any message queues.
