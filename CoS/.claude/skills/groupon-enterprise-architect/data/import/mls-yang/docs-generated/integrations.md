---
service: "mls-yang"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 3
---

# Integrations

## Overview

mls-yang integrates with five external or platform-level systems. Three are data sources consumed by the batch subsystem: Janus/Hive (deal engagement metrics), Cerebro Hive (risk/refund rate data), and the Deal Catalog service (permalink-to-UUID resolution). Two are messaging infrastructure: Kafka (command ingestion) and the Groupon Message Bus (batch feedback publication). All database connections are treated as internal infrastructure managed by DaaS.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Kafka | Kafka (SSL) | Consume all MLS command topics for read-model projection | yes | `messageBus` |
| Groupon Message Bus | JMS (Message Bus) | Publish batch feedback commands on job completion | no | `messageBus` |
| Deal Catalog | REST (HTTP) | Resolve deal permalink strings to deal UUIDs for metrics import | yes (for batch imports) | `continuumDealCatalogService` |
| Janus / Hive (gdoop) | JDBC / Hive2 | Source of deal engagement metrics (clicks, impressions, shares) | yes (for batch imports) | external |
| Cerebro Hive | JDBC / Hive2 | Source of merchant risk and refund rate data | no | external |

### Kafka Detail

- **Protocol**: Kafka consumer (SSL), `kafka-clients` v0.10.2.1
- **Bootstrap servers (production)**: `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093`
- **Consumer group**: `mls_yang-prod-snc1`
- **Auth**: SSL mutual TLS — keystore at `/var/groupon/jtier/kafka.client.keystore.jks`, truststore at `/var/groupon/jtier/truststore.jks`
- **Purpose**: Primary data input — all merchant lifecycle state changes arrive as Kafka command messages across nine topics
- **Failure mode**: Consumer lag builds; Quartz batch jobs continue independently; `auto.offset.reset: earliest` ensures no message loss on restart

### Groupon Message Bus Detail

- **Protocol**: JMS via `groupon messagebus` client (`ProducerImpl`)
- **Destination**: `jms.queue.mls.batchCommands`
- **Host (production)**: `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com`
- **Auth**: Internal service credentials (managed by jtier)
- **Purpose**: Notify downstream MLS components that a batch import or retention job has completed
- **Failure mode**: Feedback command is lost for the batch run; jobs continue to execute on schedule regardless

### Deal Catalog Detail

- **Protocol**: REST (HTTP) via `DealCatalogClient` (Retrofit-based)
- **Base URL (production)**: `http://deal-catalog.production.service`
- **Base URL (staging)**: `http://deal-catalog-staging.snc1`
- **Auth**: Client ID parameter (`clientId`); value from `DC_CLIENT_ID` env var in production
- **Purpose**: Translate deal permalink strings (from Janus query results) to canonical deal UUIDs for persisting deal metrics
- **Failure mode**: HTTP 5xx triggers retry with delay (`maxRetries: 6`, `retryDelayInMillis: 1000`); 4xx results in skipping the permalink; batch import continues for other deals
- **Circuit breaker**: Retry-with-delay pattern (`RetryWithDelay`); no explicit circuit breaker framework
- **Cache**: Guava in-memory cache (`permalinkToDealUUIDCache`) — 500,000 entries, 1-day expire-after-access — reduces repeat calls per run

### Janus / Hive (gdoop) Detail

- **Protocol**: JDBC via HiveDriver (`org.apache.hive.jdbc.HiveDriver`)
- **URL (production)**: `jdbc:hive2://analytics.data-comp.prod.gcp.groupondev.com:8443/default;ssl=true;transportMode=http;httpPath=gateway/pipelines-adhoc-query/hive`
- **User**: `svc_mx_merchant` (password from `GDOOP_HIVE_PASSWORD` env var)
- **Table**: `grp_gdoop_pde.junohourly` (production)
- **Purpose**: Source deal engagement metrics — shares, email clicks, email impressions, web/mobile clicks, web/mobile impressions, merchant website referrals — queried per event date
- **Failure mode**: Batch job fails for the affected run; Quartz misfire threshold (300,000ms) governs retry scheduling
- **Connection pool**: `minSize: 8`, `maxSize: 32`

### Cerebro Hive Detail

- **Protocol**: JDBC via HiveDriver
- **URL (production)**: `jdbc:hive2://analytics.data-comp.prod.gcp.groupondev.com:8443/default;ssl=true;transportMode=http;httpPath=gateway/analytics-adhoc-query/hive`
- **User**: `svc_mx_merchant` (password from `CEREBRO_HIVE_PASSWORD` env var)
- **Purpose**: Source merchant refund rate data for risk import (`RefundRateImportExecutor`)
- **Failure mode**: Refund rate import job fails; no impact on Kafka ingestion or other batch jobs
- **Connection pool**: `minSize: 0`, `maxSize: 14`

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DaaS PostgreSQL | JDBC/JDBI | All four PostgreSQL databases (yangDb, rinDb, historyDb, dealIndexDb) | `mlsYangDb`, `mlsYangRinDb`, `mlsYangHistoryDb`, `mlsYangDealIndexDb` |
| mls-sentinel | Internal (referenced in `.service.yml`) | MLS sentinel/coordination service | external |
| mls-commons | Library (in-process) | Shared MLS command/payload types, Kafka utilities | `mls-commons` artifact |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Yang REST API is consumed by internal MLS tooling and analytics services that need to query projected merchant state. The Yang PostgreSQL databases are consumed by read-side query services within the MLS platform.

## Dependency Health

- **Kafka**: Consumer group lag is the primary health indicator. SSL mutual TLS means certificate expiry is a potential failure mode.
- **Deal Catalog**: Health checked implicitly via retry logic on batch import runs; 500ms-1s retry delay with up to 6 retries before skipping a permalink.
- **Hive sources**: Connection validity checked on borrow (`checkConnectionOnBorrow: true`). Pool eviction is configured with a 10-second interval.
- **Databases**: DaaS-managed pools with session and transaction ports; connection pool names (`yang-rw`, `mls_lifecycle-rw`, `history-rw`, `mls_dealindex-ro`) allow pool-level monitoring.
