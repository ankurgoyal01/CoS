# Groupon Architecture Patterns & Standards

> Synthesized from Groupon's C4 architecture model (84 systems, 1,311 containers), platform documentation, and operating principles.
> This is opinionated guidance for new architecture decisions.

---

## Approved Patterns

### Service Design

- **One service, one team, one database.** Encore enforces the OwnsDB pattern — 22 of 23 OwnsDB-tagged containers belong to Encore. Each service gets a dedicated PostgreSQL database. No shared schema access.
- **Encore shared infrastructure.** New services leverage Encore's platform layer: Gateway, Authentication, Authorization, API Tokens, Topics, Audit Log, Websocket, Service Management. Do not rebuild these capabilities.
- **Typed wrappers for Continuum integration.** Encore uses 17 wrapper services (lightweight TypeScript proxies) to access Continuum APIs. This is the strangler fig pattern — wrap first, migrate logic incrementally. Never call Continuum services directly from new business logic; always go through a wrapper.
- **Domain-driven boundaries.** Align service boundaries to Continuum's 11 established domain views: Core Flows, Orders/Payments/Finance, Inventory, Merchant/Partner, Identity/Access, Messaging/Events, Data/Analytics, Online Booking/Travel, Marketing/Ads/Reporting, Supply, and MBNXT surfaces. New Encore services should map to one of these domains.
- **Modular over layered.** Encore uses flat modular decomposition (API controllers fan out to independent domain modules) rather than Continuum's deep layered architecture (controllers to managers to accessors to clients). Prefer Encore's pattern for new services.

### Communication

- **Event-driven by default.** Use Encore Topics (platform-managed PubSub) for async communication between Encore services. Use Kafka for Continuum-to-Encore integration and high-throughput streaming (Janus pipeline, CDC).
- **REST for external, Encore RPC for internal.** External APIs use REST. Internal Encore-to-Encore calls use typed Encore.api RPC endpoints. Continuum internal calls use REST (Rails controllers, RESTEasy servlets).
- **No synchronous chains deeper than 3 hops.** Continuum's API Proxy filter chain (14 filters) and Lazlo SOX aggregator (30+ downstream clients) show what happens when sync chains grow unchecked. New designs must limit sync call depth.
- **Unidirectional migration flow.** Encore depends on Continuum; Continuum does not depend on Encore. Maintain this one-way dependency during migration.

### Data

- **PostgreSQL for Encore services.** Cloud SQL with private IP only, service-owned. No shared databases.
- **MySQL for Continuum.** Existing shared MySQL clusters. Maintenance only — no new shared schemas.
- **BigQuery for analytics.** Replacing Teradata (marked ToDecommission). All new analytical workloads target BigQuery.
- **Redis with explicit TTL.** Groupon has 30+ cache elements across services (rate limiting, inventory cache, OTP codes, sessions). Always set explicit TTLs. Never use Redis as a primary database.
- **Keboola for ETL.** Cloud ETL platform replacing legacy Spark/Hadoop pipelines. New data integration uses Keboola, not custom Spark jobs.
- **OpenMetadata for data catalog.** Data catalog v2 for discovery and governance.

### Deployment

- **GCP Cloud Run.** Default compute for all new services. Do not use GKE unless Cloud Run is technically insufficient (long-running workers, GPU workloads).
- **Multi-region minimum.** us-central1 (primary) + europe-west1 (EMEA). Continuum also runs in us-west, legacy DCs (snc1, dub1), and AWS eu-west-1 — consolidate toward GCP.
- **Direct VPC Egress.** Encore uses Direct VPC Egress on Cloud Run for private network access to Cloud SQL and internal services.
- **Shared VPC networking.** Private IPs throughout. Custom VPC setup coordinated with Encore Dev team.

### Observability

- **Datadog** for metrics, logs, and APM.
- **Structurizr-as-code** for C4 architecture diagrams, maintained in `github.com/groupon/architecture`, auto-published to Confluence daily.

---

## Anti-Patterns (Do Not Introduce)

- **New services on the Continuum stack without a migration plan.** Continuum is maintain-only (1,164 containers, 89% of all containers). New business logic goes on Encore.
- **New AWS resources.** GCP-first. Consolidate existing AWS (eu-west-1, Strimzi/Conveyor Kafka) toward GCP.
- **New Teradata dependencies.** Teradata is marked ToDecommission. Use BigQuery.
- **Direct cross-boundary database access.** Services must own their data. No reading another service's database directly.
- **Shared database ownership.** One service, one database. Continuum's shared MySQL pattern is legacy debt, not a model.
- **Feature flags without cleanup timeline.** Groupon has 4 separate feature flag systems (Birdcage, Setting model, Config-based JSON, countryFeatures.json). Every new flag needs a removal date.
- **GKE when Cloud Run suffices.** Cloud Run is the default. GKE only for workloads that genuinely require Kubernetes.
- **New languages beyond the approved set.** TypeScript and Go for Encore. Java and Ruby for Continuum maintenance only. No new Scala, Python, or other languages for services.
- **Shared ownership or unclear domain boundaries.** Every service has one owning team. Map to one of the 11 Continuum domain views or a defined Encore domain.

---

## Decision Record Template (ADR)

Use this template for all architecture decisions. Store in the architecture repo or team wiki.

```markdown
# ADR-NNNN: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

## Context
What is the issue? What forces are at play? Why does this decision need to be made now?

## Options Considered
1. **Option A** — Description. Pros/cons.
2. **Option B** — Description. Pros/cons.
3. **Option C** — Description. Pros/cons.

## Decision
We will use [Option X] because [reasoning].

## Consequences
- **Positive:** [What improves]
- **Negative:** [What trade-offs we accept]
- **Risks:** [What could go wrong]

## Principles Applied
- [ ] Extreme Ownership — Clear single owner identified
- [ ] Speed Over Comfort — Can ship MVP within [timeframe]
- [ ] Impact Obsessed — Directly improves [metric]
- [ ] Simplify to Scale — Simplest viable approach chosen
- [ ] Disciplined — Uses existing infrastructure where possible
```

---

## Technology Philosophy: Continuum vs Encore

| Aspect | Continuum (Legacy) | Encore (Strategic) |
|--------|-------------------|-------------------|
| **Languages** | Java, Ruby, Scala, Python, Go (organic growth) | TypeScript (primary), Go (relevance/cloud) |
| **Framework** | Mixed: Rails, Vert.x, Spring, RESTEasy, Sinatra | Encore.ts throughout |
| **Database** | MySQL (shared), plus Cassandra, Hive, HDFS, Bigtable, ElasticSearch | PostgreSQL (service-owned exclusively) |
| **Messaging** | ActiveMQ Artemis + Kafka (infrastructure-heavy) | Encore Topics (platform-managed PubSub) |
| **Integration** | Direct HTTP clients between services | Typed wrappers abstract Continuum; RPC between Encore services |
| **AI/ML** | GenAI Service, ML Toolkit, DeepScout | AI Gateways, AI Agents, AI Common Management, AIDG, MCP Server |
| **Batch** | Quartz, Spark, rake tasks | Temporal workflows |
| **Architecture** | Layered (controllers to managers to accessors to clients) | Modular (controllers fan out to independent domain modules) |
| **Scale** | 1,164 containers, 317 tagged elements | 134 containers, growing |
| **Direction** | **Maintain** — fix bugs, keep running | **Grow** — all new business logic here |

**Migration strategy:** Strangler fig via typed wrappers. Encore wraps Continuum capabilities rather than rewriting them, gradually owning more business logic. Traffic flows one direction (Encore to Continuum). Continuum has zero dependencies on Encore.
