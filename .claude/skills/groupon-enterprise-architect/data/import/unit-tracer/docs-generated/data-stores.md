---
service: "unit-tracer"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Unit Tracer is a stateless aggregation service. It owns no data stores of any kind. All data it presents in reports is fetched on-demand from upstream services (inventory services, accounting service, message-to-ledger service) at request time. No data is persisted, cached, or replicated by this service.

## Stores

> Not applicable. This service is stateless and does not own any data stores.

## Caches

> Not applicable. No caching layer is configured. All upstream calls are made synchronously per request with no result caching.

## Data Flows

Unit Tracer is a pure read-through aggregator. Data flows in one direction at request time:

1. A user submits unit IDs to Unit Tracer via HTTP.
2. Unit Tracer makes outbound HTTP calls to inventory services, accounting service, and message-to-ledger service.
3. Responses are assembled in memory into a `UnitReport` object.
4. The assembled report is serialized (HTML or JSON) and returned to the caller.

No ETL, CDC, replication, or materialized views are involved.
