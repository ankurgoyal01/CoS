---
service: "darwin-groupon-deals"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Relevance / Personalization"
platform: "Continuum"
team: "Relevance Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "2.1.12"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Darwin Aggregator Service Overview

## Purpose

The Darwin Aggregator Service is the central deal aggregation and personalization engine within the Continuum platform. It receives deal search and discovery requests, fans out to a wide set of upstream data sources (catalog, badges, geo, user identity, ML models, and third-party ad networks), and returns a ranked, blended set of deals tailored to the requesting user and context. The service exists to decouple downstream consumers (mobile apps, web frontends) from the complexity of multi-source deal assembly and relevance ranking.

## Scope

### In scope

- Serving synchronous deal search queries via REST (`/v2/deals/search`, `/cards/v1/search`, `/batch/cards/v1/search`, `/v1/deals/local`)
- Asynchronous batch aggregation via Kafka for high-throughput or offline use cases
- Relevance ranking and personalization using ML model artifacts loaded from Watson Object Storage
- Redis response caching for low-latency repeated queries
- A/B experiment management for boosting parameters (`/booster_ab_experiments`)
- Aggregating data from Deal Catalog, Badges, User Identities, Geo Places/Details, Cardatron, Audience User Attributes, Citrus Ads, Targeted Deal Messages, Recently Viewed Deals, and Spell Correction
- Querying Elasticsearch for the deal index

### Out of scope

- Deal creation, modification, or lifecycle management (owned by Deal Catalog)
- Badge definition and assignment (owned by Badges service)
- User identity provisioning (owned by User Identities service)
- Geo data maintenance (owned by Geo Places / Geo Details)
- ML model training and publishing (owned by Relevance ML pipelines)
- Ad campaign management (owned by Citrus Ads)

## Domain Context

- **Business domain**: Relevance / Personalization
- **Platform**: Continuum
- **Upstream consumers**: Mobile apps, web frontend (MBNXT), and any Groupon product surface that renders deal lists or search results
- **Downstream dependencies**: Deal Catalog, Badges, User Identities, Geo Places, Geo Details, Cardatron, Alligator Deck Config, Audience User Attributes, Citrus Ads, Targeted Deal Message, Recently Viewed Deals, Spell Correction, Elasticsearch, Redis, Watson Object Storage, Kafka

## Stakeholders

| Role | Description |
|------|-------------|
| Engineering Owner | Relevance Engineering team (relevance-engineering@groupon.com) |
| Tech Lead | tkuntz |
| Primary Consumers | Product teams building consumer deal discovery surfaces |
| Ops / On-call | Relevance Engineering on-call rotation |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | Service inventory / Dockerfile |
| Framework | Dropwizard | 2.1.12 | pom.xml |
| Runtime | JVM | 17 | Service inventory |
| Build tool | Maven | 3.x | pom.xml |
| Package manager | Maven | | pom.xml |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| dropwizard-kafka | 1.8.3 | message-client | Kafka integration within Dropwizard lifecycle |
| kafka-clients | 3.7.0 | message-client | Low-level Kafka producer/consumer |
| guice | 7.0.0 | http-framework | Dependency injection |
| jedis | 2.9.0 | db-client | Redis client for response caching |
| kryo | 5.6.2 | serialization | High-performance binary serialization for cache payloads |
| jackson-databind | 2.14.0 | serialization | JSON marshalling for REST API |
| logback-classic | 1.4.14 | logging | Structured application logging |
| slf4j-api | 2.0.9 | logging | Logging facade |
| guava | 33.3.1-jre | validation | Collections, caching utilities, preconditions |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
