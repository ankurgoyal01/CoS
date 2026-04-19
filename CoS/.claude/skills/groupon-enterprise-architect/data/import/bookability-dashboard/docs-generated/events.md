---
service: "bookability-dashboard"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The Bookability Dashboard is a browser-only single-page application that communicates exclusively via synchronous HTTP REST calls to `continuumPartnerService`. It does not publish or consume any asynchronous events, message queues, or streaming topics directly.

The broader bookability ecosystem (TPP, Partner Service, EPODS, Ingestion Service) uses a Message Bus for event streaming, as described in the system README. However, the dashboard interacts with those events only indirectly — by reading health-check logs and status data stored by Partner Service after it has processed those events.

## Published Events

> Not applicable — this service does not publish async events.

## Consumed Events

> Not applicable — this service does not consume async events directly. It reads health-check log data from `continuumPartnerService` via REST polling (`/v1/groupon/simulator/logs`).

## Dead Letter Queues

> Not applicable — no message queue integration exists in this service.
