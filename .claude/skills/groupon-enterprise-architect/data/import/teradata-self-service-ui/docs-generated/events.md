---
service: "teradata-self-service-ui"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The Teradata Self Service UI does not publish or consume any asynchronous messages via an external messaging system (no Kafka, RabbitMQ, SQS, or similar). All interactions are synchronous HTTP request/response cycles between the browser and the backend API.

The application does use an internal Vue.js `EventBus` (`src/events/index.js`) for in-process component-to-component communication within the SPA. These are not network-level events.

## Internal Event Bus

The `EventBus` is a bare Vue instance used for decoupled communication between sibling components. It is not a distributed messaging system.

| Event Name | Emitter | Listener | Purpose |
|------------|---------|----------|---------|
| `success` | Account / request action dialogs | `NotificationDialog` | Show a green success snackbar notification |
| `error` | API Client interceptor, action dialogs, Vue error handler | `NotificationDialog` | Show a red error snackbar notification |
| `gms-restriction` | `Account.vue` (on new account / reactivate click) | `GmsEmployeeDialog` | Show a blocking dialog for GMS employees who cannot create personal accounts |

## Published Events

> This service does not publish async events to any external messaging system.

## Consumed Events

> This service does not consume async events from any external messaging system.

## Dead Letter Queues

> Not applicable. No async messaging infrastructure is used.
