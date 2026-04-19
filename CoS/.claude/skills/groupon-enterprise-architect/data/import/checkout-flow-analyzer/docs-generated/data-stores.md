---
service: "checkout-flow-analyzer"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumCheckoutFlowAnalyzerCsvDataFiles"
    type: "local-filesystem"
    purpose: "Repository-backed CSV/ZIP log file archives used as the analysis data source"
  - id: "browser-local-storage"
    type: "browser-local-storage"
    purpose: "Persists the selected time window ID across page navigations"
---

# Data Stores

## Overview

The Checkout Flow Analyzer uses two storage mechanisms: a local filesystem directory containing pre-loaded CSV/ZIP log exports, and browser `localStorage` for client-side time-window selection state. There is no database, cache, or cloud object store. The filesystem data is read-only at runtime (the application reads but does not delete or modify log files during normal operation).

## Stores

### CSV Data Files Store (`continuumCheckoutFlowAnalyzerCsvDataFiles`)

| Property | Value |
|----------|-------|
| Type | local-filesystem (CSV and ZIP archives) |
| Architecture ref | `continuumCheckoutFlowAnalyzerCsvDataFiles` |
| Purpose | Source of all checkout log data used for session browsing and metric computation |
| Ownership | owned |
| Path | `src/assets/data-files/` (relative to application root) |

#### Key Entities

| Entity / File Type | Purpose | Key Fields |
|----------------|---------|-----------|
| `pwa_logs_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv.zip` | PWA frontend event log — primary source for session browsing and conversion metrics | `bcookie`, `name` (event name), `timestamp`, `requestId`, `platform`, `cat`, `errorCode`, `errorMessage`, `macaroon` |
| `proxy_logs_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv.zip` | Proxy-layer HTTP request log for cross-referencing backend calls | `bcookie`, `timestamp`, `requestId`, `path`, `statusCode`, `name`, `errorMessage` |
| `lazlo_logs_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv.zip` | Lazlo (legacy checkout backend) request log | `timestamp`, `requestId`, `path`, `statusCode`, `name`, `legacyMethod`, `action` |
| `orders_logs_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv.zip` | Orders-service event log for correlating order outcomes with sessions | `bcookie`, `timestamp`, `requestId`, `statusCode`, `endpoint` |
| `bcookie_summary_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv.zip` | Pre-aggregated session summary per bCookie — used as an optimized fast-path for session list queries | `bcookie`, aggregated event flags, purchase/error indicators |

#### Access Patterns

- **Read**: `FileStorage.listFiles(timeWindowId?)` scans `src/assets/data-files/`, parses filenames using the pattern `(pwa|orders|proxy|lazlo|bcookie_summary)(_logs)?_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv(.zip)?`, and returns metadata. `FileStorage.readFile(fileId)` reads the file buffer and auto-detects compression (ZIP via `adm-zip`, gzip via `zlib.createGunzip`, fallback to plain text).
- **Write**: Files are pre-loaded externally (not created by the application at runtime). `FileStorage.storeFile()` exists as an API but is not called by any active route handler.
- **Indexes**: None — files are discovered by directory scan and filename pattern matching on each request.

### Browser Time Window Store

| Property | Value |
|----------|-------|
| Type | browser-local-storage |
| Architecture ref | `webUiCheFloAna` (client-side component of `continuumCheckoutFlowAnalyzerApp`) |
| Purpose | Persists the selected `timeWindowId` across page navigations within the browser session |
| Ownership | owned |
| Key | `current_time_window_id` |

#### Access Patterns

- **Read**: `TimeWindowStore.getTimeWindowId()` — called on page load by the Sessions page to restore the active time window context.
- **Write**: `TimeWindowStore.setTimeWindowId(timeWindowId)` — called after `/api/select-csv` succeeds.

## Caches

> No server-side caches are configured. The `bcookie_summary` file acts as a pre-aggregated data source that serves as a performance optimization over raw log scanning, but it is not a cache — it is a static file.

## Data Flows

Log files are produced externally (e.g., exported from Kibana/ELK) and placed in `src/assets/data-files/` before the application starts. At runtime:

1. The File Storage Adapter scans the directory, parses filenames, and groups files into time windows.
2. When the user selects a time window, the API reads the appropriate compressed file, decompresses it, and streams it through Papa Parse.
3. Parsed rows are filtered and paginated in memory before being returned as JSON to the browser UI.
4. No data is written back to the filesystem during normal operation.
