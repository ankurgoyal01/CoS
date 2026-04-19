---
service: "cls-data-pipeline"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka"]
---

# Events

## Overview

The CLS Data Pipeline is a Kafka-centric service. It consumes three distinct Kafka input topics (one per location signal source) across two data centers (NA and EMEA), resulting in six parallel streaming pipelines. Each pipeline deserializes Loggernaut-encoded byte payloads, filters to relevant event types, transforms the JSON payload, and optionally publishes normalized records to a shared downstream Kafka output topic. All consumed messages use `StringDeserializer` for keys and `ByteArrayDeserializer` for values, with Loggernaut event parsing applied in the pre-processing stage.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `cls_coalesce_pts_na` | Normalized location record | Successful transformation of any PTS, Proximity, or GSS event | `consumer_id`, `device_id`, `rounded_latitude`, `rounded_longitude`, `country_code`, `pipeline_source` |

### Normalized Location Record Detail

- **Topic**: `cls_coalesce_pts_na`
- **Trigger**: Each successfully transformed event from the PTS NA, PTS EMEA, Proximity NA, Proximity EMEA, GSS NA, or GSS EMEA streaming pipelines, when `--enableKafkaOutput` flag is set
- **Payload**: JSON object with normalized fields including `consumer_id`, `device_id`, `rounded_latitude`, `rounded_longitude`, `country_code`, and `pipeline_source` (one of: `pts`, `proximity`, `gss`)
- **Consumers**: Downstream coalescing jobs (Optimus jobs in `cls-optimus-jobs`)
- **Guarantees**: at-least-once (Spark Streaming with Kafka offset management; `offsetReset` defaults to `latest`)
- **Output Kafka broker (NA)**: `kafka.snc1:9092`

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `mobile_notifications` (NA) | PTS token update/create event | `PtsLocationJob` + `PtsSerializableJob` | Writes to `grp_gdoop_cls_db.pts_history_na_v2`; optionally publishes to `cls_coalesce_pts_na` |
| `mobile_notifications` (EMEA) | PTS token update/create event | `PtsLocationJob` + `PtsSerializableJob` | Writes to `grp_gdoop_cls_db.pts_history_emea_v2`; optionally publishes to `cls_coalesce_pts_na` |
| `mobile_proximity_locations` (NA) | Proximity geofence event | `ProximityLocationJob` + `ProximitySerializableJob` | Writes to `grp_gdoop_cls_db.proximity_history_na`; optionally publishes to `cls_coalesce_pts_na` |
| `mobile_proximity_locations` (EMEA) | Proximity geofence event | `ProximityLocationJob` + `ProximitySerializableJob` | Writes to `grp_gdoop_cls_db.proximity_history_emea`; optionally publishes to `cls_coalesce_pts_na` |
| `global_subscription_service` (NA) | GSS division subscription change | `GssDivJob` + `GssSerializableJob` | Writes to `grp_gdoop_cls_db.gss_history_na`; optionally publishes to `cls_coalesce_pts_na` |
| `global_subscription_service` (EMEA) | GSS division subscription change | `GssDivJob` + `GssSerializableJob` | Writes to `grp_gdoop_cls_db.gss_history_emea`; optionally publishes to `cls_coalesce_pts_na` |

### PTS Event Detail (`mobile_notifications`)

- **Topic**: `mobile_notifications`
- **Input brokers**: NA — `kafka-aggregate.snc1:9092`; EMEA — `kafka.dub1:9092`
- **Handler**: `PtsLocationJob.preProcessDStream` decodes Loggernaut byte payload, extracts JSON body, filters for `name="trace"`, `level="info"`, and `event` equal to `update_token_cc` or `create_token_cc` with a non-null `location` field
- **Transformation**: `PtsSerializableJob.transformJsonMessage` maps `deviceId`, `token`, `consumerId`, `clientRole`, `country_code`, `location.latitude`, `location.longitude`, and event timestamps to a normalized flat JSON string with `pipeline_source=pts`
- **Consumer Group (NA)**: `kafka_cls_mpts_na`; (EMEA): `kafka_cls_mpts_emea`
- **Idempotency**: No explicit deduplication; Hive insert appends per micro-batch
- **Error handling**: Exceptions during JSON parsing are caught and the record is silently dropped (returns `false` from `filterKafkaMessage`)
- **Processing order**: unordered (Spark Streaming micro-batch, 60-second intervals)

### Proximity Event Detail (`mobile_proximity_locations`)

- **Topic**: `mobile_proximity_locations`
- **Input brokers**: NA — `kafka.snc1:9092`; EMEA — `kafka.dub1:9092`
- **Handler**: `ProximityLocationJob.preProcessDStream` decodes Loggernaut payload; `ProximitySerializableJob.filterKafkaMessage` filters for `name="GeofenceResource"`, `level="info"`, and `data.message="realtimeuserlocation"`
- **Transformation**: Maps `data.lat`, `data.lng`, `data.bCookie`, `data.consumerId`, `data.detectTime`, `data.countryCode` to normalized fields with `pipeline_source=proximity`
- **Consumer Group (NA)**: `kafka_cls_prxmty_na`; (EMEA): `kafka_cls_prxmty_emea`
- **Idempotency**: No explicit deduplication
- **Error handling**: Exceptions caught; record dropped silently
- **Processing order**: unordered (60-second micro-batches)

### GSS Event Detail (`global_subscription_service`)

- **Topic**: `global_subscription_service`
- **Input brokers**: NA — `kafka-aggregate.snc1:9092`; EMEA — `kafka.dub1:9092`
- **Handler**: `GssDivJob.preProcessDStream` decodes Loggernaut payload; `GssSerializableJob.filterKafkaMessage` accepts `subscription_db_change` (action=`subscribe`, listNamespace length=4) and `subscription_change` (listType=`division`, action in `UNSUBSCRIBE_BY_LIST_TYPE`, `UNSUBSCRIBE_BY_LIST_ID`, `UNSUBSCRIBE_BY_ID`)
- **Transformation**: Maps `time`, `data.action`, `data.sid`, `data.listId`, `data.countryCode`, `data.brand`, `data.bcookie` to normalized fields with `pipeline_source=gss`
- **Consumer Group (NA)**: `kafka_cls_gss_na`; (EMEA): `kafka_cls_gss_emea`
- **Idempotency**: No explicit deduplication
- **Error handling**: Exceptions caught; record dropped silently
- **Processing order**: unordered (60-second micro-batches)

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration exists; failed records are silently dropped at the filter stage with exception handling.
