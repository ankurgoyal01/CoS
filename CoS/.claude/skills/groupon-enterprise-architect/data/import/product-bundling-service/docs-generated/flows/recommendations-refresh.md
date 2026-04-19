---
service: "product-bundling-service"
title: "Recommendations Refresh"
generated: "2026-03-03"
type: flow
flow_name: "recommendations-refresh"
flow_type: scheduled
trigger: "Quartz cron (daily per recommendation type) or manual POST /v1/bundles/refresh/{refreshType}"
participants:
  - "pbsRecommendationJobOrchestrator"
  - "pbsHdfsAdapter"
  - "pbsFluxAdapter"
  - "pbsKafkaPublisher"
architecture_ref: "dynamic-pbs-recommendations-refresh"
---

# Recommendations Refresh

## Summary

The Recommendations Refresh flow is a scheduled batch job that produces up-to-date ML-driven recommendation bundle payloads for Groupon's commerce surfaces. It reads the latest recommendation input file from HDFS (Cerebro), creates a Flux scoring run and polls for completion, reads the Flux output file from HDFS (Gdoop), transforms the scored results into recommendation payloads, and publishes them to Watson KV Kafka for downstream consumption. The flow runs daily for each of the four recommendation types.

## Trigger

- **Type**: schedule (also supports manual trigger)
- **Source**: Quartz scheduler (`BundlesRefreshScheduler`) — four named triggers, one per recommendation type. Also triggerable on demand via `POST /v1/bundles/refresh/{refreshType}`.
- **Frequency**: Daily per recommendation type

| Trigger Name | Recommendation Type | Cron (dev) |
|---|---|---|
| `customer_also_bought` | `customer_also_bought` | `0 26 08 * * ?` |
| `customer_also_bought_2` | `customer_also_bought` (secondary run) | `0 26 06 * * ?` |
| `customer_also_viewed` | `customer_also_viewed` | `0 33 08 * * ?` |
| `sponsored_similar_item` | `sponsored_similar_item` | `0 30 09 * * ?` |

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Recommendation Job Orchestrator | Quartz job entry point; orchestrates all steps of the refresh | `pbsRecommendationJobOrchestrator` |
| HDFS Adapter | Reads recommendation input files from Cerebro HDFS; reads Flux output files from Gdoop HDFS | `pbsHdfsAdapter` |
| Flux Adapter | Creates Flux scoring run via HTTP; polls Flux run status until completion | `pbsFluxAdapter` |
| Kafka Publisher | Publishes recommendation event payloads to Watson KV Kafka | `pbsKafkaPublisher` |

## Steps

1. **Resolve latest recommendation input file from Cerebro HDFS**: Recommendation Job Orchestrator instructs HDFS Adapter to locate the most recent input data file for the given recommendation type on the Cerebro HDFS cluster. The input file path/header schema is configured via `hadoopInputClient` and `inputHeader` config.
   - From: `pbsRecommendationJobOrchestrator`
   - To: `pbsHdfsAdapter`
   - Protocol: HDFS (Hadoop client 2.8.1)

2. **Create Flux run**: Recommendation Job Orchestrator instructs Flux Adapter to create a new Flux scoring run by POSTing to the Flux API with the input file reference and the configured `fluxModelId` for the recommendation type.
   - From: `pbsRecommendationJobOrchestrator`
   - To: `pbsFluxAdapter`
   - Protocol: HTTP/JSON

3. **Poll Flux run status**: Flux Adapter polls the Flux API for run completion status at `pollingInterval` milliseconds intervals, up to `pollingLimit` attempts.
   - From: `pbsRecommendationJobOrchestrator`
   - To: `pbsFluxAdapter`
   - Protocol: HTTP/JSON

4. **Load Flux output from Gdoop HDFS**: Once the Flux run completes, Recommendation Job Orchestrator instructs HDFS Adapter to read the Flux output file from the Gdoop HDFS cluster and transform the scored records into recommendation payloads.
   - From: `pbsRecommendationJobOrchestrator`
   - To: `pbsHdfsAdapter`
   - Protocol: HDFS (Hadoop client 2.8.1)

5. **Stream parsed recommendation results to Kafka Publisher**: HDFS Adapter passes the parsed recommendation payload records to the Kafka Publisher component for publishing.
   - From: `pbsHdfsAdapter`
   - To: `pbsKafkaPublisher`
   - Protocol: Direct

6. **Publish recommendation events to Watson KV Kafka**: Kafka Publisher emits recommendation payload events to the configured Watson KV Kafka topic using the `holmes:kv-producer` library.
   - From: `pbsRecommendationJobOrchestrator` / `pbsKafkaPublisher`
   - To: Watson KV Kafka
   - Protocol: Kafka (kafka-clients 0.11.0.1)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cerebro HDFS input file not found | Job fails with exception; logged | No Flux run created; no Kafka events published; existing recommendation data unchanged |
| Flux API unavailable | Job fails with exception after timeout | No scoring run started; no Kafka events published |
| Flux run times out (exceeds pollingLimit) | Job fails with exception | Scoring incomplete; no Kafka events published |
| Gdoop HDFS output file not found after Flux completes | Job fails with exception | Scoring done but no payloads published |
| Kafka publish failure | Exception logged per record; partial publish possible | Some recommendation events may not reach consumers |
| Manual refresh with invalid refreshType | Returns HTTP 400 from `POST /v1/bundles/refresh/{refreshType}` | Job not started |

## Sequence Diagram

```
Quartz/Caller -> pbsRecommendationJobOrchestrator: Trigger recommendations refresh (refreshType)
pbsRecommendationJobOrchestrator -> pbsHdfsAdapter: Resolve latest recommendation input file from Cerebro
pbsHdfsAdapter --> pbsRecommendationJobOrchestrator: Input file path/reference
pbsRecommendationJobOrchestrator -> pbsFluxAdapter: Create Flux run (model ID, input reference)
pbsFluxAdapter -> FluxAPI: POST /flux/runs
pbsFluxAdapter -> FluxAPI: GET /flux/runs/{runId} (poll until complete)
pbsFluxAdapter --> pbsRecommendationJobOrchestrator: Run complete, output reference
pbsRecommendationJobOrchestrator -> pbsHdfsAdapter: Load Flux output and transform payloads
pbsHdfsAdapter -> pbsKafkaPublisher: Emit recommendation payloads
pbsRecommendationJobOrchestrator -> pbsKafkaPublisher: Publish recommendation events
pbsKafkaPublisher -> WatsonKVKafka: Produce recommendation events
```

## Related

- Architecture dynamic view: `dynamic-pbs-recommendations-refresh`
- Related flows: [Warranty Refresh](warranty-refresh.md)
- See [Configuration](../configuration.md) for Quartz cron expressions and Flux/HDFS client settings
