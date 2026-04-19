---
service: "transporter-itier"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

Transporter I-Tier is stateless and does not own any data stores. All persistent state — Salesforce job records, upload history, and S3 file references — is owned and managed by `transporter-jtier`. The I-Tier service fetches data from jtier on every request and does not maintain a local database, cache, or persistent file system store.

The upload proxy buffers an incoming CSV file in memory (via multer's `memoryStorage()`) only for the duration of the HTTP proxy request before streaming the binary to jtier. No data is written to disk.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase.

The ITier framework dependency `itier-cached` (^7.4.1) is listed in `package.json` but no caching configuration or usage was identified in the application module code. No Redis or Memcached client is configured.

## Data Flows

All data originates from or terminates in `transporter-jtier`:

- The job list page (`/`) reads paginated upload job records from jtier `GET /getUploads`.
- The job description page (`/job-description`) reads a single job record from jtier `GET /getUploadsById`.
- The new-upload page (`/new-upload`) validates the user via jtier `GET /validUser` and reads user info from jtier `GET /userInfo`.
- The upload proxy (`/jtier-upload-proxy`) buffers a CSV file in memory and streams it to jtier `POST /v0/upload`.
- The file download endpoint (`/get-aws-csv-file`) streams a file from jtier `GET /getAWSFile`.
- The Salesforce read-only pages (`/sfdata`) retrieve available object types from jtier `GET /sfObjects` and individual records from jtier `GET /getSfObject`.
