---
service: "killbill-subscription-programs-plugin"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumSubscriptionProgramsPlugin", "continuumSubscriptionProgramsPluginDb"]
---

# Architecture Context

## System Context

The Kill Bill Subscription Programs Plugin (`continuumSubscriptionProgramsPlugin`) runs as an OSGi bundle inside the Kill Bill billing platform within the Continuum system. It sits between the Kill Bill event infrastructure and Groupon's commerce systems: it receives billing lifecycle events in-process from Kill Bill and translates them into subscription order calls against the Lazlo GAPI. It also bridges the Groupon MBus message stream, consuming transactional ledger events from the Orders system to synchronize invoice payment state. It is not a standalone service — it is embedded in the Kill Bill Tomcat container and accessed by external callers via HTTP at the `/plugins/sp-plugin/` path prefix.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Kill Bill Subscription Programs Plugin | `continuumSubscriptionProgramsPlugin` | Service (OSGi bundle) | Java 8, OSGi, Jooby | 0.4.x | OSGi plugin that reacts to Kill Bill invoice events and MBus ledger events to create and refresh subscription program orders |
| SP Plugin Persistence | `continuumSubscriptionProgramsPluginDb` | Database | MySQL | 5.6/5.7 | Plugin-specific MySQL tables for auth tokens (`sp_token`) and retry notifications (`sp_notifications`, `sp_notifications_history`) |

## Components by Container

### Kill Bill Subscription Programs Plugin (`continuumSubscriptionProgramsPlugin`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`spApiResources`) | HTTP endpoints for health, token operations, createOrder, and refreshOrder flows | Jooby Resources |
| Kill Bill Event Handler (`spKillBillEventHandler`) | Processes `INVOICE_CREATION` events and drives order creation/mapping logic | SPListener |
| MBus Listener (`spMbusListener`) | Consumes `TransactionalLedgerEvent` messages and identifies relevant invoices | MBusListener |
| Retry Processor (`spRetryProcessor`) | Schedules and executes retry jobs to reconcile payment updates with invoices | MBusRetries + MessageProcessor |
| Token Manager (`spTokenManager`) | Generates and validates short-lived authorization tokens for order creation calls | TokenManager |
| Orders Gateway (`spOrdersGateway`) | HTTP client for Orders read APIs | OrdersClient (Retrofit2) |
| GAPI Gateway (`spGapiGateway`) | HTTP client for Lazlo `multi_item_orders` API | GAPIClient (Async HTTP) |
| Token Repository (`spTokenRepository`) | Persistence layer for plugin tokens and retry-notification metadata | TokenDao / JDBI / jOOQ |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSubscriptionProgramsPlugin` | `continuumSubscriptionProgramsPluginDb` | Stores tokens and retry queue records | JDBC/MySQL |
| `continuumSubscriptionProgramsPlugin` | `continuumApiLazloService` | Creates subscription orders via `multi_item_orders` API | HTTPS/JSON |
| `continuumSubscriptionProgramsPlugin` | `continuumOrdersService` | Reads order/payment status to reconcile invoices | HTTPS/JSON |
| `continuumSubscriptionProgramsPlugin` | `messageBus` | Consumes `TransactionalLedgerEvents` messages | JMS/STOMP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuum-subscription-programs-plugin`
- Dynamic flow: `dynamic-sp-plugin-order-processing`
