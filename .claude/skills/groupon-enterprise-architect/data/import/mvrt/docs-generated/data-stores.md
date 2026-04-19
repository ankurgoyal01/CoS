---
service: "mvrt"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "aws-s3"
    type: "s3"
    purpose: "Offline search/redemption report storage and temporary code list staging"
  - id: "local-filesystem"
    type: "filesystem"
    purpose: "Offline job queue (JSON files) and temporary XLSX/CSV report generation"
---

# Data Stores

## Overview

MVRT owns no relational database or cache. Its data storage is composed of two stores: an AWS S3 bucket for durable storage of offline report files and temporary code list staging, and a local filesystem directory used as a transient job queue and intermediate report staging area. All authoritative voucher, deal, and merchant data is held by downstream Continuum services (`continuumVoucherInventoryService`, `continuumDealCatalogService`, `continuumM3MerchantService`) — MVRT reads from these but does not persist their data.

## Stores

### AWS S3 Bucket (`aws-s3`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `unknown_awss3bucket_da58205c` (stub — not in federated model) |
| Purpose | Stores temporary code list uploads (during offline job creation) and final XLSX/CSV search reports (after offline processing) |
| Ownership | owned |
| Migrations path | Not applicable (object storage) |

#### Key Entities

| Entity / Object | Purpose | Key Fields |
|----------------|---------|-----------|
| `<tempFileName>` (codes list) | Temporary accumulation of codes submitted in chunks by the browser before job creation | Comma-separated code strings |
| `<fileNameWithoutExtn>.xlsx` | Final offline search report in Excel format | Voucher records, redemption status, merchant/deal metadata |
| `<fileNameWithoutExtn>.csv` | Final offline search report in CSV format (user-selectable alternative) | Same as XLSX |

#### Access Patterns

- **Read**: Offline job downloads the final codes list from S3 (`getAllCodes`); download endpoint streams reports from S3 to the browser via `GET /downloadFile`
- **Write**: `/createCodesList` uploads or appends code chunks; offline job uploads completed XLSX/CSV reports; temporary code objects are deleted after JSON job file creation (`deleteCodesObject`)
- **Credentials**: AWS access key and secret pulled from secrets file (`s3_bucket.access_key_id`, `s3_bucket.secret_key`, `s3_bucket.bucket_name`, `s3_bucket.region`)

---

### Local Filesystem Queue (`local-filesystem`)

| Property | Value |
|----------|-------|
| Type | filesystem |
| Architecture ref | Not applicable (pod-local storage) |
| Purpose | Offline job queue (JSON input files) and intermediate report staging (XLSX/CSV before S3 upload) |
| Ownership | owned |
| Migrations path | Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `CodesForOfflineSearch/Json_Files/*.json` | Job queue entry per offline search request | `user_email`, `user_name`, `Code.codes`, `Code.codetype`, `Code.fileType`, `i18n_country`, `host_name` |
| `CodesForOfflineSearch/Excel_Files/*.xlsx` | Transient local copy of report before S3 upload | Voucher search results |
| `CodesForOfflineSearch/Excel_Files/*.csv` | Transient local CSV copy of report before S3 upload | Voucher search results |
| `CodesForOfflineSearch/sample.lock` | Lock file preventing concurrent offline job execution | Stale timeout: 4 hours |

#### Access Patterns

- **Read**: Offline job scheduler reads the oldest `.json` file in the JSON queue directory each polling cycle
- **Write**: `POST /createJsonFile` writes the job JSON file; offline job writes XLSX/CSV locally before uploading to S3
- **Cleanup**: JSON job files and local report files are deleted after successful S3 upload and email dispatch

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| In-memory (config) | in-memory | `config/base.cson` sets `cache.fromMemory.backend: 'memory'` for ITier config layer | Session-scoped |

## Data Flows

1. Browser submits codes in chunks via `POST /createCodesList` → codes written to S3 as a temporary object.
2. Browser finalises job via `POST /createJsonFile` → codes downloaded from S3, combined into a local JSON file in `CodesForOfflineSearch/Json_Files/`, then the S3 temporary object is deleted.
3. Offline job scheduler polls every 1 minute, picks up the oldest JSON file, performs voucher search across downstream services, generates a local XLSX/CSV report.
4. Report is uploaded to S3; local file is deleted.
5. User downloads the report via `GET /downloadFile` which streams the file directly from S3.
