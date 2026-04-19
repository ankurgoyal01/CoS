---
service: "coupons-revproc"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Coupons Revproc.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [AffJet Scheduled Ingestion](affjet-scheduled-ingestion.md) | scheduled | Quartz cron per country | Polls AffJet API for affiliate transactions on a rolling 30-day window per country/network variant |
| [Transaction Processing and Finalization](transaction-processing-finalization.md) | synchronous | Per inbound unprocessed transaction | Validates, deduplicates, enriches, persists, and publishes each affiliate transaction |
| [Manual AffJet Ingestion Trigger](manual-affjet-ingestion.md) | synchronous | HTTP POST by operator or internal service | Allows targeted re-ingestion of AffJet transactions with custom date and network filters |
| [Redirect Cache Prefill](redirect-cache-prefill.md) | scheduled | Every 15 minutes (Kubernetes cron job) | Fetches redirect URL mappings from VoucherCloud and stores them in Redis |
| [Coupon Feed Generation and Upload](coupon-feed-generation.md) | scheduled | Daily at 04:00 UTC (Kubernetes cron job) | Builds coupon feed files from processed transactions and uploads to Dotidot SFTP |
| [Processed Transaction Query](processed-transaction-query.md) | synchronous | HTTP GET by internal consumers | Returns processed transactions filtered by click IDs, user IDs, country, and date |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 3 |
| Manual trigger (synchronous) | 1 |

## Cross-Service Flows

- The [Transaction Processing and Finalization](transaction-processing-finalization.md) flow spans `continuumCouponsRevprocService`, `voucherCloudApi`, `continuumCouponsRevprocDatabase`, `messageBus`, and optionally `salesForce`.
- The [AffJet Scheduled Ingestion](affjet-scheduled-ingestion.md) flow spans `continuumCouponsRevprocService` and the external AffJet API (not currently in the federated Structurizr model).
- The [Coupon Feed Generation and Upload](coupon-feed-generation.md) flow spans `continuumCouponsRevprocService` and the external Dotidot SFTP server (not currently in the federated Structurizr model).
