---
service: "gims"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase for async messaging patterns used by GIMS. Based on the architecture DSL, all known interactions with GIMS are synchronous HTTP/REST calls. The service may publish or consume events via the Continuum message bus, but this is not documented in the federated architecture model.

## Published Events

> No evidence found in codebase. If GIMS publishes image lifecycle events (e.g., image uploaded, image processed, image deleted), they should be documented by the service owner.

## Consumed Events

> No evidence found in codebase. If GIMS consumes events (e.g., image processing requests, cache invalidation signals), they should be documented by the service owner.

## Dead Letter Queues

> No evidence found in codebase.
