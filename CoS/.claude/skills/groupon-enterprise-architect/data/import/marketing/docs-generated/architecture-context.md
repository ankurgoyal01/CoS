---
service: "marketing"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMarketingPlatform", "continuumMarketingPlatformDb"]
---

# Architecture Context

## System Context

The Marketing & Delivery Platform sits within the **Continuum Platform** (`continuumSystem`), Groupon's core commerce engine. It occupies the campaign management and notification delivery domain, positioned downstream of the Orders Service (which triggers confirmation notifications) and alongside the Marketing Deal Service (which serves deal data and publishes updates consumed by marketing systems). Administrators interact directly with the platform to create and manage marketing campaigns. The platform publishes campaign events, subscription changes, and delivery logs to the shared Message Bus for consumption by analytics and downstream systems.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Marketing & Delivery Platform | `continuumMarketingPlatform` | Application | Java / Ruby on Rails | Microservice suite (mostly Java/Ruby on Rails) for campaign management and delivery (Mailman, Rocketman). Owns its data stores. |
| Marketing Platform Database | `continuumMarketingPlatformDb` | Database | MySQL (DaaS) | Primary relational data store for campaign, subscription, and inbox data. |

## Components by Container

### Marketing & Delivery Platform (`continuumMarketingPlatform`)

| Component | ID | Responsibility | Technology |
|-----------|----|---------------|-----------|
| Inbox Management | `marketingPlatform_inboxManagement` | User messaging inbox -- manages consumer inbox state, message delivery status, and read/unread tracking. | Java |
| Campaign Management | `marketingPlatform_campaignManagement` | Campaign orchestration -- handles campaign creation, scheduling, targeting, and lifecycle transitions. | Java |
| Subscriptions | `marketingPlatform_subscriptions` | Topic/user subscriptions -- manages consumer opt-in/opt-out preferences and subscription routing rules. | Java |
| Kafka Logging | `marketingPlatform_kafkaLogging` | Event logging -- publishes campaign delivery metrics, inbox events, and subscription changes to Kafka topics. | Java |

## Key Relationships

### Container-Level

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `administrator` | `continuumMarketingPlatform` | Creates and manages marketing campaigns system | HTTPS |
| `continuumOrdersService` | `continuumMarketingPlatform` | Triggers marketing notifications | JSON/HTTPS |
| `continuumMarketingDealService` | `continuumMarketingPlatform` | Serves deal data and publishes updates consumed by marketing systems | HTTP + Events |
| `continuumMarketingPlatform` | `messageBus` | Pub/Sub for order/campaign events/logs | Async |
| `continuumMarketingPlatform` | `continuumMarketingPlatformDb` | Persistence of campaign, subscription, and inbox data | JDBC (inferred) |

### Component-Level (inferred from dynamic view)

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `marketingPlatform_campaignManagement` | `messageBus` | Publish campaign events | Async |
| `marketingPlatform_subscriptions` | `messageBus` | Routing rules / subscription events | Async |
| `marketingPlatform_kafkaLogging` | `messageBus` | Log delivery events | Async |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Container (focused): `containers-continuum-platform-marketing-ads`
- Dynamic (campaign notification): `dynamic-continuum-marketing`
- Dynamic (orders checkout - triggers notification): `dynamic-continuum-orders-service`
- Dynamic (consumer purchase E2E): `dynamic-continuum-consumer-purchase-e2e`
- Dynamic (data pipeline): `dynamic-continuum-data-pipeline`
