---
service: "goods-shipment-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumGoodsShipmentService"
  containers: [continuumGoodsShipmentService, continuumGoodsShipmentDatabase]
---

# Architecture Context

## System Context

The Goods Shipment Service is a backend microservice in the Continuum platform, sitting within the Inventory domain. It acts as the authoritative shipment tracking hub: upstream commerce systems create and update shipment records via the REST API, and the service periodically polls external carrier APIs or receives push updates from Aftership to propagate status changes. It writes status changes to its own MySQL database and fans out notifications to email (Rocketman), mobile push (Event Delivery Service), and downstream consumers via the Groupon message bus.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Goods Shipment Service | `continuumGoodsShipmentService` | Backend | Java, Dropwizard (JTier) | 1.0.x | REST API, scheduled jobs, carrier polling, notification dispatch |
| Goods Shipment MySQL | `continuumGoodsShipmentDatabase` | Database | MySQL | — | Stores shipment records, carrier config, OAuth2 tokens, and notification state |

## Components by Container

### Goods Shipment Service (`continuumGoodsShipmentService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Shipment Resource | REST API for shipment CRUD operations | JAX-RS |
| Carrier Resource | REST API for carrier operations (tracking data, OAuth token) | JAX-RS |
| Shipment Manual Refresh Resource | Admin endpoint to manually trigger shipment refresh | JAX-RS |
| Goods Shipment Service Resource | Service-level health/diagnostic endpoints | JAX-RS |
| Aftership Update Receiver Resource | Webhook endpoint for inbound Aftership status events | JAX-RS |
| Shipment Service | Core shipment business logic — create, update, notify | — |
| Shipment Reject Service | Marks eligible shipments as REJECTED after timeout | — |
| Shipment Record Update Service | Updates shipment records from carrier data | — |
| Shipment Pending Status Updates Service | Processes shipments with pending notification state | — |
| Carrier Refresh Service | Iterates active shipments and polls carrier APIs | — |
| Carrier Router | Dynamically resolves and dispatches to carrier-specific implementations | — |
| Mobile Notification Service | Sends mobile push notifications via Event Delivery Service | — |
| Email Notification Service | Sends transactional shipment emails via Rocketman | — |
| Order Fulfillment Notification Sender Service | Publishes order fulfilment events to the message bus | — |
| Shipment Notification Sender Service | Publishes shipment status events to the message bus | — |
| Auth Service | Refreshes carrier OAuth2 tokens on schedule | — |
| Aftership Create Shipment Service | Registers shipments with Aftership for passive tracking | — |
| Aftership Update Receiver Service | Validates and processes inbound Aftership webhook payloads | — |
| Carrier OAuth Registry | Resolves carrier-specific OAuth adapters (UPS, DHL, FedEx) | — |
| Commerce Interface Client | HTTP client for sending tracking updates to Commerce Interface | OkHttp |
| Rocketman Client | HTTP client for sending transactional emails via Rocketman | OkHttp |
| Event Delivery Service Client | HTTP client for mobile push notifications | OkHttp |
| Token Service Client | HTTP client for fetching mobile push tokens | OkHttp |
| Aftership API Client | HTTP client for Aftership tracking API | Retrofit2 |
| UPS API Client | HTTP client for UPS tracking and OAuth API | Retrofit2 |
| DHL API Client | HTTP client for DHL tracking and OAuth API | Retrofit2 |
| FedEx API Client | HTTP client for FedEx tracking and OAuth API | Retrofit2 |
| USPS API Client | HTTP client for USPS tracking API | Retrofit2 |
| AIT API Client | HTTP client for AIT tracking API | Retrofit2 |
| UPSMI API Client | HTTP client for UPSMI tracking API | Retrofit2 |
| FedEx SmartPost API Client | HTTP client for FedEx SmartPost tracking API | Retrofit2 |
| Shipment DAO | Shipment record persistence | JDBI/MySQL |
| Carrier Config DAO | Carrier configuration persistence | JDBI/MySQL |
| Pending Notifiable Shipment DAO | Pending notification queue persistence | JDBI/MySQL |
| ZIP DAO | ZIP code lookup persistence | JDBI/MySQL |
| OAuth2 DAO | Carrier OAuth2 token persistence | JDBI/MySQL |
| Shipment Refresh Job | Scheduled job — polls carriers for active shipment status | Quartz |
| Aftership Create Shipments Job | Scheduled job — registers unregistered shipments with Aftership | Quartz |
| Untracked Shipment Updater Job | Scheduled job — updates shipments without a carrier event | Quartz |
| Shipment Reject Job | Scheduled job — rejects aged shipments with no Aftership update | Quartz |
| Email Notification Job | Scheduled job — sends pending email notifications | Quartz |
| Shipment Update Mobile Notification Job | Scheduled job — dispatches pending mobile notifications | Quartz |
| Auth Token Refresh Job | Scheduled job — refreshes carrier OAuth2 tokens before expiry | Quartz |
| UPS OAuth Adapter | UPS-specific OAuth2 token acquisition | — |
| DHL OAuth Adapter | DHL-specific OAuth2 token acquisition | — |
| FedEx OAuth Adapter | FedEx-specific OAuth2 token acquisition | — |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGoodsShipmentService` | `continuumGoodsShipmentDatabase` | Stores shipment, carrier, and notification data | JDBC/MySQL |
| `continuumGoodsShipmentService` | `commerceInterfaceService` | Sends tracking status updates (EMEA only) | REST/HTTP |
| `continuumGoodsShipmentService` | `aftershipApi` | Creates trackings and receives webhooks | REST/HTTP |
| `aftershipApi` | `continuumGoodsShipmentService` | Shipment status webhook deliveries | REST/HTTP (inbound) |
| `continuumGoodsShipmentService` | `rocketmanService` | Sends transactional shipment emails | REST/HTTP |
| `continuumGoodsShipmentService` | `eventDeliveryService` | Publishes mobile push notification events | REST/HTTP |
| `continuumGoodsShipmentService` | `tokenService` | Fetches consumer mobile push tokens | REST/HTTP |
| `continuumGoodsShipmentService` | `mbusGoodsShipmentNotificationTopic` | Publishes shipment and order fulfilment notifications | Message Bus |
| `continuumGoodsShipmentService` | `upsApi` | Carrier tracking and OAuth token API | REST/HTTP |
| `continuumGoodsShipmentService` | `dhlApi` | Carrier tracking and OAuth token API | REST/HTTP |
| `continuumGoodsShipmentService` | `fedexApi` | Carrier tracking and OAuth token API | REST/HTTP |
| `continuumGoodsShipmentService` | `uspsApi` | Carrier tracking API | REST/HTTP |
| `continuumGoodsShipmentService` | `aitApi` | Carrier tracking API | REST/HTTP |
| `continuumGoodsShipmentService` | `upsmiApi` | Carrier tracking API | REST/HTTP |
| `continuumGoodsShipmentService` | `fedexspApi` | Carrier tracking API | REST/HTTP |

## Architecture Diagram References

- Component: `components-goodsShipmentService`
- Dynamic (Aftership webhook flow): `goodsShipmentServiceAftershipWebhook`
