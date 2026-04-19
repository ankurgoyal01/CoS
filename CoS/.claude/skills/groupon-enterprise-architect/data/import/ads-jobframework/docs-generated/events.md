---
service: "ads-jobframework"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

ads-jobframework does not participate in any Kafka, RabbitMQ, or other async message broker. All data movement is handled via batch Spark SQL reads from Hive tables and outbound HTTP callbacks to third-party ad attribution APIs (CitrusAd, DoubleClick). The service treats Hive table partitions as its implicit event-log input — job runs scan time-bounded partitions of `grp_gdoop_pde.junoHourly` rather than consuming a real-time event stream.

## Published Events

> No evidence found in codebase. This service does not publish to any message broker or event bus.

The service does emit the following outbound HTTP callbacks that function as attribution events to external ad platforms:

| Target System | Endpoint | Trigger | Payload |
|---------------|----------|---------|---------|
| CitrusAd | `GET /v1/resource/first-i/{adId}` | Impression detected in `grp_gdoop_pde.junoHourly` | Ad ID in URL path |
| CitrusAd | `GET /v1/resource/second-c/{adId}` | Click detected in `grp_gdoop_pde.junoHourly` | Ad ID in URL path |
| DoubleClick / Clarus | `GET https://ad.doubleclick.net/ddm/trackimp/...` | Impression detected in `grp_gdoop_pde.junoHourly` | Full tracking URL from `clarus.url` config |

## Consumed Events

> No evidence found in codebase. This service does not subscribe to any message broker topics.

The service consumes data by running Spark SQL queries against these Hive table partitions, which act as durable event logs:

| Hive Table | Partition Key | Data Consumed |
|-----------|---------------|---------------|
| `grp_gdoop_pde.junoHourly` | `eventdate`, `eventtime` | Impressions, clicks, page views, email events, coupon redemptions |
| `user_edwprod.fact_gbl_transactions` | `ds` | Order authorizations and captures |
| `cia_realtime.user_attrs_gbl` | `record_date` | Global customer demographic attributes |
| `cia_realtime.user_attrs` | `record_date` | User behavioral attributes for uplift modeling |
| `cia_realtime.user_attr_daily` | `record_date` | Daily user attribute snapshots |
| `grp_gdoop_marketing_analytics_db.me_orders_fgt` | `transaction_date` | Marketing order fact data for attribution joins |

## Dead Letter Queues

> No evidence found in codebase. No DLQ infrastructure is in use.

Failed HTTP callbacks to CitrusAd or DoubleClick are logged and counted via the `citrus_impressions_report_exception` / `citrus_clicks_report_exception` metrics counters. There is no automatic retry or DLQ mechanism — failed callbacks are counted but not replayed automatically. The backfill jobs (`CitrusAdImpressionsReportBackfillJob`, `CitrusAdClicksReportBackfillJob`) serve as the manual replay mechanism.
