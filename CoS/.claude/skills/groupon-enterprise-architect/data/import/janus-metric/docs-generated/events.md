---
service: "janus-metric"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["kafka-via-gcs"]
---

# Events

## Overview

janus-metric does not directly consume from or publish to Kafka. Instead, it reads files that were previously written to GCS from Kafka topics by upstream ingestion pipelines. The service treats each GCS bucket path as a logical "event source" and uses Ultron watermarking to track which files have been processed. Metric results are written synchronously to the Janus Metadata Service API — no events are published.

## Published Events

> No evidence found in codebase. This service does not publish async events. All metric results are persisted synchronously via HTTPS POST to the Janus Metadata Service.

## Consumed Events (via GCS file sources)

The following logical source topics are consumed as GCS Parquet/Avro files. The Ultron delta manager determines which files are new since the last high-watermark.

| GCS Source (topic origin) | Event Type | Handler | Side Effects |
|---------------------------|-----------|---------|-------------|
| `mobile_tracking` (NA region) | GRP3, GRP4, GRP5, GRP9, GRP14, GRP17, GRP24, GRP39 | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `tracky` (NA region) | `interaction-goal-purchase_server` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `tracky_lup1` (INTL region) | `interaction-goal-purchase_server` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `tracky_json_nginx` (NA region) | `interaction-goal-purchase`, `tracking-init` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `tracky_json_nginx_lup1` (INTL region) | `interaction-goal-purchase`, `tracking-init` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `msys_delivery` (NA region) | `msys_delivery` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `msys_delivery_lup1` (INTL region) | `msys_delivery` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `grout_access` (NA region) | `email-click`, `email-open` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `grout_access_lup1` (INTL region) | `email-click`, `email-open` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `rocketman_send` (NA region) | `email-send` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| `rocketman_send_lup1` (INTL region) | `email-send` | `janusRawMetricEngine` | Raw audit cube persisted to Janus API |
| Janus volume/quality Parquet (GCS) | All Janus events | `janusMetricComputationEngine` | Volume, quality, catfood cubes persisted to Janus API |
| Juno hourly Parquet (GCS) | All Juno events | `junoMetricEngine` | Juno volume cubes persisted to Janus API |
| Jupiter attribute Parquet (GCS) | All Jupiter attributes | `attributeCardinalityEngine` | Cardinality results persisted to Janus API |

### GCS Source Path Details (production)

| Logical Source | Production GCS Path Pattern |
|---------------|----------------------------|
| Janus volume/quality | `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/janus/ds=$dates/hour=$hours/*` |
| Juno hourly | `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/prod/juno/junoHourly/eventDate=$dates/platform=*/eventDestination=*/*` |
| mobile_tracking (NA) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=na/yati_raw_sources/source=mobile_tracking/` |
| tracky (NA) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=na/yati_raw_sources/source=tracky/` |
| tracky_lup1 (INTL) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=intl/yati_raw_sources/source=tracky/` |
| tracky_json_nginx (NA) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=na/yati_raw_sources/source=tracky_json_nginx/` |
| tracky_json_nginx_lup1 (INTL) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=intl/yati_raw_sources/source=tracky_json_nginx/` |
| msys_delivery (NA) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=na/yati_raw_sources/source=msys_delivery/` |
| msys_delivery_lup1 (INTL) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=intl/yati_raw_sources/source=msys_delivery/` |
| grout_access (NA) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=na/yati_raw_sources/source=grout_access/` |
| grout_access_lup1 (INTL) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=intl/yati_raw_sources/source=grout_access/` |
| rocketman_send (NA) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=na/yati_raw_sources/source=rocketman_send/` |
| rocketman_send_lup1 (INTL) | `gs://grpn-dnd-prod-pipelines-yati-raw/kafka/region=intl/yati_raw_sources/source=rocketman_send/` |
| Jupiter attributes | `gs://grpn-dnd-prod-pipelines-pde/user/grp_gdoop_platform-data-eng/jupiter` |

## Dead Letter Queues

> No evidence found in codebase. Ultron watermarking marks failed files with `FileStatus.FAILED` and they are retried on the next run. No DLQ mechanism is configured.
