---
service: "regla"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [reglaService, reglaStreamJob, reglaPostgresDb, reglaRedisCache]
---

# Architecture Context

## System Context

regla sits within the Continuum platform's Emerging Channels domain. It acts as the central decision layer for inbox management: rule authors configure rules via a REST API, the stream job continuously evaluates purchase and browse events against those rules, and when conditions are met, regla triggers downstream action services (push notifications, email campaigns, incentives). It depends on the Taxonomy Service for category hierarchy resolution and on Redis for low-latency rule evaluation state.

> No architecture/ folder exists for regla in the federated model. Containers and relationships below are derived from the inventory.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| regla Service | `reglaService` | API service | Java / Play Framework | Play 2.5 / JDK 1.8 | Handles HTTP API for rule CRUD, approval workflow, query evaluation, and action dispatch |
| regla Stream Job | `reglaStreamJob` | Stream processor | Scala / Kafka Streams (Spark) | Kafka Streams 2.8.2 / Scala 2.11.8 | Processes deal-purchase and browse event streams; evaluates rules at scale; publishes results to Kafka topics |
| regla PostgreSQL | `reglaPostgresDb` | Database | PostgreSQL | — | Primary relational store for rules, rule instances, rule actions, executions, users, and purchase records |
| regla Redis Cache | `reglaRedisCache` | Cache | Redis | — | Caches purchase history, rule evaluation state, and taxonomy data for low-latency queries |

## Components by Container

### regla Service (`reglaService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Rule management API | Handles GET/POST/PUT for rule CRUD, approval, rejection, deactivation | Play Framework routes |
| Rule instance registration | Handles `POST /ruleInstance/registerRuleEvents` to bind events to rule instances | Play Framework |
| Rule evaluation query handler | Serves `GET /userHasDealPurchaseSince`, `GET /userHasAnyPurchaseEver` | Play Framework |
| Category tree resolver | Serves `GET /categoryInCategoryTree` using Taxonomy Service and Redis cache | Play Framework |
| Rule action executor | Dispatches actions to Rocketman, Email Campaign, Incentive Service when rules fire | commons-httpclient |
| Health/status router | Serves health and status endpoints | Play Framework |

### regla Stream Job (`reglaStreamJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Event stream consumer | Consumes deal-purchase and browse events from Kafka topics | kafka-streams 2.8.2 |
| Rule evaluation engine | Evaluates active rules against event data and purchase history | Scala / kafka-streams |
| Delayed instance publisher | Publishes delayed rule instance results to `im_push_regla_delayed_instances_spark` | kafka-0.8-thin-client |
| Janus tier-2 publisher | Publishes rule evaluation results to `janus-tier2` Kafka topic | kafka-0.8-thin-client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `reglaService` | `reglaPostgresDb` | Reads and writes rule definitions, instances, actions, executions | JDBC / PostgreSQL |
| `reglaService` | `reglaRedisCache` | Reads/writes purchase history cache and rule evaluation state | Redis (jedis) |
| `reglaStreamJob` | `reglaPostgresDb` | Reads active rules and writes execution records | JDBC / PostgreSQL |
| `reglaStreamJob` | `reglaRedisCache` | Reads/writes rule state and taxonomy cache during stream processing | Redis (jedis) |
| `reglaService` | Taxonomy Service v2 | Resolves category hierarchy for rule conditions | HTTP (commons-httpclient) |
| `reglaService` | Rocketman v2 | Dispatches push notification actions when rules fire | HTTP |
| `reglaService` | Email Campaign | Dispatches email campaign actions when rules fire | HTTP |
| `reglaService` | Incentive Service | Dispatches incentive grants when rules fire | HTTP |
| `reglaStreamJob` | Kafka | Consumes event streams; publishes evaluation results | Kafka |

## Architecture Diagram References

> No architecture/ folder exists for regla in the federated model. No Structurizr diagram references available.

- System context: `contexts-regla` (not yet defined in federated model)
- Container: `containers-regla` (not yet defined in federated model)
- Component: `components-regla` (not yet defined in federated model)
