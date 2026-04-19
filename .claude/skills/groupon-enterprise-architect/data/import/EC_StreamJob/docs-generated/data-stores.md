---
service: "EC_StreamJob"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. EC_StreamJob reads events from Kafka and forwards them to TDM via HTTP. No data is persisted, cached, or read from a database by this service. State is held transiently in memory within each Spark micro-batch (20-second window) for within-partition deduplication using a `HashSet`, which is discarded after each batch completes.

## Stores

> Not applicable. This service is stateless and does not own any data stores.

## Caches

> Not applicable. No external caches are used. The in-partition `HashSet` used for deduplication is an ephemeral in-memory structure discarded after each 20-second batch.

## Data Flows

> Not applicable. No persistent data movement between stores occurs in this service. Data flows in from Kafka and out to TDM HTTP within each micro-batch window.
