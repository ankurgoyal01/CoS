---
service: "my_appointments_client"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

My Appointments Client is a stateless application. It owns no databases, caches, or persistent storage. All reservation and booking data is stored and managed by downstream services (`continuumAppointmentsEngine` for reservation state, `continuumApiLazloService` for groupon/order state). This service acts purely as an orchestration and rendering layer, fetching data on demand from upstream APIs and rendering it to HTML or JSON responses.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase.

No caching layer (Redis, Memcached, or in-memory) is directly owned or operated by this service. CDN asset caching for static JavaScript and CSS widget bundles is managed by the I-Tier asset pipeline (`itier-assets`) and served from Groupon CDN hosts (`www<1,2>.grouponcdn.com` in production, `staging<1,2>.grouponcdn.com` in staging).

## Data Flows

> This service is stateless and does not own any data stores.

All data flows pass through HTTP requests to downstream services and are not persisted locally. See [Integrations](integrations.md) for details on upstream data sources.
