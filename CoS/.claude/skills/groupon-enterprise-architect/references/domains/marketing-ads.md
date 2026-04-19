# Marketing, Ads & Reporting Domain

> Tier 3 reference — factual, concise, architect-focused

## Overview

**Domain View:** `containers-continuum-platform-marketing-ads` (23 elements)

Three sub-domains: marketing message delivery (Revenue Operations), sponsored advertising (AdsOnGroupon), and AI deal generation (AIDG). They share infrastructure (data pipelines, audience stores, Teradata/BigQuery) but operate as distinct systems with separate ownership. AIDG lives within Encore Platform, not Continuum.

## Revenue Operations Platform

**Space:** [Revenue Ops](https://groupondev.atlassian.net/wiki/spaces/RO/)

Two parallel pipelines:

- **Legacy Pipeline (On-Premises):** Hadoop-based, serves certain stakeholder reports/analysis. Still active for workloads not yet ported to GCP.
- **Modern Pipeline (GCP):** Strategic direction for all email and push notification delivery.

**4-Phase Message Journey:**

1. **User Subscription & Audience Definition** — Subscription Service manages consent state. Audience Service builds targetable segments from Cassandra Audience Cluster (id:359), Realtime Audience Bigtable (id:360), and Hive Warehouse (id:357).

2. **Campaign Planning & Setup** — Audience Service provides targeting. Campaign config defines content, scheduling, A/B variants, delivery rules per market.

3. **Message Dispatch & Delivery** — Message assembly with deal content + personalization. Routes through Email & Messaging Providers (id:46). Rocketman handles transactional email.

4. **Tracking & Analytics** — Opens, clicks, conversions, unsubscribes. Feedback loops into audience definitions. Data flows to Teradata/BigQuery for reporting.

## AdsOnGroupon

**Space:** [AOG](https://groupondev.atlassian.net/wiki/spaces/AOG/)

Sponsored ads platform undergoing a 2026 re-architecture initiative (Teradata → BigQuery + Keboola).

### Current Services

| Service | Technology | Status | Responsibility |
|---------|-----------|--------|---------------|
| **ai-reporting** (ads-on-groupon) | Java/Dropwizard | KEEP | Campaign management, click tracking, performance reporting |
| **ad-inventory** | Java/Dropwizard | KEEP | Ad serving, audience management, DFP/LiveIntent/Rokt integration |
| **sponsored-campaign-itier** | Node.js + React | KEEP | Merchant-facing UI for sponsored listing campaign creation and management |
| **ads-jobframework** | Scala/Spark | RETIRE | Batch ETL jobs — scheduled for migration to Keboola |

### CitrusAd (Epsilon) Integration

Bidirectional data flow:

- **Outbound** (Groupon → CitrusAd): Order, Customer, Product catalog data.
- **Inbound** (CitrusAd → Groupon): Campaign performance, billing data → feeds into ai-reporting.

### 2026 Re-Architecture Plan

Three-phase simplification initiative:

1. **Architecture analysis and simplification** — Audit dependencies, identify redundancy, map data flows.
2. **Keboola migration for ETL** — Replace ads-jobframework (Scala/Spark) with Keboola cloud ETL. Eliminates on-prem Hadoop dependency.
3. **Service consolidation** — Merge ad-inventory + ai-reporting → unified **ads-platform** service. One Java/Dropwizard deployment for campaign management, ad serving, and reporting.

### External Dependencies

| System | Structurizr ID | Purpose |
|--------|---------------|---------|
| Google Ad Manager | 23 | Ad inventory management and reporting |
| CitrusAd (Epsilon) | 31 | Retail media — sponsored product listings, attribution, billing |
| LiveIntent | 32 | Email monetization — ad insertion in marketing emails |
| Rokt | 33 | Post-transaction marketing — targeted offers at checkout |

## AIDG (AI Deal Generation)

**Space:** [Merchant Advisor](https://groupondev.atlassian.net/wiki/spaces/MA/)

AI-powered merchant onboarding and deal generation platform. Lives within the Encore Platform (id:7580) as a B2B service, not within Continuum. Owned by the Encore B2B Team (id:7).

### Architecture

| Layer | Technology | Details |
|-------|-----------|---------|
| **Frontend** | Next.js 15.3.1, React 19 | Tailwind CSS, Shadcn UI component library, TanStack Query for data fetching, Preact Signals for state management |
| **Backend** | Encore.dev, TypeScript | Node.js 22+ runtime, Encore.ts microservices framework with typed RPC endpoints |
| **Database** | PostgreSQL | Drizzle ORM for type-safe database access. Service owns its own DB (`OwnsDB` pattern — AIDG + DB in Structurizr) |
| **Auth** | JWT with RBAC | Encore Gateway handles JWT validation; Authorization service (id in Encore Core) enforces role-based access control |
| **External** | Salesforce, Google APIs, OpenAI | Salesforce for merchant account data (via Salesforce Wrapper id:7662), Google APIs for business information, OpenAI for content generation |

### Key Features

- **Pre-qualification form** — Salesforce account retrieval validates merchant eligibility. Uses Salesforce Wrapper (id:7662).
- **AI service detection** — Analyzes merchant websites to detect service offerings, categories, pricing.
- **Dynamic pricing and margin analysis** — AI-assisted pricing with margin calculations per deal type/market.
- **Content generation and image scraping** — Automated deal descriptions and merchant image collection.
- **Dual preview modes** — Internal admin preview + merchant-facing preview.
- **Feature flags and audit logging** — Gradual rollout control. Audit Log (Encore Core) records all events.

**Continuum integration** via Encore wrappers: DMAPI (id:7650) for deal management, MDS (id:7654) for marketing deal service, Lazlo (id:7651) for aggregation APIs. Also calls InferPDS API (id:2787) for enrichment and Merchant Quality API (id:2788) for scoring.

## Source Links

| Document | Link |
|----------|------|
| Revenue Ops Platform Architecture | [RO](https://groupondev.atlassian.net/wiki/spaces/RO/pages/81924390991) |
| AIDG Comprehensive Architecture | [MA](https://groupondev.atlassian.net/wiki/spaces/MA/pages/81978359825/AIDG+Platform+-+Comprehensive+Architecture+Document) |
| AdsOnGroupon Re-Architecture 2026 | [AOG](https://groupondev.atlassian.net/wiki/spaces/AOG/pages/82521686254/AdsOnGroupon+Re-Architecture+2026) |
| Architecture Analysis | [AOG](https://groupondev.atlassian.net/wiki/spaces/AOG/pages/82521882757/01-Architecture+Analysis) |
| Service Consolidation Plan | [AOG](https://groupondev.atlassian.net/wiki/spaces/AOG/pages/82522341523/03-Service+Consolidation) |
| CitrusAd Integration Architecture | [AOG](https://groupondev.atlassian.net/wiki/spaces/AOG/pages/82526830671) |
