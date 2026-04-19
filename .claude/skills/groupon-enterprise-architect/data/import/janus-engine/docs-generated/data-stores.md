---
service: "janus-engine"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores.

Janus Engine operates as a pure stream processor. All state required for curation (mapper definitions and routing rules) is fetched at runtime from the external Janus metadata service and held in a local in-process cache (`janusMetadataClientComponent`). No databases, object stores, or persistent caches are owned or managed by this service.

## Stores

> Not applicable

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Janus metadata cache | in-memory | Caches mapper definitions and curation rules fetched from the Janus metadata service to avoid per-event HTTP calls | > No evidence found — TTL/refresh policy managed within `janusMetadataClientComponent` |

## Data Flows

Janus Engine reads from MBus and Kafka (inbound) and writes to Kafka (outbound). There is no database read or write path. The in-memory metadata cache is populated on startup and refreshed periodically. See [Curator Metadata Refresh Flow](flows/curator-metadata-refresh.md) for details.
