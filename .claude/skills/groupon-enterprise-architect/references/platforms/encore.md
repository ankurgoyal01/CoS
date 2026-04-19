# Encore Platform

> Tier 3 reference — factual, concise, architect-focused

## Current State

- **Structurizr ID:** 7580
- **Containers:** 134
- **Role:** Next-gen TypeScript/Go backbone; AuthN/Z, API Gateway, B2B tools, Groupon Admin
- **Tech Stack:** TypeScript (primary), Go (relevance/cloud), Encore.dev framework, PostgreSQL, GCP Cloud Run
- **Repository:** Monorepo at `github.com/groupon` (public GitHub — required by Encore Cloud integration), repo name `groupon-monorepo` containing Encore TS backend + React frontends
- **Status:** Strategic new-build platform. Active development with growing B2B service portfolio. Migration from Continuum ongoing via wrapper/strangler-fig pattern.

## Infrastructure

| Dimension | Details |
|-----------|---------|
| GCP Projects | `prj-grp-encore-pr-stable` (Preview), `prj-grp-encore-stable` (Staging), `prj-grp-encore-prod` (Production) |
| Regions | US (us-central1) and EMEA (europe-west1) |
| Networking | Shared VPC with private IPs (custom setup with Encore Dev team) |
| Database | PostgreSQL on Cloud SQL (private IP only), service-owned databases |
| Deployment | Cloud Run with Direct VPC Egress |
| Frontend | Static SPA hosted on Digital Ocean, served via `admin.groupondev.com` |

## Service Topology

Encore's 134 containers are organized into four tiers:

**Gateway (1 service)**
- Gateway (id:7581) — API entry point, routes to all downstream services

**Core Services (9 services, 7 with dedicated DBs)**
- Authentication, Authorization, Users, API Tokens, Audit Log, Websocket, Topics, Service Management, Temp Ops
- Each core service with a DB owns its PostgreSQL instance on Cloud SQL

**B2B Services (40 services, 15 with dedicated DBs)**
- Deal, Accounts, Tagging, AIDG, Images, Brands, FAQ, Custom Fields, Notifications, Notes, Video, Email, Dashboard, AI Agents, MCP Server, DCT, Deal Reviews, Workflows, and more
- Domain-specific services for merchant onboarding, deal management, and internal operations

**Wrappers (17 services)**
- Lightweight TypeScript proxies bridging Encore to Continuum APIs (see Wrapper Pattern below)

**Frontends (2)**
- Groupon Admin FE — React SPA for internal admin operations
- AIDG FE — React SPA for AI Deal Generation workflow

## Wrapper Pattern

17 wrapper services implement the strangler-fig migration, providing typed TypeScript interfaces over Continuum's legacy APIs:

| Wrapper | ID | Wraps |
|---------|-----|-------|
| Users Wrapper | 7649 | Continuum user service |
| DMAPI Wrapper | 7650 | Deal Management API |
| Lazlo Wrapper | 7651 | Lazlo aggregation APIs |
| Bhuvan Wrapper | 7652 | Bhuvan location service |
| Orders Wrapper | 7653 | Orders service |
| MDS Wrapper | 7654 | Marketing Deal Service |
| MBus Wrapper | 7657 | ActiveMQ Message Bus |
| Salesforce Wrapper | 7662 | Salesforce.com APIs |
| BigQuery Wrapper | 7663 | BigQuery data access |
| Booster Wrapper | 7665 | Booster relevance engine |
| M3 Wrapper | — | M3 service |
| Gazebo Wrapper | — | Gazebo service |
| Getaway Wrapper | — | Getaway service |
| UMAPI Wrapper | — | UMAPI service |
| Bynder Wrapper | — | Bynder DAM |
| Google Places Wrapper | — | Google Places API |
| Additional Wrapper | — | (17th wrapper from model) |

Each wrapper translates Encore's typed RPC calls into Continuum's REST/JSON endpoints, isolating Encore services from legacy protocol details.

## Data Ownership (OwnsDB)

22 of 23 OwnsDB-tagged containers in the entire architecture belong to Encore. Each service owns a dedicated PostgreSQL database — strict service-owns-its-database pattern, in contrast to Continuum's shared MySQL clusters.

**Core Services with DB:**

| Service | Has DB |
|---------|--------|
| API Tokens | Yes |
| Authorization | Yes |
| Authentication | Yes |
| Users | Yes |
| Audit Log | Yes |
| Websocket | Yes |
| Service Management | Yes |

**B2B Services with DB:**

| Service | Has DB |
|---------|--------|
| Deal | Yes |
| Accounts | Yes |
| Tagging | Yes |
| AIDG | Yes |
| DCT | Yes |
| Images | Yes |
| Brands | Yes |
| FAQ | Yes |
| Custom Fields | Yes |
| Notifications | Yes |
| Notes | Yes |
| Video | Yes |
| Email | Yes |
| Deal Reviews | Yes |
| Workflows | Yes |

## Key Architecture Decisions

- **Public GitHub:** Uses `github.com/groupon` instead of internal `github.groupondev.com` due to Encore Cloud integration requirements. The Encore.dev framework requires public GitHub for its Cloud deployment pipeline.
- **OAuth/Okta:** Google standard OAuth login flow backed by Okta for enterprise identity management. All internal users authenticate through this flow to access Groupon Admin and AIDG.
- **TypeScript primary:** Entire backend in TypeScript via Encore.ts framework; monorepo pattern with shared types and RPC contracts between services. This is a deliberate contrast to Continuum's polyglot estate (Ruby, Java, Scala, Python, Go).
- **Go for relevance/cloud:** Go used specifically for relevance engine and cloud-native services where performance characteristics differ from TypeScript workloads.
- **Encore Topics:** Platform-managed PubSub for inter-service messaging (wraps GCP Pub/Sub). Replaces Continuum's infrastructure-heavy ActiveMQ + Kafka setup with framework-level topic abstractions.
- **Temporal workflows:** Workflow orchestration for long-running B2B processes such as deal creation pipelines, merchant onboarding flows, and data migration jobs. Replaces Continuum's Quartz schedulers and Spark batch jobs.
- **AI via Gateways/Agents/AIDG/MCP:** AI strategy is built into the platform from the start — AI Gateways for centralized LLM access, AI Agents for autonomous task execution, AIDG for merchant deal generation, MCP Server for tool integration with AI coding assistants and chat interfaces.
- **Service-owns-database:** Every service with persistent state gets its own PostgreSQL Cloud SQL instance. No shared databases. This enforces bounded contexts and prevents the cross-service data coupling that characterizes Continuum.

## Sub-projects

| Sub-project | Description |
|------------|-------------|
| AI Self-Service | AI-powered tools for internal teams |
| AIDG | AI Deal Generation — merchant onboarding and deal creation |
| Admin | Groupon Admin internal operations portal |
| PF Playground | Platform feature experimentation |
| Support Angular | Angular-based support tooling |
| Mastra AI | AI framework (frozen — not actively developed) |

## Team Ownership

**Encore Core Team (id:6)** owns:
- Gateway, Authentication (AuthN), Authorization (AuthZ), Users, API Tokens, Topics, Realtime (Websocket), Audit Log, Service Management

**Encore B2B Team (id:7)** owns:
- All B2B domain services (Deal, Accounts, Tagging, AIDG, Images, Brands, FAQ, Custom Fields, Notifications, Notes, Video, Email, Dashboard, AI Agents, MCP Server, DCT, Deal Reviews, Workflows)
- Groupon Admin FE
- AIDG FE

**RAPI Team (id:9)** — owns Relevance API in both Continuum and Encore (cross-platform)

## Migration Relationship

- **Direction:** One-directional. Encore depends on Continuum via "Integrations (wrappers, pub/sub)" over JSON/HTTPS. Continuum does not depend on Encore at the system level. Traffic flows one direction during migration.
- **Integration Points:**
  - 17 wrapper services as typed TypeScript proxies to Continuum APIs
  - Pub/sub via MBus Wrapper (id:7657) to Continuum's ActiveMQ Message Bus (id:300)
  - REST to InferPDS API (id:2787) for AIDG enrichment
  - REST to Merchant Quality API (id:2788) for scoring
- **Pattern:** Strangler fig — Encore wraps Continuum capabilities rather than rewriting them, gradually taking ownership of business logic. New features are built in Encore; existing functionality is accessed through wrappers until migrated.

## Component Structure

Encore services use a modular (not layered) internal architecture. Example — Deal Service (id:7758, 15 components):

```
API Controllers
├── Base Module
├── Versioning Module
├── AI Module
├── Content Module
├── Media Module
├── Enrichment Module
├── Location Module
├── Pricing Module
├── Performance Module
├── Resolver Module
├── Role Module
├── Collaboration Module
├── Structured Data Module
└── Shared Module
```

Controllers fan out to independent domain modules — flat structure compared to Continuum's layered API > Domain > Data > Integration pattern.

## Source Links

| Document | Link |
|----------|------|
| Groupon Architecture Next (C4 Model) | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82195873828/Groupon+Architecture+Next) |
| Encore Containers | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82243453341/Encore+Containers) |
| Encore Components | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82252398686/Encore+Components) |
| Encore Architecture — High Level | [Encore](https://groupondev.atlassian.net/wiki/spaces/Encore/pages/82181062730/Encore+architecture+-+high+level) |
| Java to TypeScript Encore Onboarding | [Encore](https://groupondev.atlassian.net/wiki/spaces/Encore/pages/81950998562) |
| AIDG Comprehensive Architecture | [MA](https://groupondev.atlassian.net/wiki/spaces/MA/pages/81978359825/AIDG+Platform+-+Comprehensive+Architecture+Document) |
| Structurizr Repository | [GitHub](https://github.com/groupon/architecture) |
