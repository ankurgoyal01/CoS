---
service: "raas_c1"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. RAAS C1 is a Service Portal registration entry with no deployable application. Persistent metadata for Redis cluster inventory is managed by the `raas` platform via `continuumRaasMetadataMysql` and `continuumRaasMetadataPostgres`.

## Stores

> Not applicable — no data stores are owned or operated by this service.

## Caches

> Not applicable — no caches are operated by this service. Redis instances visible through the C1 Service Portal entry are managed infrastructure, not application caches owned by this service.

## Data Flows

> Not applicable — this service is stateless and mediates no data flows.
