---
service: "merchant-booking-tool"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. The Merchant Booking Tool is an I-tier web application that acts as a presentation and proxy layer. All booking data is owned and persisted by the upstream `continuumUniversalMerchantApi` (booking service). The Merchant Booking Tool reads and writes data through that API and does not maintain its own database, cache, or file storage.

## Stores

> Not applicable. This service does not own any data stores.

## Caches

> No evidence found in codebase. No caching layer is defined in the architecture DSL for this service.

## Data Flows

All data flows pass through the Merchant Booking Tool as a transparent proxy or page-rendering layer:

- The `mbtMerchantApiClient` component reads booking-service data (reservations, calendars, accounts, campaigns, workshops, staff profiles) from `continuumUniversalMerchantApi` on behalf of page renders.
- The `mbtProxyController` forwards write and update operations to the upstream booking service base URL.
- No data is persisted within this service's own boundaries.
