---
service: "mobile-logging-v2"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. It operates as a pure ingestion and transformation pipeline: it receives log payloads via HTTP, processes them entirely in memory, and publishes results to Kafka. No database, cache, or persistent storage is read from or written to by this service.

> This service is stateless and does not own any data stores.

## Stores

> Not applicable.

## Caches

> Not applicable. The only in-memory structure that resembles a cache is the static `BAD_BCOOKIES` set loaded at startup from a classpath resource (`bad_bcookies.txt`), and the `GRP_STRING_TO_INT` map in `GRPMapper` — both are read-only and initialised once at JVM startup.

## Data Flows

Events flow in one direction:

1. Mobile client HTTP POST → held in request buffer (in-memory, bounded by `bufferSize` config)
2. Decoded and normalised in the decode thread pool (in-memory, bounded by `decodePoolSize`)
3. Encoded and sent to Kafka (`mobile_tracking` topic) — no local persistence

The Kafka topic `mobile_tracking` is owned by the downstream data platform (Kafka team), not by this service.
