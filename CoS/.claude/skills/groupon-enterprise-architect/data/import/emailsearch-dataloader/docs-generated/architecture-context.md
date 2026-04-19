---
service: "emailsearch-dataloader"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "continuumEmailSearchDataloaderService"
    - "continuumEmailSearchPostgresDb"
    - "continuumDecisionEnginePostgresDb"
    - "continuumCampaignPerformanceMysqlDb"
---

# Architecture Context

## System Context

The Email Search Dataloader sits within the Continuum platform as the statistical decision engine for email and push campaign experiments. It is positioned between raw campaign performance data sources (Campaign Performance Service, Inbox Management Services, Kafka event streams) and the campaign execution system (Campaign Management Service). It reads delivery and engagement events, computes statistical significance for A/B treatment experiments, decides which treatment wins, and commands the Campaign Management Service to roll out the winning treatment. It also feeds the Hive analytics warehouse with experiment outcome data for downstream reporting.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Email Search Dataloader | `continuumEmailSearchDataloaderService` | Service | Java, Dropwizard | 1.0.x | Main application process: processes email event streams, exports metrics, provides API access for campaign performance and notifications |
| Email Search Postgres | `continuumEmailSearchPostgresDb` | Database | PostgreSQL | — | Stores email search operational data and metrics |
| Decision Engine Postgres | `continuumDecisionEnginePostgresDb` | Database | PostgreSQL | — | Stores decision engine data used by campaign decisions |
| Campaign Performance MySQL | `continuumCampaignPerformanceMysqlDb` | Database | MySQL | — | Provides read access to campaign performance data |

## Components by Container

### Email Search Dataloader (`continuumEmailSearchDataloaderService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP API Resources | REST resources for campaign performance queries and health checks | JAX-RS |
| Quartz Schedulers | Scheduled job orchestration for decisions, exports, and unsubscriptions | Quartz |
| Kafka Event Processors | Parses and processes Kafka delivery, bounce, and unsubscribe events | Kafka Consumers |
| Email Search Service | Core business logic for campaign performance evaluation and decisions | Java |
| Metrics Export Service | Exports statistical significance metrics to Hive warehouse | Java |
| Unsubscription Service | Processes subscription changes from Kafka events | Java |
| Bounce Config Service | Maintains bounce configuration and bounce type catalog | Java |
| Notification Service | Posts operational notifications to Slack/GChat channels | Java |
| Hive Query Executor | Executes Hive JDBC queries for reporting and metrics export | Hive JDBC |
| DAO Layer | Persistence access for PostgreSQL (Email Search DB, Decision Engine DB) and MySQL | JDBI |
| Web Clients | HTTP clients for all external and internal downstream services | Retrofit |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumEmailSearchDataloaderService` | `continuumEmailSearchPostgresDb` | Reads/Writes operational data and stat-sig metrics | JDBC |
| `continuumEmailSearchDataloaderService` | `continuumDecisionEnginePostgresDb` | Reads/Writes decision engine state | JDBC |
| `continuumEmailSearchDataloaderService` | `continuumCampaignPerformanceMysqlDb` | Reads campaign performance data | JDBC |
| `continuumEmailSearchDataloaderService` | `hiveWarehouse` | Queries and writes analytics data (stat-sig metrics) | Hive JDBC |
| `continuumEmailSearchDataloaderService` | `continuumCampaignManagementService` | Fetches campaigns and issues rollout commands | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `continuumArbitrationService` | Fetches user cadence data | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `wavefront` | Sends operational metrics | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `externalKafkaCluster_3c9a` | Consumes email delivery, bounce, and unsubscribe events | Kafka |
| `continuumEmailSearchDataloaderService` | `externalCampaignPerformanceService_9f3b` | Requests campaign performance data | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `externalInboxManagementEmailUiService_6a2d` | Fetches email inbox metrics | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `externalInboxManagementPushUiService_63de` | Fetches push inbox metrics | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `externalPhraseeService_1a8c` | Syncs Phrasee/Engage experiment results | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `externalSubscriptionService_f0a4` | Manages user unsubscriptions | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `externalRocketmanCommercialService_7b15` | Fetches gross profit (GP) order data | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `externalSlackWebhook_8ad2` | Sends Slack notifications | HTTP webhook |
| `continuumEmailSearchDataloaderService` | `externalGChatWebhook_91f4` | Sends Google Chat notifications | HTTP webhook |
| `continuumEmailSearchDataloaderService` | `externalElkDataServiceNA_53c0` | Queries NA ELK logging data | REST (Retrofit) |
| `continuumEmailSearchDataloaderService` | `externalElkDataServiceEMEA_7f0a` | Queries EMEA ELK logging data | REST (Retrofit) |

## Architecture Diagram References

- Component: `emailsearch_dataloader_components` (Email Search Dataloader - Component View)

> No system context or container-level diagram views are defined in the local DSL. Cross-system context is represented in the central Continuum workspace.
