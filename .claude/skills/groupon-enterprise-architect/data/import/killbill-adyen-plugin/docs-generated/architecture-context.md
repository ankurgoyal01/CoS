---
service: "killbill-adyen-plugin"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumKillbillAdyenPlugin", "continuumKillbillAdyenPluginDb"]
---

# Architecture Context

## System Context

The Kill Bill Adyen Plugin operates as an OSGi bundle inside the `continuumSystem` (Continuum Platform). It sits between the Kill Bill billing platform and the Adyen external payment gateway. Kill Bill invokes the plugin's `PaymentPluginApi` when it needs to execute payment operations; the plugin translates those calls into Adyen SOAP or REST requests, persists results, and returns enriched transaction info back to Kill Bill. Adyen sends asynchronous SOAP notifications to the plugin's notification endpoint; the plugin parses and reconciles these against existing Kill Bill payment records to update transaction states.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Kill Bill Adyen Plugin | `continuumKillbillAdyenPlugin` | OSGi Bundle | Java 8, OSGi | 0.5.x | OSGi payment plugin integrating Kill Bill with Adyen APIs and webhook processing |
| Kill Bill Adyen Plugin DB | `continuumKillbillAdyenPluginDb` | Database | MySQL/PostgreSQL | - | Plugin persistence for payment methods, Adyen responses, HPP requests, and notifications |

## Components by Container

### Kill Bill Adyen Plugin (`continuumKillbillAdyenPlugin`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Payment API Adapter | Implements Kill Bill `PaymentPluginApi`; orchestrates authorize, capture, refund, void, and recurring operations | `AdyenPaymentPluginApi` |
| Adyen Gateway Client | Sends payment, recurring, and checkout requests to Adyen SOAP and REST services | `AdyenPaymentRequestSender`, `AdyenRecurringClient`, `AdyenCheckoutApiClient` |
| Notification Processor | Parses Adyen SOAP notifications and reconciles transaction states with Kill Bill | `AdyenNotificationService`, `KillbillAdyenNotificationHandler` |
| Persistence Adapter | Reads and writes plugin payment methods, responses, HPP requests, and notifications | `AdyenDao` (JDBI + jOOQ) |
| Delayed Action Scheduler | Schedules and executes delayed 3DSv2 follow-up actions using Kill Bill's notification queue | `DelayedActionScheduler` |
| Healthcheck Component | Validates Adyen endpoint reachability via HTTP probe; exposed to Kill Bill healthcheck framework | `AdyenHealthcheck` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumKillbillAdyenPlugin` | `continuumKillbillAdyenPluginDb` | Stores plugin payment methods, responses, notifications, and HPP requests | JDBC (MySQL/PostgreSQL) |
| `continuumKillbillAdyenPlugin` | `adyen` | Calls Payment, Recurring, Checkout, and HPP APIs | SOAP / HTTPS REST |
| `adyen` | `continuumKillbillAdyenPlugin` | Sends asynchronous payment notifications | SOAP over HTTPS |
| Kill Bill Platform | `continuumKillbillAdyenPlugin` | Invokes payment plugin APIs and servlet endpoints | OSGi service / HTTP servlet |
| `continuumKillbillAdyenPlugin` | Kill Bill Platform | Updates transaction and payment states through Kill Bill APIs | OSGi service |

## Architecture Diagram References

- Component view: `components-continuumKillbillAdyenPlugin`
- Dynamic view: `dynamic-authorize-and-notification-flow`
