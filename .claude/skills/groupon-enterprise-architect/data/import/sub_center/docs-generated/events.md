---
service: "sub_center"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

sub_center does not use asynchronous messaging as part of its primary flows. It is a synchronous, request/response I-Tier web application. Subscription state changes are made via direct HTTP calls to downstream services (Groupon V2 API, Subscriptions Service). Tracking events are sent synchronously to the Optimize Service. SMS notifications are dispatched synchronously via the Twilio SDK through the SMS Helper component.

## Published Events

> No evidence found in codebase. sub_center does not publish events to any message broker or queue.

## Consumed Events

> No evidence found in codebase. sub_center does not consume events from any message broker or queue.

## Dead Letter Queues

> Not applicable. This service does not use async messaging and has no dead letter queues.
