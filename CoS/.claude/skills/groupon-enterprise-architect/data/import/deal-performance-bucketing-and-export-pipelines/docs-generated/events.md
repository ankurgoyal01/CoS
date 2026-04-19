---
service: "deal-performance-bucketing-and-export-pipelines"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The Deal Performance Data Pipelines do not publish or consume events via a traditional message broker (e.g., Kafka, RabbitMQ, SQS). All data exchange is performed through batch file I/O on GCS/HDFS. Raw deal event files are read from GCS paths partitioned by date and hour; bucketed output Avro files are written back to GCS. Apache Airflow coordinates pipeline task ordering in place of event-driven triggering.

## Published Events

> No evidence found in codebase.

This service does not publish messages to any event bus or message queue. Output data is written as Avro files to GCS under the path pattern:

```
/user/grp_gdoop_mars_mds/dps/time_granularity=hourly/event_source={source}/date={date}/hour={hour}/event_type={type}
```

These files are consumed by downstream Spark jobs and the DB export pipeline.

## Consumed Events

> No evidence found in codebase.

This service does not subscribe to any event topic. Input data is read as Avro files from GCS:

- **Deal events (impressionAttributed source)**: Path `gs://grpn-dnd-prod-analytics-grp-mars-mds/user/grp_gdoop_mars_mds/dps/events` partitioned as `/date={date}/hour={hour}` — schema: `InstanceStoreAttributedDealImpression`
- **A/B experiment instances**: Path `hdfs://gdoop-namenode/user/grp_gdoop_platform-data-eng/janus` partitioned as `/ds={date}/hour={hour}` — filtered by prefix `relevance-explore-exploit-`

## Dead Letter Queues

> Not applicable. This service uses batch file processing, not message queues. Invalid records are counted and logged; the pipeline emits a `[DPS V2] High Invalid Field Count` Wavefront alert when the error count exceeds thresholds.
