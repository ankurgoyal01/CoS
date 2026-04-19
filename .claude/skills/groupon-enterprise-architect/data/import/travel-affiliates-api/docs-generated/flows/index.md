---
service: "travel-affiliates-api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Travel Affiliates API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Affiliate Hotel Availability Request](affiliate-hotel-availability.md) | synchronous | HTTPS POST from affiliate partner (Google, TripAdvisor, Trivago) | Partner sends availability query; service maps partner identity, calls Getaways API, and returns hotel pricing |
| [Google Hotel Ads Transaction Query (Live Query)](google-transaction-query.md) | synchronous | HTTPS POST from Google Hotel Ads | Google sends a Live Query XML request; service fetches bundles and pricing from Getaways API and returns a Transaction XML response |
| [Hotel List Feed Generation (On-Demand)](hotel-list-feed-on-demand.md) | synchronous | HTTPS GET from partner or internal trigger | Service aggregates active hotel deals from Getaways API and Deal Catalog, generates XML/JSON feed, uploads to S3 |
| [Scheduled Hotel Feed Export (Cron)](scheduled-hotel-feed-export.md) | scheduled | Kubernetes CronJob (daily 10:00 UTC) | Cron container runs JobRunner, generates hotel feed XML per region, uploads to S3 feed bucket |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

All four flows involve `continuumGetawaysApi` as the primary upstream inventory source. The scheduled feed export flow and the on-demand feed generation flow share the same component pipeline (`ActiveDealsSummaryManager` → `HotelsFeedService` → `AwsFileUploadService` → S3), differing only in how the pipeline is triggered (HTTP vs Kubernetes CronJob).

The affiliate availability flow and the Google transaction query flow share a common dependency on `continuumGetawaysApi` for real-time pricing but use different data shapes: the availability flow returns a JSON `HotelAvailabilityResponse`, while the transaction flow returns Google's XML `Transaction` schema.

Architecture dynamic view reference: `dynamic-affiliate-availability-flow`
