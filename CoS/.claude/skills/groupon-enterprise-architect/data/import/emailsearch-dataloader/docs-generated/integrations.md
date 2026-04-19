---
service: "emailsearch-dataloader"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 9
internal_count: 2
---

# Integrations

## Overview

The Email Search Dataloader has a wide integration footprint with 11 downstream dependencies: 2 internal Continuum services and 9 external services. All HTTP integrations use Retrofit clients configured via JTier's `RetrofitConfiguration`. Kafka integration uses the Apache Kafka client with mutual TLS. Most HTTP dependencies are configured with separate `RetrofitConfiguration` instances, allowing independent timeout and base URL settings per service. The `resilience4j-retry` library provides retry capability for HTTP calls.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka Cluster | Kafka (TLS) | Consumes email delivery, bounce, and unsubscribe events | yes | `externalKafkaCluster_3c9a` |
| Campaign Performance Service | REST (Retrofit) | Retrieves per-treatment campaign performance metrics (clicks, opens, sends) | yes | `externalCampaignPerformanceService_9f3b` |
| Inbox Management Email UI Service | REST (Retrofit) | Fetches email inbox accepted count for significance threshold calculation | yes | `externalInboxManagementEmailUiService_6a2d` |
| Inbox Management Push UI Service | REST (Retrofit) | Fetches push inbox accepted count for significance threshold calculation | yes | `externalInboxManagementPushUiService_63de` |
| Phrasee Service | REST (Retrofit) | Uploads Engage/Phrasee campaign performance results | no | `externalPhraseeService_1a8c` |
| Subscription Service | REST (Retrofit) | Processes user unsubscription requests triggered by Kafka events | no | `externalSubscriptionService_f0a4` |
| Rocketman Commercial Service | REST (Retrofit) | Fetches order gross profit (GP) data per UTM campaign | no | `externalRocketmanCommercialService_7b15` |
| Slack Webhook | HTTP webhook | Sends operational and decision notifications | no | `externalSlackWebhook_8ad2` |
| Google Chat Webhook | HTTP webhook | Sends operational and decision notifications | no | `externalGChatWebhook_91f4` |
| ELK Data Service NA | REST (Retrofit) | Queries NA region ELK logging data | no | `externalElkDataServiceNA_53c0` |
| ELK Data Service EMEA | REST (Retrofit) | Queries EMEA region ELK logging data | no | `externalElkDataServiceEMEA_7f0a` |
| Wavefront | REST (Retrofit) | Sends operational metrics and counters | no | `wavefront` |
| Hive Warehouse | Hive JDBC | Reads/writes analytics tables for metrics export | yes | `hiveWarehouse` |

### Kafka Cluster Detail

- **Protocol**: Kafka with mutual TLS (mTLS)
- **Base URL / SDK**: `kafka-clients` 3.1.0; broker endpoint via `KAFKA_ENDPOINT` env var (e.g., `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093`)
- **Auth**: Mutual TLS; certificates mounted from Kubernetes secret `emailsearch-dataloader-staging-tls-identity` (staging); configured by `kafka-tls-v2.sh` at startup
- **Purpose**: Source of email delivery, bounce, and unsubscribe event streams that drive campaign performance state
- **Failure mode**: If Kafka is unavailable, event consumption stops; campaign performance data becomes stale; decision jobs may produce incorrect or no rollout decisions
- **Circuit breaker**: No evidence found in codebase

### Campaign Performance Service Detail

- **Protocol**: REST (Retrofit)
- **Base URL / SDK**: Configured via `campaignPerformanceServiceClient` `RetrofitConfiguration` in runtime YAML
- **Auth**: Not documented in codebase
- **Purpose**: Provides per-treatment click, open, send, and push metrics used in statistical significance evaluation during `DecisionJob` and `EngageUploadJob`
- **Failure mode**: If unavailable, the decision task fails with a `CompletionException`; `METRIC_MISSING_CP_METRICS_COUNT` counter is incremented
- **Circuit breaker**: No evidence found in codebase; `resilience4j-retry` available

### Inbox Management Services Detail

- **Protocol**: REST (Retrofit)
- **Auth**: Not documented in codebase
- **Purpose**: Provides accepted send counts per campaign send ID, used to calculate dynamic statistical significance thresholds based on treatment bucket size
- **Failure mode**: Returns `Optional.empty()` on error (logged, counter incremented via `METRIC_MISSING_IM_METRICS_COUNT`); service falls back to default 95% significance threshold
- **Circuit breaker**: No evidence found in codebase

### Campaign Management Service Detail

- **Protocol**: REST (Retrofit)
- **Auth**: Not documented in codebase
- **Purpose**: Fetches the list of APPROVED campaigns for each decision/upload job run; receives rollout commands (`rolloutTemplateTreatment`) when a winning treatment is determined
- **Failure mode**: If unavailable, the decision job cannot fetch campaigns or issue rollouts; `CompletionException` is thrown and logged
- **Circuit breaker**: No evidence found in codebase

### Hive Warehouse Detail

- **Protocol**: Hive JDBC (`org.apache.hive.jdbc.HiveDriver`)
- **Base URL / SDK**: `hive-jdbc` 2.0.0; JDBC URL configured via `hive.jdbcUrl` in runtime YAML
- **Auth**: Username configured via `hive.user`; password not in source
- **Purpose**: Analytics export target; receives incremental batches of `campaign_stat_sig_metrics` data
- **Failure mode**: If unavailable, `MetricsExportJob` fails; metrics export is delayed until next scheduled run
- **Circuit breaker**: No evidence found in codebase; HikariCP connection pool with configurable `connectionTimeout` (default 30 seconds)

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Campaign Management Service | REST (Retrofit) | Fetches and updates campaigns | `continuumCampaignManagementService` |
| Arbitration Service | REST (Retrofit) | Fetches user cadence data | `continuumArbitrationService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The REST API (`/campaign_performance/{utm_campaign}` and `/campaign_performances`) is consumed by internal Rocketman platform services for campaign performance lookups.

## Dependency Health

- **Retry**: `resilience4j-retry` (version 1.7.1) is available as a library dependency; specific retry policies per client are defined in runtime configuration
- **Inbox Management**: Explicitly degrades gracefully — if IM call fails, defaults to a fixed 95% significance threshold rather than failing the entire decision task
- **Kafka TLS**: Certificates are mounted as Kubernetes secrets and configured at container startup via `kafka-tls-v2.sh`; if certificates are missing, the service will fail to start
- **HikariCP**: Hive connection pool uses configurable pool size (default 10) and connection timeout (default 30 seconds)
