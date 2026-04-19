---
service: "transporter-jtier"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Transporter JTier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Salesforce User Authentication](salesforce-user-authentication.md) | synchronous | POST /v0/auth from Transporter ITier | Exchanges a Salesforce OAuth auth code for an access token and caches it in Redis |
| [CSV Upload Submission](csv-upload-submission.md) | synchronous | POST /v0/upload from Transporter ITier | Accepts a CSV file, persists an upload job record to MySQL, and stages the file to AWS S3 |
| [Bulk Salesforce Upload (Worker Job)](bulk-salesforce-upload-worker.md) | scheduled | Quartz scheduler (sf-upload-worker) | Reads pending upload jobs, fetches CSV from S3, executes Salesforce bulk operations, and writes results to GCS |
| [Upload Status Query](upload-status-query.md) | synchronous | GET /v0/getUploads or /v0/getUploadsById from ITier | Returns upload job list or a specific job record from MySQL |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The CSV Upload Submission flow initiates work that is completed asynchronously by the Bulk Salesforce Upload worker flow. ITier polls status via Upload Status Query.
- All synchronous flows pass through the Edge Proxy (Envoy) before reaching the `api` component.
- The `sf-upload-worker` component operates independently on a Quartz schedule and does not respond to HTTP requests.
