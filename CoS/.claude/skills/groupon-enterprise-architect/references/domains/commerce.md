# Commerce Domain

## Overview

The Commerce domain spans order processing, payment handling, pricing, inventory management, booking, and travel services within the Continuum platform. It is represented across 3 domain views in the Structurizr architecture model, totaling approximately 86 elements. These views cover the full lifecycle from deal pricing through inventory reservation, order placement, payment processing, fulfillment, and financial reconciliation.

## Domain Views

| Domain | View Key | Elements | Scope |
|--------|----------|----------|-------|
| **Orders, Payments & Finance** | `containers-continuum-platform-commerce` | 31 | Order lifecycle, payment processing, accounting, pricing, forex, billing |
| **Inventory** | `containers-continuum-platform-inventory` | 26 | Voucher, goods, travel, live, CLO, third-party, coupons |
| **Online Booking & Travel** | `containers-continuum-platform-booking` | 29 | Reservation lifecycle, availability, booking APIs, travel inventory |

These views overlap with adjacent domains: the Merchant & Partner domain (`containers-continuum-platform-merchant`, 38 elements) handles merchant accounts and deal management, while the Data & Analytics domain (`containers-continuum-platform-data-analytics`, 31 elements) provides warehouse and reporting infrastructure that commerce services export to.

## Service Clients (via Lazlo SOX)

The API Lazlo SOX aggregator exposes commerce functionality to consumers through these downstream service clients:

| Category | Clients | Role |
|----------|---------|------|
| **Order management** | CartServiceClient, WriteOnlyOrdersClient, ReadOnlyOrdersClient | Cart operations, order placement (write-path), order lookup (read-path) |
| **Inventory — Voucher** | VIS (Voucher Inventory Service) | System of record for voucher lifecycle |
| **Inventory — Card-Linked** | CLO (Card-Linked Offers) | Card-linked offer inventory |
| **Inventory — Physical** | Stores, Goods | Physical goods and store inventory |
| **Inventory — Third-Party** | TPIS (Third-Party Inventory Service) | External partner inventory |
| **Inventory — Experience** | GLive (Groupon Live), MR Getaways, Getaways | Events, travel packages, getaway inventory |
| **Pricing & Incentives** | Offers, Bucks, AutoRebuy, Subscriptions | Deal offers, Groupon Bucks credits, auto-renewal, subscription management |

## Voucher Inventory Service (Representative Architecture)

**Technology:** Ruby on Rails | **Container ID:** 554 | **Components:** 25 | **Domain:** Inventory

VIS is the system of record for voucher lifecycle — creation, reservation, redemption, gifting, refunds, and expiration. It follows a clean 4-layer architecture representative of Continuum services.

**Component breakdown by layer:**

| Layer | Count | Components |
|-------|-------|------------|
| **API** | 6 | Status & Health API (555), Inventory Products API (556), Units & Redemptions API (557), Reservation API (558), Redemption Code Pools API (559), Features & Config API (560) |
| **Domain** | 5 | Inventory Product Manager (561), Inventory Unit Manager (562), Redemption Code Pool Manager (563), Booking Appointments Manager (564), Voucher Barcode Reports (565) |
| **Data Access** | 2 | Inventory Data Accessors (566) — ActiveRecord/MySQL, Cache & Lock Accessors (567) — Redis caching, distributed locks, counters |
| **Integration** | 8 | Orders Client (568), Pricing Client (569), Deal Catalog Client (570), Merchant Service Client (571), JTier Client (572), Goods Central Client (573), Geo Service Client (574), Booking Service Client (575) |
| **Cross-Cutting** | 4 | EDW Exporter (576) — daily batch ETL to S3/Teradata, Experimentation Integration (577) — feature flags via Reading Rainbow, Message Producer (578) — publishes events to ActiveMQ, Observability (579) — New Relic APM, Wavefront, ELK |

**Data flow example (Inventory Unit Manager):**

```
Units & Redemptions API (557) ──> Inventory Unit Manager (562)
Reservation API (558) ──────────> Inventory Unit Manager (562)
                                        |
                    ┌───────────────────┼──────────────────────┐
                    v                   v                      v
          Data Accessors (566)   Cache & Locks (567)    Orders Client (568)
          (ActiveRecord/SQL)     (Redis)                (HTTPS/JSON)
                    |                                         |
                    v                   v                      v
          Voucher Units DB (542) Pricing Client (569)   Merchant Client (571)
          (MySQL)                Geo Client (574)       Goods Central (573)
```

## Pricing Service (Representative Architecture)

**Technology:** Java, RESTEasy, Quartz | **Container ID:** 901 | **Components:** 27 | **Domain:** Commerce

The pricing engine handles current/future prices, retail prices, program prices, price rules, and price history. It demonstrates the Java variant of Continuum's layered pattern.

**Component breakdown by layer:**

| Layer | Count | Components |
|-------|-------|------------|
| **API** | 7 | Current & Future Price (902), Program Price Bulk (903), Retail Price (904), Price Rule (905), Price History (906), Product Feature Flags (907), Config & Health (908) |
| **Domain** | 11 | Current Price Service (909), Retail Price Service (910), Program Price Service (911), Price Rule Service (912), Price Rule Update (913), Price History Service (914), Feature Flag Service (915), Established Price (916), Price Metadata (917), Quote Price History (918), Price Update Workflow (919) |
| **Background** | 2 | Scheduled Update Worker (920) — processes scheduled price updates and recovery, Quartz Job Runner (921) — emits price events on configured cadences |
| **Data Access** | 4 | Pricing DB Repository (922) — JDBC queries, PWA DB Repository (923) — inventory state parity checks, Redis Price Cache (924) — Lettuce client with bulk get/set PriceSummary CSV, VIS HTTP Client (927) — fetches product/unit details from Voucher Inventory |
| **Integration** | 3 | MBus Producers (925) — publishes price/retail/program/rule change events, MBus Consumers (926) — consumes VIS inventory updates and price rule events, Deal Catalog Client (928) — fetches deal metadata for program price validation |

## Architecture Patterns

| Pattern | VIS (Ruby) | Pricing (Java) |
|---------|------------|----------------|
| **Architecture style** | Layered: API -> Domain -> Data -> Integration | Layered: API -> Domain -> Data -> Integration |
| **Framework** | Rails controllers | RESTEasy servlets |
| **Database** | MySQL via ActiveRecord | MySQL via JDBC |
| **Cache** | Redis (custom client) | Redis (Lettuce) |
| **Messaging** | ActiveMQ producer | ActiveMQ producer + consumer |
| **Batch** | S3 ETL exporter | Quartz scheduler |
| **Observability** | New Relic, Wavefront, ELK | Not explicitly modeled |

These patterns are representative of Continuum's ~1,164 containers: microservices with clean component decomposition, MySQL + Redis backing, connected via ActiveMQ message bus and HTTP clients.

## External Dependencies

| System | ID | Role |
|--------|----|------|
| Payment Gateways | 12 | Payment processing (Adyen, PayPal, Amex settlements) |
| 3rd-Party Inventory Systems | 62 | Partner inventory integration |
| Salesforce.com | 14 | Deal catalog data (inbound contracts) |
| Analytics Platforms | 51 | Tracking and attribution |

## Key Timeouts

| Operation | Timeout |
|-----------|---------|
| Default connect | 200ms |
| Default request | 2,000ms |
| Write operations (orders, bucks) | Up to 60,000ms |
| Localization / CMS | 6,000ms |

The 60-second timeout for write operations reflects the transactional nature of order placement and Groupon Bucks operations, which may involve multiple downstream calls (inventory reservation, payment authorization, order creation) in sequence.

## Source Links

| Document | Space | Link |
|----------|-------|------|
| Continuum Containers | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82198331428/Continuum) |
| Continuum Components | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82250137601/Continuum+Components) |
| Runtime Flows | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82197479479) |
| Pricing Service Architecture | DPR | [View](https://groupondev.atlassian.net/wiki/spaces/DPR/pages/13073966690/Architecture) |
| Overall Architecture & Teams (FSA) | FSA | [View](https://groupondev.atlassian.net/wiki/spaces/FSA/pages/81910136860/Overall+architecture+and+teams+overview) |
| Groupon Architecture Next (C4 Model) | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82195873828/Groupon+Architecture+Next) |
