---
service: "cls-data-pipeline"
title: "Proximity Location Ingestion"
generated: "2026-03-03"
type: flow
flow_name: "proximity-location-ingestion"
flow_type: event-driven
trigger: "Kafka event on mobile_proximity_locations topic"
participants:
  - "proximityService"
  - "kafkaPlatform"
  - "continuumClsDataPipelineService"
  - "continuumClsRealtimeHive"
architecture_ref: "dynamic-clsDataPipeline"
---

# Proximity Location Ingestion

## Summary

This flow processes geofence-detected consumer location events from the Proximity service. The Proximity service publishes real-time user location events to the `mobile_proximity_locations` Kafka topic; the CLS pipeline subscribes separately for NA (`kafka.snc1:9092`) and EMEA (`kafka.dub1:9092`). Each 60-second micro-batch is decoded from Loggernaut binary format, filtered to `GeofenceResource` / `realtimeuserlocation` events, transformed to extract latitude/longitude coordinates, and written to partitioned proximity history tables in Hive.

## Trigger

- **Type**: event (Kafka message arrival)
- **Source**: Proximity Service publishes geofence-detected location events to `mobile_proximity_locations`
- **Frequency**: Continuous; processed in 60-second micro-batch intervals

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Proximity Service | Upstream producer of `mobile_proximity_locations` events | `proximityService` |
| Kafka (input) | Message transport; `mobile_proximity_locations` topic | `kafkaPlatform` |
| ProximityLocationJob (Ingestion Jobs) | Spark Streaming job driving this flow | `continuumClsDataPipelineService` / `ingestionJobs` |
| ProximitySerializableJob (Transformation Processors) | Filters and normalizes proximity JSON messages | `continuumClsDataPipelineService` / `transformProcessors` |
| ProximityLocationProcessor | Creates a Spark temporary view and passes records through | `continuumClsDataPipelineService` / `transformProcessors` |
| Spark Client Adapter | Executes Hive INSERT statements | `continuumClsDataPipelineService` / `sparkClientAdapter` |
| Kafka Writer | Publishes to output topic when enabled | `continuumClsDataPipelineService` / `kafkaWriter` |
| CLS Realtime Hive Tables | Persistence target | `continuumClsRealtimeHive` |

## Steps

1. **Subscribes to Kafka topic**: `ProximityLocationJob` creates a Spark Streaming direct stream against `mobile_proximity_locations` on the configured broker.
   - From: `kafkaPlatform` (`mobile_proximity_locations`)
   - To: `ingestionJobs` (`ProximityLocationJob`)
   - Protocol: Kafka (Spark Streaming Kafka 0-10, `StringDeserializer` + `ByteArrayDeserializer`)

2. **Decodes Loggernaut payload**: `LoggernautParser` decodes the binary value into `LoggernautEvent` objects and extracts each event's JSON body string.
   - From: Raw `Array[Byte]` Kafka record value
   - To: JSON string array
   - Protocol: in-process

3. **Filters for geofence location events**: `ProximitySerializableJob.filterKafkaMessage` accepts only records where `name="GeofenceResource"` AND `level="info"` AND `data.message="realtimeuserlocation"`. All other messages are silently dropped.
   - From: Raw JSON string
   - To: Filtered JSON string
   - Protocol: in-process

4. **Transforms to normalized record**: `ProximitySerializableJob.transformJsonMessage` extracts:
   - `data.lat` → `rounded_latitude`
   - `data.lng` → `rounded_longitude`
   - `data.bCookie` → `device_id`
   - `data.consumerId` → `consumer_id`
   - `data.detectTime` → `detect_time`
   - `data.countryCode` → `country_code`
   - Appends `pipeline_source=proximity`
   - From: Proximity-format JSON
   - To: Normalized CLS JSON string
   - Protocol: in-process

5. **Creates Spark DataFrame**: `ProximityLocationProcessor` registers a temporary view `proximity_view_for_<dc>` and selects all columns.
   - From: DStream of normalized JSON strings
   - To: Spark DataFrame
   - Protocol: in-process (Spark SQL)

6. **Inserts into Hive table**: `ProximityLocationJob.insertIntoTable` executes Spark SQL INSERT INTO:
   - NA: `grp_gdoop_cls_db.proximity_history_na PARTITION (record_date='yyyy-MM-dd')`
   - EMEA: `grp_gdoop_cls_db.proximity_history_emea PARTITION (record_date='yyyy-MM-dd')`
   - Fields: `consumer_id`, `device_id`, `detect_time`, `country_code`, `rounded_latitude`, `rounded_longitude`, `entry_time`
   - From: `sparkClientAdapter`
   - To: `continuumClsRealtimeHive`
   - Protocol: Hive / Spark SQL

7. **Publishes to downstream Kafka** (optional): When `--enableKafkaOutput` is set, `kafkaWriter` publishes normalized records to `cls_coalesce_pts_na` on `kafka.snc1:9092`.
   - From: `kafkaWriter`
   - To: `kafkaPlatform` (`cls_coalesce_pts_na`)
   - Protocol: Kafka

8. **Registers pipeline in monitoring table**: On startup, `ProximityLocationJob.registerPipelineJob` upserts a `proximity_<dc>` entry into `grp_gdoop_cls_db.pipeline_monitoring_table`.
   - From: `ingestionJobs`
   - To: `continuumClsRealtimeHive` (`pipeline_monitoring_table`)
   - Protocol: Hive / Spark SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JSON parse exception in `filterKafkaMessage` | `try/catch` — returns `false` | Record silently dropped |
| Null `data.lat` or `data.lng` in proximity payload | Conditional `if` checks in `transformJsonMessage` | Field omitted from output JSON; may result in null lat/lng in Hive row |
| Hive INSERT failure | Spark task failure | Micro-batch data lost; job continues on next batch |
| Kafka output write failure | Spark task failure and retry | If persistent, YARN app fails and pipeline monitor alerts |

## Sequence Diagram

```
ProximityService -> Kafka[mobile_proximity_locations]: Publish geofence event (Loggernaut/binary)
Kafka[mobile_proximity_locations] -> ProximityLocationJob: Poll micro-batch (60s)
ProximityLocationJob -> LoggernautParser: Decode binary payload
LoggernautParser --> ProximityLocationJob: JSON message body
ProximityLocationJob -> ProximitySerializableJob: filterKafkaMessage(jsonString)
ProximitySerializableJob --> ProximityLocationJob: true/false
ProximityLocationJob -> ProximitySerializableJob: transformJsonMessage(jsonString)
ProximitySerializableJob --> ProximityLocationJob: Normalized CLS JSON
ProximityLocationJob -> ProximityLocationProcessor: run(dataFrame, paramsHolder)
ProximityLocationProcessor --> ProximityLocationJob: Processed DataFrame
ProximityLocationJob -> SparkClientAdapter: INSERT INTO proximity_history_na PARTITION(record_date)
SparkClientAdapter -> HiveTables: Write ORC partition
ProximityLocationJob -> KafkaWriter: Write to cls_coalesce_pts_na (if enabled)
KafkaWriter -> Kafka[cls_coalesce_pts_na]: Publish normalized records
```

## Related

- Architecture dynamic view: `dynamic-clsDataPipeline`
- Related flows: [PTS Location Ingestion](pts-location-ingestion.md), [GSS Division Ingestion](gss-division-ingestion.md), [Pipeline Health Monitoring](pipeline-health-monitoring.md)
