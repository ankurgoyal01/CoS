---
service: "voucher-archive-backend"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumVoucherArchiveBackendApp, continuumVoucherArchiveDealsDb, continuumVoucherArchiveUsersDb, continuumVoucherArchiveOrdersDb, continuumVoucherArchiveTravelDb, continuumVoucherArchiveRedis]
---

# Architecture Context

## System Context

The voucher-archive-backend sits within the **Continuum** platform as a self-contained archive service for legacy LivingSocial data. It is called directly by consumer clients, merchant portals, and CSR tools over REST. It authenticates callers by delegating token validation to the Users Service, CS Token Service, and MX Merchant API. It reads and writes four dedicated MySQL databases (deals, users, orders, travel) and uses Redis for background job queuing via Resque. GDPR erasure events flow through the Message Bus, connecting this service to the broader Continuum compliance pipeline via the Retcon Service.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Voucher Archive API | `continuumVoucherArchiveBackendApp` | Application | Ruby on Rails / Puma | 4.2 / 2.2.3 | REST API serving consumers, merchants, and CSRs; hosts background workers |
| Deals Database | `continuumVoucherArchiveDealsDb` | Database | MySQL | 5.6 | Stores legacy LivingSocial deal and option data |
| Users Database | `continuumVoucherArchiveUsersDb` | Database | MySQL | 5.6 | Stores legacy LivingSocial user and account data |
| Orders Database | `continuumVoucherArchiveOrdersDb` | Database | MySQL | 5.6 | Stores legacy LivingSocial order, coupon, and voucher records |
| Travel Database | `continuumVoucherArchiveTravelDb` | Database | MySQL | 5.6 | Stores legacy LivingSocial travel-specific voucher data |
| Redis Cache | `continuumVoucherArchiveRedis` | Cache | Redis | — | Resque job queue and action event store |

## Components by Container

### Voucher Archive API (`continuumVoucherArchiveBackendApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `voucherArchiveBackend_apiControllers` | Routes and handles all HTTP requests across consumer, merchant, CSR, deal, and checkout namespaces | Rails controllers |
| `authClients` | Validates bearer tokens by calling Users Service, CS Token Service, or MX Merchant API | rest-client |
| `voucherServices` | Orchestrates voucher retrieval, state transitions (AASM), PDF and QR code generation | Ruby / aasm / pdfkit / rqrcode |
| `refundServices` | Creates refund records and updates coupon state for CSR operations | Ruby / aasm |
| `voucherRepositories` | Data access layer across all four MySQL databases | rom 3.0 / mysql2 |
| `messageBusWorker` | Consumes GDPR erasure events and publishes completion events; runs Resque jobs | messagebus / Resque |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumVoucherArchiveBackendApp` | `continuumVoucherArchiveDealsDb` | Reads deal and option records | MySQL |
| `continuumVoucherArchiveBackendApp` | `continuumVoucherArchiveUsersDb` | Reads user and account records | MySQL |
| `continuumVoucherArchiveBackendApp` | `continuumVoucherArchiveOrdersDb` | Reads and writes order, coupon, and voucher records | MySQL |
| `continuumVoucherArchiveBackendApp` | `continuumVoucherArchiveTravelDb` | Reads travel voucher records | MySQL |
| `continuumVoucherArchiveBackendApp` | `continuumVoucherArchiveRedis` | Enqueues and dequeues Resque jobs; stores action events | Redis |
| `continuumVoucherArchiveBackendApp` | `continuumUsersService` | Validates consumer bearer tokens | REST |
| `continuumVoucherArchiveBackendApp` | `continuumCsTokenService` | Validates CSR session tokens | REST |
| `continuumVoucherArchiveBackendApp` | `messageBus` | Publishes GDPR completion events; consumes erasure events | JMS |
| `continuumVoucherArchiveBackendApp` | `continuumRetconService` | Triggers personal data erasure during GDPR flow | REST |
| `continuumVoucherArchiveBackendApp` | `continuumMxMerchantApi` | Validates merchant authentication tokens | REST |

## Architecture Diagram References

- System context: `contexts-voucher-archive-backend`
- Container: `containers-voucher-archive-backend`
- Component: `components-voucher-archive-backend`
