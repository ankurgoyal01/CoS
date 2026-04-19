---
service: "mx-reservations-app"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

> This service is stateless and does not own any data stores. MX Reservations App is a BFF (Backend for Frontend) that proxies all data operations to downstream services — API Proxy and Marketing Deal Service. No database connections, cache clients, or file storage are managed by this container. All reservation state is persisted and queried exclusively through the `/reservations/api/v2/*` proxy path.

## Stores

> Not applicable

## Caches

> Not applicable

## Data Flows

All data flows through the proxy path:

1. Merchant browser sends a request to `/reservations/api/v2/*`
2. `continuumMxReservationsApp` forwards the authenticated request to `apiProxy`
3. `apiProxy` routes to `continuumMarketingDealService` for data reads/writes
4. Response is passed back through the proxy chain to the merchant browser

No data is stored or cached at the `continuumMxReservationsApp` layer.
