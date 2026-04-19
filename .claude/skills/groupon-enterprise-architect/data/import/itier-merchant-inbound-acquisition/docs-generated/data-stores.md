---
service: "itier-merchant-inbound-acquisition"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. It holds no database connections, caches, or object storage of its own. All state that must be persisted is delegated to downstream services:

- **Merchant lead data** — written to Metro draft service (via `@grpn/metro-client`) or Salesforce CRM (via `jsforce`)
- **Address and place data** — retrieved on demand from the Groupon V2 address-autocomplete API (`continuumApiLazloService`)
- **Merchant configuration / PDS taxonomy** — fetched on demand from Metro (`metro.getConfig`, `metro.getPDS`)

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase of any caching layer (Redis, Memcached, or in-memory cache).

## Data Flows

All data flows are request-scoped:

1. Browser submits form fields to `POST /merchant/inbound/api/lead`.
2. The lead handler transforms the payload into either a Metro draft merchant payload (`createDraftServiceLeadData`) or a Salesforce lead payload (`createSFLeadData`) and writes to the appropriate downstream system.
3. The handler returns the downstream system's response (including a draft merchant ID or Salesforce lead ID) directly to the browser.
4. No data is retained in this service between requests.
