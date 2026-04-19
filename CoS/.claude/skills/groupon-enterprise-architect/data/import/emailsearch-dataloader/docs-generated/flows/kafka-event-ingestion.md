---
service: "emailsearch-dataloader"
title: "Kafka Event Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "kafka-event-ingestion"
flow_type: event-driven
trigger: "Email delivery, bounce, or unsubscribe event arrives on Kafka cluster"
participants:
  - "externalKafkaCluster_3c9a"
  - "continuumEmailSearchDataloaderService"
  - "continuumEmailSearchPostgresDb"
  - "externalSubscriptionService_f0a4"
architecture_ref: "emailsearch_dataloader_components"
---

# Kafka Event Ingestion

## Summary

The Kafka Event Ingestion flow is the primary inbound data pipeline for the Email Search Dataloader. The `kafkaEventProcessors` component continuously consumes events from the Groupon Kafka cluster (connected via mTLS). Three event types are processed: delivery events update campaign performance state in PostgreSQL, bounce events update bounce configuration, and unsubscribe events trigger unsubscription via the Subscription Service. This flow is the source of all campaign engagement data that feeds into the Campaign Decision Job.

## Trigger

- **Type**: event
- **Source**: Email platform publishes delivery, bounce, and unsubscribe events to the Kafka cluster (`externalKafkaCluster_3c9a`)
- **Frequency**: Continuous / real-time; events arrive as email campaigns are delivered

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Cluster | Event source — delivers email events | `externalKafkaCluster_3c9a` |
| Kafka Event Processors | Consumes and routes events to appropriate handlers | `continuumEmailSearchDataloaderService` |
| Email Search Service | Processes delivery events; updates performance state | `continuumEmailSearchDataloaderService` |
| Unsubscription Service | Handles unsubscribe event processing | `continuumEmailSearchDataloaderService` |
| Bounce Config Service | Handles bounce event processing | `continuumEmailSearchDataloaderService` |
| DAO Layer | Reads/writes event state to PostgreSQL | `continuumEmailSearchDataloaderService` |
| Email Search Postgres | Stores updated campaign performance data | `continuumEmailSearchPostgresDb` |
| Subscription Service | Receives unsubscription commands | `externalSubscriptionService_f0a4` |

## Steps

1. **Consume event from Kafka**: The `kafkaEventProcessors` component polls the Kafka cluster for new messages. TLS credentials are established at startup via `kafka-tls-v2.sh`. The consumer uses `kafka-clients` 3.1.0 with `kafka-message-serde` for deserialization. The Kafka broker address is set via `KAFKA_ENDPOINT`.
   - From: `externalKafkaCluster_3c9a`
   - To: `kafkaEventProcessors`
   - Protocol: Kafka (mTLS)

2. **Deserialize and parse event**: The `kafkaEventProcessors` applies the configured `ParserConfig` (list of parsers, each with a field separator and index) from the runtime YAML to extract structured event data from the raw Kafka message payload.
   - From: `kafkaEventProcessors` (in-process)
   - To: parsed event model
   - Protocol: in-process

3a. **Route delivery event to Email Search Service**: For delivery events (clicks, opens, sends), `kafkaEventProcessors` routes to `emailSearchService`, which updates the campaign performance counters for the relevant campaign send ID.
   - From: `kafkaEventProcessors`
   - To: `emailSearchService`
   - Protocol: in-process

3b. **Route unsubscribe event to Unsubscription Service**: For unsubscribe events, `kafkaEventProcessors` routes to `unsubscriptionService`.
   - From: `kafkaEventProcessors`
   - To: `unsubscriptionService`
   - Protocol: in-process

3c. **Route bounce event to Bounce Config Service**: For bounce events, `kafkaEventProcessors` routes to `bounceConfigService`, which updates bounce type configuration data.
   - From: `kafkaEventProcessors`
   - To: `bounceConfigService`
   - Protocol: in-process

4a. **Persist delivery event to Postgres**: `emailSearchService` writes updated performance metrics (click, open, send, push counts) to `continuumEmailSearchPostgresDb` via `daoLayer_EmaDat`.
   - From: `emailSearchService` / `daoLayer_EmaDat`
   - To: `continuumEmailSearchPostgresDb`
   - Protocol: JDBC

4b. **Issue unsubscription command**: `unsubscriptionService` calls the external Subscription Service via the Retrofit client to record the user unsubscription. It also updates the local state in `continuumEmailSearchPostgresDb`.
   - From: `unsubscriptionService` / `webClients`
   - To: `externalSubscriptionService_f0a4`
   - Protocol: REST (Retrofit)

4c. **Persist bounce configuration**: `bounceConfigService` writes updated bounce type data to `continuumEmailSearchPostgresDb` via `daoLayer_EmaDat`.
   - From: `bounceConfigService` / `daoLayer_EmaDat`
   - To: `continuumEmailSearchPostgresDb`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka connection failure | Pod fails health checks; Kubernetes restarts pod | Event consumption resumes after reconnect |
| TLS certificate expiry | Container startup fails; `kafka-tls-v2.sh` cannot configure keystore | Deployment fails; alert required |
| Message deserialization failure | Not documented in codebase | Dependent on Kafka consumer error configuration |
| Subscription Service unavailable | Not documented in codebase; Retrofit exception | Unsubscription not processed; Kafka offset may not be committed |
| Postgres write failure | Not documented in codebase | Event data loss possible if offset is committed before write confirmation |

## Sequence Diagram

```
KafkaCluster -> KafkaEventProcessors: poll() -> message batch
KafkaEventProcessors -> KafkaEventProcessors: deserialize(ParserConfig)
KafkaEventProcessors -> EmailSearchService: processDeliveryEvent(event) [delivery]
EmailSearchService -> DaoLayer: updatePerformanceCounters(campaignSendId, metrics)
DaoLayer -> EmailSearchPostgres: INSERT/UPDATE [JDBC]
KafkaEventProcessors -> UnsubscriptionService: processUnsubscribeEvent(event) [unsubscribe]
UnsubscriptionService -> SubscriptionService: unsubscribe(user) [REST]
UnsubscriptionService -> DaoLayer: updateUnsubscribeState() [JDBC]
DaoLayer -> EmailSearchPostgres: INSERT/UPDATE [JDBC]
KafkaEventProcessors -> BounceConfigService: processBounceEvent(event) [bounce]
BounceConfigService -> DaoLayer: updateBounceConfig(bounceType)
DaoLayer -> EmailSearchPostgres: INSERT/UPDATE [JDBC]
```

## Related

- Architecture component view: `emailsearch_dataloader_components`
- Related flows: [Campaign Decision Job](campaign-decision-job.md)
