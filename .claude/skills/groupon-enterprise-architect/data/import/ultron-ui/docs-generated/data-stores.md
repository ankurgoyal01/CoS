---
service: "ultron-ui"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. Ultron UI holds no persistent data. All job definitions, group metadata, instance records, lineage information, and resource registrations are stored and managed by `continuumUltronApi`. Ultron UI retrieves this data on demand via HTTP/JSON and renders it for the operator.

## Stores

> Not applicable

## Caches

> Not applicable

## Data Flows

> Not applicable — data flows through `continuumUltronApi`. See [Integrations](integrations.md) for the upstream dependency.
