# Groupon Platform Architecture — Collected Materials

> Compiled 2026-02-28 from Groupon Confluence (`groupondev.atlassian.net`)

---

## Table of Contents

1. [Architecture Overview (C4 Model)](#1-architecture-overview-c4-model)
2. [Core Platforms](#2-core-platforms)
   - [Encore (B2B / Internal Operations)](#encore-b2b--internal-operations)
   - [Continuum (Consumer-Facing Legacy)](#continuum-consumer-facing-legacy)
   - [MBNXT (Next-Gen Consumer / Mobile)](#mbnxt-next-gen-consumer--mobile)
3. [API Layer (GAPI Monorepo)](#3-api-layer-gapi-monorepo)
4. [Data Platform & Discovery](#4-data-platform--discovery)
5. [Financial Systems & Analytics](#5-financial-systems--analytics)
6. [Revenue Operations Platform](#6-revenue-operations-platform)
7. [AIDG (AI Deal Generation)](#7-aidg-ai-deal-generation)
8. [AdsOnGroupon](#8-adsonroupon)
9. [Source Links](#9-source-links)

---

## 1. Architecture Overview (C4 Model)

Groupon maintains a **Structurizr-as-code** architecture model in Git (`github.com/groupon/architecture`) with auto-generated C4 diagrams published to Confluence daily. The architecture space (`ARCH`) provides:

- **System landscape & context** — Bird's-eye view of main platforms, users, and external dependencies
- **Containers & components** — Internal structure of each platform (apps, services, databases, workers)
- **Runtime & deployment** — End-to-end business flows and GCP production deployment
- **Team topology & ownership** — How teams map to systems

### Three Core Platforms

| Platform | Purpose | Tech Stack |
|----------|---------|------------|
| **Encore** | B2B services, internal operations, merchant tools | TypeScript, Encore.dev, PostgreSQL, GCP Cloud Run |
| **Continuum** | Consumer-facing marketplace (legacy + active) | Java/Vert.x, Ruby/Sinatra, MySQL, Redis |
| **MBNXT** | Next-gen consumer experience (web + mobile) | React/Next.js, React Native, GraphQL |

---

## 2. Core Platforms

### Encore (B2B / Internal Operations)

**Space:** [Encore](https://groupondev.atlassian.net/wiki/spaces/Encore/) | **Architecture:** [ARCH space](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82243453341/Encore+Containers)

Encore is the **new-generation B2B and internal operations platform** built on the [Encore.dev](https://encore.dev) framework.

**Infrastructure:**
- **GCP Projects:**
  - `prj-grp-encore-pr-stable` — Preview environments
  - `prj-grp-encore-stable` — Staging
  - `prj-grp-encore-prod` — Production
- **Regions:** US (us-central1) and EMEA (europe-west1)
- **Networking:** Shared VPC with private IPs (custom setup with Encore Dev team)
- **Database:** PostgreSQL on Cloud SQL (private IP only)
- **Deployment:** Cloud Run with Direct VPC Egress
- **Frontend:** Static SPA hosted on Digital Ocean, served via `admin.groupondev.com`

**Key Architecture Decisions:**
- Uses `github.com/groupon` (public GitHub) instead of internal `github.groupondev.com` due to Encore Cloud integration requirements
- OAuth login via Google standard flow backed by Okta
- Monorepo at `groupon-monorepo` containing Encore TS backend + React frontends

**Sub-projects within Encore:**
- AI Self-Service, AIDG, Admin, PF Playground, Support Angular, Mastra AI framework (frozen)

---

### Continuum (Consumer-Facing Legacy)

**Architecture:** [Continuum Containers](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82198331428/Continuum) | [Continuum Components](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82250137601/Continuum+Components)

Continuum is the **existing consumer-facing marketplace platform** — the backbone serving groupon.com and associated properties. Container and component diagrams are auto-generated from Structurizr.

**Key Architectural Layers (from GAPI KT docs):**

| Layer | Technology | Services |
|-------|-----------|----------|
| **API Proxy** | Java/Vert.x | Request routing, rate limiting, filter chains, A/B testing |
| **API Lazlo SOX** | Java/Vert.x | SOX-compliant API aggregator with 50+ downstream service clients |
| **Users Service** | Ruby/Sinatra | User authentication, OTP, database-backed feature flags |
| **Identity Service** | Ruby/Sinatra + PostgreSQL | Identity management (newer, coexists with Users Service) |
| **Deckard** | Java/Vert.x | Inventory unit indexing, Redis caching, async updates |
| **Client-ID** | Java/Dropwizard + MySQL | API client identification and access management |

**Multi-Region Deployment:**

| Region | Type | Services |
|--------|------|----------|
| snc1 | Legacy DC | Proxy, Lazlo, Deckard, Client-ID |
| us-central1 | GCP Primary | All services |
| us-west-1/2 | GCP | All services |
| europe-west1 | GCP EMEA | All services |
| dub1 | Legacy EMEA | All services |
| eu-west-1 | AWS EMEA | All services |
| sac1 | South America | All services |

**API Proxy Filter Chain:**
TracingFilter → ExtensionFilter → ErrorFilter → BCookieFilter → BCookieTranslateFilter → SubscriberIDCookieFilter → SignifydCookieFilter → XForwardedProtoFilter → LoadShedFilter → BrandFilter → ClientIdFilter → RateLimitFilter → CORSFilter → RecaptchaFilter

**Key Timeouts:**
- Default connect: 200ms, Default request: 2000ms
- Write operations (orders, bucks): up to 60s
- Localization (CMS): 6s

---

### MBNXT (Next-Gen Consumer / Mobile)

**Space:** [MBNXT Documentation](https://groupondev.atlassian.net/wiki/spaces/MD/) | **Architecture:** [Mobile-Next Containers](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82253447276/Mobile-Next+Containers)

MBNXT is modeled as **part of the Continuum platform** — the next-generation consumer experience for web (PWA) and native mobile apps (React Native).

**Key Surfaces:**
- Web (touch / responsive)
- iOS native (React Native)
- Android native (React Native)
- GraphQL API layer

**Current Status (Feb 2026):**
- Active international expansion (13 countries: US, CA, CA-QC, GB, DE, FR, IT, ES, NL, BE, PL, IE, AE, AU)
- EMEA rollout planned as all-at-once with feature-flag split against legacy iOS app
- Daily releases with Jenkins CI + Playwright E2E tests

---

## 3. API Layer (GAPI Monorepo)

**Space:** [Groupon API](https://groupondev.atlassian.net/wiki/spaces/GA/)

The GAPI monorepo is the core API infrastructure serving all consumer traffic. Detailed KT documents available:

### Service Configuration Hierarchy
```
Base Configs (default)
  → Environment Overrides (staging / uat / production)
    → Region Overrides (per-datacenter / cloud-region)
      → Runtime Overrides (DB-backed flags, feature toggles)
```

### API Lazlo SOX — 30+ Service Clients
Major downstream dependencies include:
- **AdsClient** (ads-on-groupon), **CartServiceClient**, **DealCatalogClient**
- **UsersClient**, **WriteOnlyOrdersClient**, **ReadOnlyOrdersClient**
- **TaxonomyClient**, **LocalizeClient** (CMS)
- Inventory clients: VIS, CLO, Stores, Goods, TPIS, GLive, MR Getaways, Getaways
- Plus: AutoRebuy, Bucks, CloConsent, CustomerService, Epods, Geoplaces, Getaways (multiple), Incentives, Merchant, MerchantPlace, Messaging, Offers, Subscriptions, UGC, Wishlist

### Authentication Architecture (OTP System)
Three-layer architecture:
1. **API Gateway (Java/Vert.x)** — API Lazlo SOX controllers + BLS services
2. **Users Service (Ruby/Sinatra)** — OTP generation/validation, Redis-backed state
3. **Infrastructure** — Redis for caching/rate limiting, Rocketman for email delivery

### Feature Flag Systems
| System | Technology | Used By |
|--------|-----------|---------|
| **Birdcage** | External HTTP service | Java services (Proxy, Lazlo, Deckard) |
| **Setting model** | MySQL-backed JSON | Ruby services (Users, Identity) |
| **Config-based** | JSON files per environment/region | All Java services |
| **countryFeatures.json** | Per-country feature toggles | API Lazlo |

### Redis Usage Across Services

| Service | Port | Purpose |
|---------|------|---------|
| API Proxy | 6379 | Rate limiting counters |
| Deckard (cache) | 7000 (cluster) | Inventory unit cache |
| Deckard (async) | 6379 | Async update queue |
| Users Service | 6379 | OTP codes, sessions |
| Identity Service | 6379 | Session storage |

---

## 4. Data Platform & Discovery

**Space:** [Data & Discovery](https://groupondev.atlassian.net/wiki/spaces/DD/)

### Tribe Structure (5 Squads)

| Squad | Responsibility | Key Services |
|-------|---------------|-------------|
| **DnD Infrastructure** | GCP infra: Teradata, Keboola, BigQuery, Bigtable, Data Lake, Dataproc | BigQuery, Teradata, Keboola-infra, GCP-Hadoop-Infra |
| **DnD Janus** | Foundational data ingestion pipeline — raw events → canonical datasets | Janus Engine, Janus Yati, Janus Muncher, Watson Realtime/API, Ask Janus AI |
| **DnD Ingestion** | Database source ingestion (MySQL, PostgreSQL, RDS, CloudSQL) | Megatron (CDC→TD/Hadoop), Magneto (Salesforce), GCP Datastream |
| **DnD PRE** | Platform Reliability Engineering — 24/7 pipeline operations | Airflow (Cloud Composer), Zombie Runner, CKOD, PRE Observability |
| **DnD Tools** | Tableau, Data Catalog (OpenMetadata), Optimus Prime ETL, Expy A/B testing | Optimus Prime, Tableau, Data Catalog V2, Expy Service |

### Key Data Technologies
- **Teradata** → being migrated to **BigQuery** (2026 initiative)
- **Keboola** — Cloud ETL platform, replacing legacy pipelines
- **Kafka (AWS Strimzi/Conveyor)** — Real-time event streaming (migrating from MSK)
- **Apache Airflow (Cloud Composer)** — Multi-tenant pipeline orchestration
- **OpenMetadata** — Data catalog v2

---

## 5. Financial Systems & Analytics

**Space:** [FSA](https://groupondev.atlassian.net/wiki/spaces/FSA/)

### Three Core Financial Systems

| System | Responsibility | Tech |
|--------|---------------|------|
| **JLA** (Journal Ledger Accounting) | NA: Daily ETL pipeline, Web app, Event-Based Accounting, O2C Reconciliation, NetSuite integration | Teradata → Data Mart, NetSuite API |
| **FDE** (Financial Data Engine) | INTL: Daily revenue postings, AR reporting, Financial Data Mart | EDW, Falcon frontend, NetSuite |
| **FED** (Financial Entity Data) | Global: Merchant payment calculation, P2P bill creation, Tax authority payments | Salesforce imports, Orders/Inventory, NetSuite |

### High-Level Integration Flow
- **FED** imports contracts from Salesforce, receives unit data from Orders/Inventory, calculates invoices → NetSuite
- **JLA** (NA) sources from Teradata, reconciles PSP settlements (Adyen, PayPal, Amex), creates journal entries → NetSuite
- **FDE** (INTL) produces daily revenue reports and postings from EDW sources → NetSuite

---

## 6. Revenue Operations Platform

**Space:** [Revenue Ops](https://groupondev.atlassian.net/wiki/spaces/RO/)

Marketing message delivery infrastructure with two pipelines:

### The Legacy Pipeline (On-Premises)
On-prem Hadoop-based pipeline for certain stakeholder groups' reports and analysis.

### The Modern Pipeline (GCP)
Google Cloud Platform pipeline for email and push notifications:

**4-Phase Message Journey:**
1. **User Subscription & Audience Definition** — Subscription Flow → Subscription Service → Audience Service
2. **Campaign Planning & Setup** — Audience Service for targeting, campaign configuration
3. **Message Dispatch & Delivery** — Message assembly, delivery via email/push providers
4. **Tracking & Analytics** — Engagement tracking, reporting feedback loops

---

## 7. AIDG (AI Deal Generation)

**Space:** [Merchant Advisor](https://groupondev.atlassian.net/wiki/spaces/MA/)

AI-powered merchant onboarding and deal generation platform.

### Architecture
| Layer | Technology |
|-------|-----------|
| **Frontend** | Next.js 15.3.1, React 19, Tailwind CSS, Shadcn UI, TanStack Query, Preact Signals |
| **Backend** | Encore.dev microservices, TypeScript, Node.js 22+ |
| **Database** | PostgreSQL with Drizzle ORM |
| **Auth** | JWT with role-based access control |
| **External** | Salesforce, Google APIs, OpenAI |

### Key Features
- Pre-qualification form with Salesforce account retrieval
- AI-powered service detection from merchant websites
- Dynamic pricing and margin analysis
- Automated content generation and image scraping
- Dual preview modes (internal admin + merchant-facing)
- Feature flag management, audit logging

---

## 8. AdsOnGroupon

**Space:** [AOG](https://groupondev.atlassian.net/wiki/spaces/AOG/)

Sponsored ads platform undergoing **2026 re-architecture** (Teradata → BigQuery + Keboola).

### Current Services
| Service | Tech | Status |
|---------|------|--------|
| **ai-reporting** (ads-on-groupon) | Java/Dropwizard | KEEP — campaign management + click tracking |
| **ad-inventory** | Java/Dropwizard | KEEP — ad serving, audience mgmt, DFP/LiveIntent/Rokt |
| **sponsored-campaign-itier** | Node.js + React | KEEP — merchant UI for sponsored listings |
| **ads-jobframework** | Scala/Spark | RETIRE → migrate to Keboola |

### CitrusAd (Epsilon) Integration
Bidirectional data flow — outbound feeds (Order, Customer, Product) and inbound feeds (campaign performance, billing).

### Re-Architecture Plan (2026)
1. Architecture analysis and simplification
2. Keboola migration for ETL pipelines
3. Service consolidation: merge ad-inventory + ai-reporting → **ads-platform**

---

## 9. Source Links

### Top-Level Architecture
| Document | Space | Link |
|----------|-------|------|
| Groupon Architecture Next (C4 Model) | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82195873828/Groupon+Architecture+Next) |
| Encore Containers | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82243453341/Encore+Containers) |
| Encore Components | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82252398686/Encore+Components) |
| Continuum Containers | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82198331428/Continuum) |
| Continuum Components | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82250137601/Continuum+Components) |
| MBNXT Containers | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82253447276/Mobile-Next+Containers) |
| MBNXT Components | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82253512786) |
| Runtime Flows | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82197479479) |
| Deployment | ARCH | [View](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82207572032) |

### Platform-Specific
| Document | Space | Link |
|----------|-------|------|
| Encore Architecture — High Level | Encore | [View](https://groupondev.atlassian.net/wiki/spaces/Encore/pages/82181062730/Encore+architecture+-+high+level) |
| Java to TypeScript Encore Onboarding | Encore | [View](https://groupondev.atlassian.net/wiki/spaces/Encore/pages/81950998562) |
| B2C Tribe Architecture | CONSUMERXP | [View](https://groupondev.atlassian.net/wiki/spaces/CONSUMERXP/pages/82227920968/Architecture) |
| MBNXT International Readiness | — | [View](https://groupondev.atlassian.net/wiki/spaces/~712020c11fe51675d74604805a948251ecad9d/pages/82526044660) |

### API & Services
| Document | Space | Link |
|----------|-------|------|
| KT: Service Configurations (GAPI) | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82559139956/KT+Service+Configurations) |
| KT: OTP Authentication System | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82561368067/KT+OTP+Authentication+System) |
| KT: reCAPTCHA Enterprise V3 | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82558058896/KT+reCAPTCHA+Enterprise+V3+Integration) |
| KT: Signifyd Fraud Detection | GA | [View](https://groupondev.atlassian.net/wiki/spaces/GA/pages/82558223114/KT+Signifyd+Fraud+Detection+Integration) |

### Data & Analytics
| Document | Space | Link |
|----------|-------|------|
| DnD Tribe Structure | DD | [View](https://groupondev.atlassian.net/wiki/spaces/DD/pages/82524864515/DnD+-+Data+Platform+and+Discovery+Tribe+structure) |
| Data Platform Architecture | DD | [View](https://groupondev.atlassian.net/wiki/spaces/DD/pages/81905352726/Data+Platform+Architecture) |
| Data Platform Architecture KTs | DD | [View](https://groupondev.atlassian.net/wiki/spaces/DD/pages/81862656028/Data+Platform+Architecture+KTs) |

### Financial Systems
| Document | Space | Link |
|----------|-------|------|
| Overall Architecture & Teams | FSA | [View](https://groupondev.atlassian.net/wiki/spaces/FSA/pages/81910136860/Overall+architecture+and+teams+overview) |

### Revenue Operations
| Document | Space | Link |
|----------|-------|------|
| Revenue Ops Platform Architecture | RO | [View](https://groupondev.atlassian.net/wiki/spaces/RO/pages/81924390991) |

### AIDG
| Document | Space | Link |
|----------|-------|------|
| AIDG Comprehensive Architecture | MA | [View](https://groupondev.atlassian.net/wiki/spaces/MA/pages/81978359825/AIDG+Platform+-+Comprehensive+Architecture+Document) |

### AdsOnGroupon
| Document | Space | Link |
|----------|-------|------|
| AdsOnGroupon Re-Architecture 2026 | AOG | [View](https://groupondev.atlassian.net/wiki/spaces/AOG/pages/82521686254/AdsOnGroupon+Re-Architecture+2026) |
| Architecture Analysis | AOG | [View](https://groupondev.atlassian.net/wiki/spaces/AOG/pages/82521882757/01-Architecture+Analysis) |
| Service Consolidation Plan | AOG | [View](https://groupondev.atlassian.net/wiki/spaces/AOG/pages/82522341523/03-Service+Consolidation) |
| CitrusAd Integration Architecture | AOG | [View](https://groupondev.atlassian.net/wiki/spaces/AOG/pages/82526830671) |

### Other
| Document | Space | Link |
|----------|-------|------|
| Pricing Service Architecture | DPR | [View](https://groupondev.atlassian.net/wiki/spaces/DPR/pages/13073966690/Architecture) |
| Office Networking 2026+ | IO | [View](https://groupondev.atlassian.net/wiki/spaces/IO/pages/82524962819) |
| Observability Stack AI Enablement | EO | [View](https://groupondev.atlassian.net/wiki/spaces/EO/pages/82541150234) |
| CICD GHA Runners Dashboard | EO | [View](https://groupondev.atlassian.net/wiki/spaces/EO/pages/82559762573) |
| Structurizr Repository | — | [GitHub](https://github.com/groupon/architecture) |
