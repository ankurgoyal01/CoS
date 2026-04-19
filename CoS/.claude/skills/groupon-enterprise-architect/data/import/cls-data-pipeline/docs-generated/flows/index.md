---
service: "cls-data-pipeline"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for CLS Data Pipeline.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [PTS Location Ingestion](pts-location-ingestion.md) | event-driven | Kafka event on `mobile_notifications` topic | Consumes PTS push-token events, filters for location-bearing records, normalizes fields, and persists to Hive and downstream Kafka |
| [Proximity Location Ingestion](proximity-location-ingestion.md) | event-driven | Kafka event on `mobile_proximity_locations` topic | Consumes proximity geofence events, extracts lat/lng coordinates, and persists to Hive and downstream Kafka |
| [GSS Division Ingestion](gss-division-ingestion.md) | event-driven | Kafka event on `global_subscription_service` topic | Consumes GSS subscription change events, extracts division/location signals, and persists to Hive and downstream Kafka |
| [Location Prediction Batch](location-prediction-batch.md) | batch | Manual spark-submit (scheduled) | Reads coalesced location history from Hive, trains a RandomForest regressor per device, and writes predicted lat/lng back to Hive |
| [Pipeline Health Monitoring](pipeline-health-monitoring.md) | batch | Manual or scheduled spark-submit | Queries YARN for the status of all registered streaming jobs and sends pager/email alerts for any non-running pipeline |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

All three event-driven ingestion flows (PTS, Proximity, GSS) span multiple services:
- Upstream producers (PTS service, Proximity service, GSS service) emit Loggernaut-encoded events to Kafka
- `continuumClsDataPipelineService` consumes, normalizes, and routes those events to Hive and the `cls_coalesce_pts_na` Kafka topic
- The coalescing layer (Optimus jobs) reads from Hive to compute primary consumer location

Refer to the central architecture model for cross-service dynamic views.
