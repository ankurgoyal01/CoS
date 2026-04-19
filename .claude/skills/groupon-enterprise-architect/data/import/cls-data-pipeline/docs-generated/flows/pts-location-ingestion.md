---
service: "cls-data-pipeline"
title: "PTS Location Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "pts-location-ingestion"
flow_type: event-driven
trigger: "Kafka event on mobile_notifications topic"
participants:
  - "ptsService"
  - "kafkaPlatform"
  - "continuumClsDataPipelineService"
  - "continuumClsRealtimeHive"
architecture_ref: "dynamic-clsDataPipeline"
---

# PTS Location Ingestion

## Summary

This flow processes consumer location events emitted by the Push Token Service (PTS). PTS publishes device token lifecycle events to the `mobile_notifications` Kafka topic; the CLS pipeline subscribes to this topic in both NA (`kafka-aggregate.snc1:9092`) and EMEA (`kafka.dub1:9092`) separately. Each 60-second micro-batch is decoded from the Loggernaut binary format, filtered to only location-bearing token events, normalized into a flat JSON structure, and inserted into a partitioned Hive history table. When Kafka output is enabled, normalized records are also published to `cls_coalesce_pts_na`.

## Trigger

- **Type**: event (Kafka message arrival)
- **Source**: Push Token Service publishes to `mobile_notifications`
- **Frequency**: Continuous; processed in 60-second micro-batch intervals per `--batch_interval 60`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Push Token Service | Upstream producer of `mobile_notifications` events | `ptsService` |
| Kafka (input) | Message transport; `mobile_notifications` topic | `kafkaPlatform` |
| PtsLocationJob (Ingestion Jobs) | Spark Streaming job that drives this flow | `continuumClsDataPipelineService` / `ingestionJobs` |
| PtsSerializableJob (Transformation Processors) | Filters and normalizes raw JSON messages | `continuumClsDataPipelineService` / `transformProcessors` |
| PtsLocationProcessor | Creates a Spark temporary view and passes records through | `continuumClsDataPipelineService` / `transformProcessors` |
| Spark Client Adapter | Executes Hive INSERT statements | `continuumClsDataPipelineService` / `sparkClientAdapter` |
| Kafka Writer | Publishes to output topic when enabled | `continuumClsDataPipelineService` / `kafkaWriter` |
| CLS Realtime Hive Tables | Persistence target | `continuumClsRealtimeHive` |

## Steps

1. **Subscribes to Kafka topic**: `PtsLocationJob` establishes a Spark Streaming direct stream against the `mobile_notifications` topic on the configured input broker.
   - From: `kafkaPlatform` (`mobile_notifications`)
   - To: `ingestionJobs` (`PtsLocationJob`)
   - Protocol: Kafka (Spark Streaming Kafka 0-10, `StringDeserializer` + `ByteArrayDeserializer`)

2. **Decodes Loggernaut payload**: For each Kafka record, `LoggernautParser` decodes the binary value field into a list of `LoggernautEvent` objects and extracts the JSON message body from each event's body field.
   - From: Raw `Array[Byte]` Kafka record value
   - To: JSON string array
   - Protocol: in-process (JVM)

3. **Filters relevant events**: `PtsSerializableJob.filterKafkaMessage` retains only records where `name="trace"` AND `level="info"` AND `data.args.event` equals `update_token_cc` (with non-null `updated_token.location`) or `create_token_cc` (with non-null `created_tokens[0].location`). Records not matching are silently dropped.
   - From: Raw JSON string
   - To: Filtered JSON string
   - Protocol: in-process

4. **Transforms JSON to normalized record**: `PtsSerializableJob.transformJsonMessage` maps PTS-specific field names to CLS canonical fields: `deviceId` → `device_id`, `consumerId` → `consumer_id`, `clientRole` → `clientrole`, `location.latitude` → `rounded_latitude`, `location.longitude` → `rounded_longitude`, `country_code`, `created`, `modified`, `event`. Appends `pipeline_source=pts`.
   - From: PTS-format JSON string
   - To: Normalized CLS JSON string
   - Protocol: in-process

5. **Creates Spark DataFrame**: The normalized JSON strings are parsed into a Spark DataFrame by `PtsLocationProcessor`, which registers a temporary view `pts_view_for_<dc>` and selects all columns.
   - From: DStream of JSON strings
   - To: Spark DataFrame
   - Protocol: in-process (Spark SQL)

6. **Inserts into Hive table**: `PtsLocationJob.insertIntoTable` executes a Spark SQL INSERT INTO the appropriate regional table, partitioned by the current date:
   - NA: `grp_gdoop_cls_db.pts_history_na_v2 PARTITION (record_date='yyyy-MM-dd')`
   - EMEA: `grp_gdoop_cls_db.pts_history_emea_v2 PARTITION (record_date='yyyy-MM-dd')`
   - Fields inserted: `consumer_id`, `device_id`, `device_token`, `clientrole`, `created`, `modified`, `event`, `rounded_latitude`, `rounded_longitude`, `entry_time`, `country_code`
   - From: `sparkClientAdapter`
   - To: `continuumClsRealtimeHive`
   - Protocol: Hive / Spark SQL

7. **Publishes to downstream Kafka** (optional): If `--enableKafkaOutput` is set, `kafkaWriter` publishes the normalized DataFrame records to the `cls_coalesce_pts_na` topic on `kafka.snc1:9092` using the Spark SQL Kafka sink.
   - From: `kafkaWriter`
   - To: `kafkaPlatform` (`cls_coalesce_pts_na`)
   - Protocol: Kafka

8. **Registers pipeline in monitoring table**: On startup, `PtsLocationJob.registerPipelineJob` upserts a row for `pts_<dc>` into `grp_gdoop_cls_db.pipeline_monitoring_table` with the current YARN application ID and timestamp.
   - From: `ingestionJobs`
   - To: `continuumClsRealtimeHive` (`pipeline_monitoring_table`)
   - Protocol: Hive / Spark SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JSON parsing exception in `filterKafkaMessage` | `try/catch` — exception is caught, returns `false` | Record silently dropped; no alert |
| Loggernaut decode returns no events | `flatMap` produces empty array | No records emitted for that Kafka message |
| Hive INSERT failure | Spark task failure; micro-batch fails | Data for that 60-second window is lost; job continues on next batch |
| Kafka output write failure | Spark task failure | Micro-batch retry; if persistent, YARN app fails and triggers monitor alert |

## Sequence Diagram

```
PtsService -> Kafka[mobile_notifications]: Publish token event (Loggernaut/binary)
Kafka[mobile_notifications] -> PtsLocationJob: Poll micro-batch (60s)
PtsLocationJob -> LoggernautParser: Decode binary payload
LoggernautParser --> PtsLocationJob: JSON message body
PtsLocationJob -> PtsSerializableJob: filterKafkaMessage(jsonString)
PtsSerializableJob --> PtsLocationJob: true/false (include or drop)
PtsLocationJob -> PtsSerializableJob: transformJsonMessage(jsonString)
PtsSerializableJob --> PtsLocationJob: Normalized CLS JSON string
PtsLocationJob -> PtsLocationProcessor: run(dataFrame, paramsHolder)
PtsLocationProcessor --> PtsLocationJob: Processed DataFrame
PtsLocationJob -> SparkClientAdapter: INSERT INTO pts_history_na_v2 PARTITION(record_date)
SparkClientAdapter -> HiveTables: Write ORC partition
PtsLocationJob -> KafkaWriter: Write to cls_coalesce_pts_na (if enabled)
KafkaWriter -> Kafka[cls_coalesce_pts_na]: Publish normalized records
```

## Related

- Architecture dynamic view: `dynamic-clsDataPipeline`
- Related flows: [Proximity Location Ingestion](proximity-location-ingestion.md), [GSS Division Ingestion](gss-division-ingestion.md), [Pipeline Health Monitoring](pipeline-health-monitoring.md)
