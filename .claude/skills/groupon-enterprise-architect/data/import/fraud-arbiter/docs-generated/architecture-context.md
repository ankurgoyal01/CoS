---
service: "fraud-arbiter"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumFraudArbiterService, continuumFraudArbiterMysql, continuumFraudArbiterConfigRedis, continuumFraudArbiterCacheRedis, continuumFraudArbiterQueueRedis]
---

# Architecture Context

## System Context

Fraud Arbiter sits within the Continuum platform as the central fraud-decision broker. It is invoked as part of the order placement pipeline, bridging Groupon's internal order and commerce services with external fraud intelligence providers (Signifyd and Riskified). It interacts with a large set of Continuum services to gather order context data and communicates fraud outcomes back through both synchronous API responses and asynchronous message-bus events.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Fraud Arbiter API & Jobs | `continuumFraudArbiterService` | Service | Ruby on Rails + Sidekiq | — | Primary Rails application hosting the API and Sidekiq background job workers |
| Fraud Arbiter MySQL | `continuumFraudArbiterMysql` | Database | MySQL | — | Persistent store for fraud decisions, events, and audit records |
| Config Redis | `continuumFraudArbiterConfigRedis` | Cache | Redis | — | Stores runtime configuration values used by the service |
| App Cache Redis | `continuumFraudArbiterCacheRedis` | Cache | Redis | — | Application-level cache for frequently accessed data |
| Job Queue Redis | `continuumFraudArbiterQueueRedis` | Queue | Redis | — | Sidekiq job queue backing store for async fraud task processing |

## Components by Container

### Fraud Arbiter API & Jobs (`continuumFraudArbiterService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Webhook Receiver | Accepts inbound fraud-decision webhooks from Signifyd and Riskified, validates signatures, and enqueues processing jobs | Rails controllers |
| Fraud Review API | Exposes internal endpoints for querying order fraud review status | Rails controllers |
| Fraud Decision Processor | Evaluates received decisions, updates MySQL records, and publishes downstream events | Rails services + ActiveRecord |
| Sidekiq Workers | Process async fraud tasks: decision handling, fulfillment updates, provider notifications | Sidekiq |
| Faraday HTTP Client | Makes outbound HTTP calls to fraud providers and internal Continuum services | Faraday |
| Message Bus Publisher | Publishes fraud decision events to the message bus for downstream consumers | mbus client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumFraudArbiterService` | `continuumFraudArbiterMysql` | Reads and writes fraud decisions, events, audit records | ActiveRecord / SQL |
| `continuumFraudArbiterService` | `continuumFraudArbiterQueueRedis` | Enqueues and dequeues Sidekiq background jobs | Redis protocol |
| `continuumFraudArbiterService` | `continuumFraudArbiterConfigRedis` | Reads runtime configuration values | Redis protocol |
| `continuumFraudArbiterService` | `continuumFraudArbiterCacheRedis` | Reads and writes application cache entries | Redis protocol |
| `continuumFraudArbiterService` | `continuumOrdersService` | Fetches order details; notifies of fraud outcomes | REST / HTTP |
| `continuumFraudArbiterService` | `continuumDealCatalogService` | Fetches deal/product context for fraud evaluation | REST / HTTP |
| `continuumFraudArbiterService` | `continuumGoodsInventoryService` | Fetches goods inventory context | REST / HTTP |
| `continuumFraudArbiterService` | `continuumIncentiveService` | Fetches incentive/promo context for fraud signals | REST / HTTP |
| `continuumFraudArbiterService` | `continuumM3PlacesService` | Fetches merchant place context | REST / HTTP |
| `continuumFraudArbiterService` | `continuumM3MerchantService` | Fetches merchant account context | REST / HTTP |
| `continuumFraudArbiterService` | `continuumUsersService` | Fetches customer/user profile data | REST / HTTP |
| `continuumFraudArbiterService` | `continuumVoucherInventoryService` | Fetches voucher inventory context | REST / HTTP |
| `signifyd` | `continuumFraudArbiterService` | Delivers fraud decision webhooks | REST / HTTPS webhook |
| `riskified` | `continuumFraudArbiterService` | Delivers fraud decision webhooks | REST / HTTPS webhook |

## Architecture Diagram References

- System context: `contexts-fraud-arbiter`
- Container: `containers-fraud-arbiter`
- Component: `components-continuumFraudArbiterService`
