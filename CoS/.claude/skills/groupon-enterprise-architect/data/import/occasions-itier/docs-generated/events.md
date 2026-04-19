---
service: "occasions-itier"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

occasions-itier does not use asynchronous messaging. Integration with the Campaign Service (ArrowHead) is performed via scheduled HTTP polling at a fixed 1800-second interval rather than event subscription. All other upstream integrations (Groupon V2 API, RAPI, Alligator, GeoDetails, Birdcage) are synchronous REST calls triggered by incoming HTTP requests.

## Published Events

> No evidence found in codebase. This service does not publish async events.

## Consumed Events

> No evidence found in codebase. This service does not consume async events.

## Dead Letter Queues

> Not applicable. This service does not publish or consume async events.
