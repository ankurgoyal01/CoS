---
service: "web-metrics"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

> No evidence found in codebase.

Web Metrics is stateless and does not own any databases, caches, or persistent storage. All data flows in one direction: from the Google PageSpeed Insights API through the transformation pipeline and out to the Telegraf metrics gateway (`metricsStack`). No data is retained within the service between CronJob runs.

## Stores

> This service is stateless and does not own any data stores.

No databases, file stores, object stores, or other persistent storage are provisioned or accessed by this service.

## Caches

> No evidence found in codebase.

No in-memory cache, Redis, or Memcached instance is used. Each CronJob execution fetches fresh data from the PSI API.

## Data Flows

Metric data flows in a single outbound pipeline:

1. Google PageSpeed Insights API returns CrUX and Lighthouse audit JSON
2. `wmWorkerResultMapper` transforms audit payloads into Influx data point structures
3. `wmWorkerTelegraphWriter` validates and writes points to the Telegraf gateway via `influx.writePoints()`
4. Telegraf forwards the Influx Line Protocol data to Wavefront for storage and visualization

No data flows back into the service or between CronJob invocations.
