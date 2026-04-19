---
service: "forex-ng"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumForexS3Bucket"
    type: "s3"
    purpose: "Durable store of forex rate JSON files, served via API reads"
  - id: "inmemory"
    type: "in-memory"
    purpose: "Development-only transient rate cache"
---

# Data Stores

## Overview

Forex NG uses AWS S3 as its primary durable data store in production. All currency conversion rates are serialized as individual JSON files and stored in an S3 bucket. In development/local environments, an in-memory map is used instead of S3. There are no relational databases or caches involved.

## Stores

### Forex Rates S3 Bucket (`continuumForexS3Bucket`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `continuumForexS3Bucket` |
| Purpose | Holds one JSON rate file per configured currency (base and pair), served to API consumers |
| Ownership | owned |
| Migrations path | Not applicable (object storage, no schema migrations) |

#### Key Entities

| Entity / Object Key Pattern | Purpose | Key Fields |
|-----------------------------|---------|-----------|
| `v1/rates/{CURRENCY}.json` | Live rate file for a base currency or base/quote pair — this is the object key served to API consumers | `base`, `rates`, `timestamp`, `timestamps`, `source` |
| `tmp_rates/{CURRENCY}.json` | Staging area for newly fetched rates before sanity check and promotion to `v1/rates/` | `base`, `rates`, `timestamp`, `timestamps`, `source` |
| `grpn/healthcheck` | Health check sentinel file — written and read back to verify S3 read/write connectivity after each update | String value `"OK"` |

#### Object (Rate File) Schema

Each `{CURRENCY}.json` file serializes a `ForexRate` immutable value object:

| Field | Type | Description |
|-------|------|-------------|
| `base` | string | ISO 4217 base currency code (e.g., `"USD"`) |
| `rates` | object (SortedMap) | Quote currency codes mapped to floating-point exchange rates |
| `source` | string | Data source identifier (e.g., `"netsuite"`) |
| `timestamp` | long | Unix epoch seconds — minimum of all per-quote timestamps |
| `timestamps` | object (SortedMap) | Per-quote-currency Unix epoch seconds of last update |

#### Access Patterns

- **Read**: `AWSS3Client.read(fileName)` — single async `GetObject` call on `S3AsyncClient`. Called during API rate lookups (`getConversionRate`) and sanity checks. Path: `v1/rates/{currency}.json`.
- **Write**: `AWSS3Client.writeData(fileData)` — batch of async `PutObject` calls, up to 50 concurrent operations at a time (`AWS_CONCURRENT_OPERATIONS = 50`). Used during rate refresh to write all currency files to `tmp_rates/`.
- **Copy**: `AWSS3Client.copy(srcToDestMap)` — batch of async `CopyObject` calls. Promotes files from `tmp_rates/` to `v1/rates/` after sanity check passes.
- **Delete**: `AWSS3Client.delete(fileData)` — batch of async `DeleteObject` calls. Cleans up `tmp_rates/` files after promotion (always runs in `finally` block).
- **Retry**: All S3 write, copy, and delete operations retry up to `MAX_RETRY - 1` (2) times on partial failure.

### In-Memory Data Store (development only)

| Property | Value |
|----------|-------|
| Type | in-memory |
| Architecture ref | Not in architecture model (local dev only) |
| Purpose | Transient map-based store for running the service locally without AWS credentials |
| Ownership | owned |
| Migrations path | Not applicable |

#### Access Patterns

- **Read**: `InmemoryDataStoreClient.getData(currencies)` — lookup by currency code key.
- **Write**: `InmemoryDataStoreClient.storeData(currencies, data)` — stores JSON string by key.

## Caches

> No evidence found in codebase. The in-memory store used in development doubles as a transient cache, but it is not used in production.

## Data Flows

1. Rate refresh job (Quartz or CLI) triggers `ForexService.refreshRates()`.
2. `NetsuiteDataProvider` fetches raw rate data from NetSuite and returns a `Map<currency, Map<quoteCurrency, [rate, epochTime]>>`.
3. `ForexHelper.transform()` converts the raw map into a map of `ForexRate` immutable objects.
4. `AWSS3ForexStore.updateConversionRates()` writes all rate files to `tmp_rates/` in S3.
5. `AWSS3Sanity.doSanity(tmp_rates/)` validates a subset of configured `sanityCurrencies` from the staging area.
6. On sanity pass, files are copied from `tmp_rates/` to `v1/rates/` atomically (per-file copy).
7. `AWSS3Sanity.doSanity(v1/rates/)` re-validates the live directory.
8. Health check sentinel (`grpn/healthcheck`) is written and read back.
9. `tmp_rates/` files are deleted in the `finally` block.
10. API consumers call `GET /v1/rates/{currency}.json` — `AWSS3ForexStore.getConversionRate()` reads the corresponding `v1/rates/{currency}.json` file directly from S3.
