---
service: "api-lazlo-sox"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

API Lazlo and API Lazlo SOX are synchronous request/response gateways. They do not publish or consume async events via message brokers (Kafka, RabbitMQ, etc.).

Internal component communication within each service uses the Lazlo EventBus (Vert.x EventBus) for in-process message passing between controllers and BLS modules via promises. This is an in-process mechanism, not an external messaging system.

## Internal EventBus Communication

The Lazlo EventBus is used for decoupled in-process communication between API controller components and BLS (Business Logic Service) modules:

| From | To | Pattern | Purpose |
|------|----|---------|---------|
| `continuumApiLazloService_usersApi` | `continuumApiLazloService_usersBlsModule` | EventBus / Promises | Delegate user/account flows (lookups, registration, OTP, email verification) |
| `continuumApiLazloService_dealsAndListingsApi` | `continuumApiLazloService_dealsBlsModule` | EventBus / Promises | Delegate deal and listing flows (buy-it-again, recommendations, merchandising) |
| `continuumApiLazloService_ordersAndCartApi` | `continuumApiLazloService_ordersBlsModule` | EventBus / Promises | Delegate order/cart/reservation logic |
| `continuumApiLazloService_geoAndTaxonomyApi` | `continuumApiLazloService_dealsBlsModule` | EventBus / Promises | Geo- and taxonomy-aware deal presentation |
| `continuumApiLazloService_ugcAndSocialApi` | `continuumApiLazloService_dealsBlsModule` | EventBus / Promises | Enrich social/UGC responses with deal context |
| `continuumApiLazloSoxService_usersApi` | `continuumApiLazloSoxService_sharedBlsModules` | EventBus / Promises | SOX user/account flows |
| `continuumApiLazloSoxService_partnersApi` | `continuumApiLazloSoxService_sharedBlsModules` | EventBus / Promises | SOX partner booking and inventory journeys |

> This service does not publish or consume external async events. All inter-service communication is synchronous HTTP/JSON via the downstream service clients.
