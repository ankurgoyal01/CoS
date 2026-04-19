---
service: "sponsored-campaign-itier"
title: Data Stores
generated: "2026-03-02"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. All persistent data — campaign records, billing records, wallet balances, and performance metrics — is stored in upstream services (`continuumUniversalMerchantApi` via UMAPI, and Groupon V2). The BFF reads and writes data exclusively through HTTP proxy calls to these upstream services.

## Stores

> Not applicable — no owned data stores.

## Caches

> No evidence found — no in-process or external cache (Redis, Memcached) is configured.

## Data Flows

All data flows are synchronous HTTP request-response cycles:

- Merchant browser sends request to `continuumSponsoredCampaignItier`
- BFF validates merchant session via `continuumMerchantApi`
- BFF forwards the operation to `continuumUniversalMerchantApi` (campaigns, billing, performance) or Groupon V2 (billing records)
- UMAPI returns the result; BFF relays it to the browser

No CDC, ETL, replication, or materialized view patterns apply.
