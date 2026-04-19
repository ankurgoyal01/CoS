---
service: "goods-vendor-portal"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. The Goods Vendor Portal is a pure frontend SPA; all persistent data (product catalog, deals, contracts, vendor profiles, analytics) is owned and stored by the GPAPI backend. The portal reads and writes data exclusively through the `/goods-gateway/*` proxy to GPAPI and does not maintain its own database, cache, or file storage.

## Stores

> Not applicable

## Caches

> Not applicable

## Data Flows

All data flows through the following path:

1. User interaction in the browser triggers an `ember-data` or `ember-ajax` call within `emberApp`.
2. `goodsVendorPortal_apiClient` issues an HTTPS request to `/goods-gateway/*`.
3. Nginx proxies the request to `gpapiApi_unk_1d2b` (GPAPI).
4. GPAPI persists to or reads from its own datastores and returns a JSON response.
5. The response travels back through Nginx to the Ember store, where it is deserialized and rendered in the UI.
