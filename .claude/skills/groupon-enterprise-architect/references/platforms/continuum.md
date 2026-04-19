# Continuum Platform

> Tier 3 reference — factual, concise, architect-focused

## Current State

- **Structurizr ID:** 297
- **Containers:** 1,164 (89% of all 1,311 containers in the architecture model)
- **Role:** Core commerce engine — the dominant system; legacy + modern microservices for deals, orders, payments, marketing, merchant ops
- **Tech Stack:** Java/Vert.x, Ruby/Sinatra, MySQL, Redis, ActiveMQ
- **Status:** Active production system. Strategic direction is gradual migration to Encore via wrapper pattern, but Continuum remains the backbone serving groupon.com and all consumer/merchant experiences.

## Deployment

Multi-region deployment across legacy data centers, GCP, and AWS:

| Region | Type | Services |
|--------|------|----------|
| snc1 | Legacy DC | Proxy, Lazlo, Deckard, Client-ID |
| us-central1 | GCP Primary | All services |
| us-west-1/2 | GCP | All services |
| europe-west1 | GCP EMEA | All services |
| dub1 | Legacy EMEA | All services |
| eu-west-1 | AWS EMEA | All services |
| sac1 | South America | All services |

## Domain Architecture

Continuum is organized into 11 domain slices, each with its own Structurizr container view:

| Domain | View Key | Elements | Scope |
|--------|----------|----------|-------|
| Core Flows | `containers-continuum-platform-core` | 36 | Frontends, edge, aggregation APIs, core services, data stores |
| Orders, Payments & Finance | `containers-continuum-platform-commerce` | 31 | Order lifecycle, payment processing, accounting, pricing, forex, billing |
| Inventory | `containers-continuum-platform-inventory` | 26 | Voucher, goods, travel, live, CLO, third-party, coupons |
| Merchant & Partner | `containers-continuum-platform-merchant` | 38 | Merchant accounts, deal management, contracts, places, compliance |
| Identity & Access | `containers-continuum-platform-identity` | 26 | Auth, identity resolution, RBAC, consent, API authorization |
| Messaging & Events | `containers-continuum-platform-messaging` | 25 | ActiveMQ, Kafka, push, webhooks, notifications, event replay |
| Data & Analytics | `containers-continuum-platform-data-analytics` | 31 | Warehouses, Spark, search indexes, audience stores, AI workloads |
| Online Booking & Travel | `containers-continuum-platform-booking` | 29 | Reservation lifecycle, availability, booking APIs, travel inventory |
| Marketing / Ads / Reporting | `containers-continuum-platform-marketing-ads` | 23 | Marketing campaigns, ads, sponsored listings, reporting |
| Supply | `containers-continuum-platform-supply` | 21 | Supply domain PoCs (Coffee, Deal Alerts, LeadGen) |
| MBNXT Surfaces | `containers-continuum-platform-mbnxt` | 7 | MBNXT web/mobile/GraphQL within Continuum |

Total across domain views: 293 elements (some containers appear in multiple domains).

## Key Architectural Layers

From GAPI KT documentation — the primary request-handling stack:

| Layer | Technology | Services |
|-------|-----------|----------|
| API Proxy | Java/Vert.x | Request routing, rate limiting, filter chains, A/B testing |
| API Lazlo SOX | Java/Vert.x | SOX-compliant API aggregator with 50+ downstream service clients |
| Users Service | Ruby/Sinatra | User authentication, OTP, database-backed feature flags |
| Identity Service | Ruby/Sinatra + PostgreSQL | Identity management (newer, coexists with Users Service) |
| Deckard | Java/Vert.x | Inventory unit indexing, Redis caching, async updates |
| Client-ID | Java/Dropwizard + MySQL | API client identification and access management |

**API Proxy Filter Chain:** TracingFilter > ExtensionFilter > ErrorFilter > BCookieFilter > BCookieTranslateFilter > SubscriberIDCookieFilter > SignifydCookieFilter > XForwardedProtoFilter > LoadShedFilter > BrandFilter > ClientIdFilter > RateLimitFilter > CORSFilter > RecaptchaFilter

**Key Timeouts:** Default connect 200ms, default request 2000ms, write operations (orders, bucks) up to 60s, localization (CMS) 6s.

## Infrastructure

| Type | Details |
|------|---------|
| Edge | API Proxy (id:298) — NGINX/Envoy edge gateway |
| Messaging | Message Bus (id:300) — ActiveMQ Artemis; Janus Tier1 Topic (id:361) — Kafka |
| Data Stores | Hive Warehouse (id:357), HDFS (id:358), Cassandra Audience Cluster (id:359), Realtime Audience Bigtable (id:360), ElasticSearch Cluster (id:346) |
| Legacy EDW | Teradata EDW (id:299) — marked ToDecommission, being replaced by BigQuery |
| Consumer Apps | Legacy Web (id:303), Legacy Android (id:301), Legacy iOS (id:302) — all ToDecommission, replaced by MBNXT |
| Merchant Apps | Merchant Center (id:305) — Ruby on Rails/Java |
| AI/ML | GenAI Service (id:325) — generative AI for deal creation |

## External Dependencies

| External System | ID | Purpose | Protocol |
|----------------|-----|---------|----------|
| Payment Gateways | 12 | Payment processing (Adyen, PayPal, Amex) | API |
| Analytics Platforms | 51 | Tracking and attribution | API |
| Booster | 83 | External relevance engine (primary) | API |
| Cloud Platform | 41 | Hosting (GCP, AWS, legacy DC) | Cloud |
| Email & Messaging Providers | 46 | Email/SMS delivery | API |
| Salesforce.com | 14 | Deal catalog data (inbound), contracts | API |
| 3rd-Party Inventory Systems | 62 | Partner inventory | API |
| Google Ad Manager | 23 | Ad inventory and reporting | API |
| CitrusAd | 31 | Sponsored listings & ad performance | API |
| LiveIntent | 32 | Ad platform | API |
| Rokt | 33 | Ad platform | API |

## Architecture Patterns

- **Layered service architecture:** API controllers > Domain managers > Data accessors > Integration clients. Consistent across both Ruby (Rails controllers, ActiveRecord) and Java (RESTEasy servlets, JDBC) services.
- **Java/Vert.x for edge and aggregation:** API Proxy, API Lazlo SOX, Deckard all use Vert.x for high-throughput async I/O.
- **Ruby/Sinatra for identity and user services:** Users Service, Identity Service use Sinatra with MySQL/PostgreSQL.
- **MySQL as dominant data store:** Shared MySQL clusters across services — legacy pattern where multiple services read/write the same schema.
- **Redis caching:** Used across services — rate limiting (Proxy, port 6379), inventory cache (Deckard, cluster port 7000), async queues (Deckard, port 6379), OTP codes and sessions (Users, Identity, port 6379).
- **ActiveMQ Artemis:** Primary message bus for inter-service event-driven communication. Kafka used for data platform (Janus ingestion).
- **Spark/Hadoop:** Batch processing for data analytics, audience building, and ETL pipelines.
- **Datadog/New Relic/Wavefront:** Observability stack; Observability Platform (id:96) is a separate shared system with 3 containers.

## Decommission Targets

11 elements tagged `ToDecommission` in the architecture model:

| Element | ID | Type | Notes |
|---------|-----|------|-------|
| EDW - Teradata | 299 | Container | Being replaced by BigQuery |
| Legacy Android App | 301 | Container | Replaced by MBNXT |
| Legacy iOS App | 302 | Container | Replaced by MBNXT |
| Legacy Web | 303 | Container | Replaced by MBNXT |
| Calendar Service | 349 | Container | Legacy calendar sync |
| MDS MongoDB | 770 | Container | Database migration |
| Feynman Search | 819 | Container | Legacy search |
| Slack | 45 | System | Being replaced as notification channel |
| Mailgun | 47 | System | Being replaced as email provider |
| OptimusPrime Analytics | 91 | System | Being replaced |

Note: Only 10 listed above from extracted data. The 11th element was not individually resolved in the source query but the total count is confirmed as 11.

## Relationship to Encore

- **Direction:** One-directional. Encore (id:7580) depends on Continuum via "Integrations (wrappers, pub/sub)" over JSON/HTTPS. Continuum does not depend on Encore at the system level.
- **Integration Points:**
  - 17 Encore wrapper services act as typed TypeScript proxies to Continuum APIs (DMAPI, Users, Lazlo, Orders, MDS, M3, Salesforce, BigQuery, Booster, Bhuvan, MBus, Gazebo, Getaway, UMAPI, Bynder, Google Places, and more)
  - Pub/sub via MBus Wrapper (id:7657) to ActiveMQ Message Bus (id:300)
  - REST calls to InferPDS API (id:2787) for AIDG enrichment
  - REST calls to Merchant Quality API (id:2788) for scoring
- **Pattern:** Strangler fig migration — Encore wraps Continuum capabilities rather than rewriting them, gradually owning more business logic.

## Actors

| Actor | ID | Relationship |
|-------|----|-------------|
| Consumer | 1 | Access consumer services (HTTPS) |
| Merchant | 2 | Manages inventory, bookings, portal tools |
| Affiliate Partner | 5 | Sends traffic (HTTPS) |
| Encore Platform | 7580 | Integrations via wrappers and pub/sub (JSON/HTTPS) |
| MBNXT Platform | 8265 | Integrates with legacy services (API) |
| Orders Team | 8 | Owns Orders domain |
| RAPI Team | 9 | Owns Relevance API |
| MDS Team | 11 | Owns Marketing Deal Service |

## Source Links

| Document | Link |
|----------|------|
| Continuum Containers | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82198331428/Continuum) |
| Continuum Components | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82250137601/Continuum+Components) |
| Runtime Flows | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82197479479) |
| Deployment | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82207572032) |
| KT: Service Configurations (GAPI) | [GA](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82559139956/KT+Service+Configurations) |
| KT: OTP Authentication System | [GA](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82561368067/KT+OTP+Authentication+System) |
| Structurizr Repository | [GitHub](https://github.com/groupon/architecture) |
