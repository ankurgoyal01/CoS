---
service: "consumer-authority"
title: "Attribute Publication"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "attribute-publication"
flow_type: batch
trigger: "Triggered after Spark transformations complete and derived tables are available in the Consumer Authority Warehouse"
participants:
  - "cdeSparkExecutionEngine"
  - "continuumConsumerAuthorityWarehouse"
  - "cdeExternalPublisher"
  - "messageBus"
  - "continuumAudienceManagementService"
  - "cdeAlertingNotifier"
  - "smtpRelay"
architecture_ref: "dynamic-daily-attribute-pipeline"
---

# Attribute Publication

## Summary

The attribute publication flow is the outbound delivery step of the consumer attribute pipeline. After `cdeSparkExecutionEngine` writes computed attribute partitions to the Consumer Authority Warehouse, the External Publisher reads the derived tables, selects the subset of attributes designated for external propagation, publishes consumer-attribute events to the Groupon Message Bus (Kafka) via the Holmes publisher, and posts attribute metadata updates to the Audience Management Service (AMS) HTTP API. This flow runs as the final stage of both the [Daily Attribute Pipeline](daily-attribute-pipeline.md) and the [Backfill Pipeline](backfill-pipeline.md).

## Trigger

- **Type**: event (in-process, triggered by pipeline completion)
- **Source**: `cdeSparkExecutionEngine` signals completion of output partition writes; `cdeJobOrchestrator` invokes `cdeExternalPublisher`
- **Frequency**: Once per pipeline run (daily or backfill)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Spark Execution Engine | Provides computed attribute datasets to the External Publisher after writing output partitions | `cdeSparkExecutionEngine` |
| Consumer Authority Warehouse | Source of derived attribute tables read by the External Publisher | `continuumConsumerAuthorityWarehouse` |
| External Publisher | Reads publishable attributes, sends events to Message Bus, posts metadata to AMS | `cdeExternalPublisher` |
| Message Bus | Receives consumer-attribute events published by the Holmes publisher | `messageBus` |
| Audience Management Service | Receives attribute metadata updates via HTTP API | `continuumAudienceManagementService` |
| Alerting Notifier | Sends publication completion or failure notifications | `cdeAlertingNotifier` |
| SMTP Relay | Delivers operational alert emails | `smtpRelay` |

## Steps

1. **Read derived tables**: External Publisher reads the computed attribute output from the Consumer Authority Warehouse for the completed run date and region.
   - From: `cdeExternalPublisher`
   - To: `continuumConsumerAuthorityWarehouse`
   - Protocol: Hive/HDFS (Spark or direct read)

2. **Select publishable attributes**: External Publisher filters the full attribute set to identify those designated for downstream propagation (e.g., attributes flagged for Holmes/Kafka publishing or AMS metadata updates).
   - From: `cdeExternalPublisher`
   - To: `cdeExternalPublisher` (internal selection logic)
   - Protocol: direct (in-process Scala)

3. **Post events to Holmes/Kafka**: External Publisher serializes the selected consumer attributes and publishes them as consumer-attribute events to the Message Bus via the Holmes publisher.
   - From: `cdeExternalPublisher`
   - To: `messageBus`
   - Protocol: Kafka (Holmes publisher)

4. **Post metadata to AMS**: External Publisher calls the Audience Management Service HTTP API to update the attribute metadata catalog, registering which attributes are available for the completed run date.
   - From: `cdeExternalPublisher`
   - To: `continuumAudienceManagementService`
   - Protocol: HTTP (REST)

5. **Send publication alert**: Alerting Notifier sends an operational notification reporting the publication outcome (success or failure) to configured recipients.
   - From: `cdeAlertingNotifier`
   - To: `smtpRelay`
   - Protocol: SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Derived table read fails | Publication step errors; `cdeAlertingNotifier` fires | Attribute data may be in the warehouse but not propagated; manual re-publish required |
| Holmes/Kafka publish failure | Holmes publisher delivery failure; no automatic retry at pipeline level | Warehouse data is intact; downstream Kafka consumers do not receive signals for this run; re-run publication step or wait for next daily run |
| AMS HTTP push returns non-2xx | Error logged and alert sent; no retry at pipeline level | Message Bus publication may succeed; AMS metadata catalog lags by one run |
| SMTP alert delivery failure | Alert not delivered | Job outcome still recorded in logs and Airflow DAG history |

## Sequence Diagram

```
cdeSparkExecutionEngine    -> cdeExternalPublisher        : Signal completion; provide computed datasets
cdeExternalPublisher       -> continuumConsumerAuthorityWarehouse : Read derived attribute tables
continuumConsumerAuthorityWarehouse --> cdeExternalPublisher : Return attribute data
cdeExternalPublisher       -> cdeExternalPublisher        : Select publishable attributes
cdeExternalPublisher       -> messageBus                  : Publish consumer-attribute events (Kafka/Holmes)
messageBus                 --> cdeExternalPublisher       : Acknowledgement
cdeExternalPublisher       -> continuumAudienceManagementService : POST attribute metadata updates (HTTP)
continuumAudienceManagementService --> cdeExternalPublisher : HTTP 2xx response
cdeExternalPublisher       -> cdeAlertingNotifier         : Report publication outcome
cdeAlertingNotifier        -> smtpRelay                   : Send operational alert
```

## Related

- Architecture dynamic view: `dynamic-daily-attribute-pipeline`
- Related flows: [Daily Attribute Pipeline](daily-attribute-pipeline.md), [Backfill Pipeline](backfill-pipeline.md)
