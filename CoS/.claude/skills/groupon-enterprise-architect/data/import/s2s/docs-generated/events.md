---
service: "s2s"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [kafka, mbus]
---

# Events

## Overview

S2S is a predominantly event-driven service. It consumes raw Janus purchase and engagement events from Kafka (`continuumS2sKafka`), applies consent filtering, enriches payloads, and publishes consent-filtered events to outbound Kafka topics. It also consumes MBus booster deal update topics (`continuumS2sMBus`) for DataBreaker ingestion. All partner conversion dispatch (Facebook, Google, TikTok, Reddit) happens as a side effect of consuming inbound Kafka events.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `da_s2s_events` | Consent-filtered S2S event | Janus Tier2/Tier3 event passes consent check | event type, customer hashed PII, order ID, IV/GP value, partner click IDs |
| Partner-specific Kafka topics (Facebook) | Facebook-routed event | Consent-filtered event matches Facebook attribution | CAPI payload: event name, user data (hashed), custom data |
| Partner-specific Kafka topics (Google) | Google-routed event | Consent-filtered event matches Google attribution | Google Ads payload: conversion action, order value, customer match |
| Partner-specific Kafka topics (TikTok) | TikTok-routed event | Consent-filtered event matches TikTok attribution | TikTok event type, platform (web/iOS/Android), user identifiers |
| Partner-specific Kafka topics (Reddit) | Reddit-routed event | Consent-filtered event matches Reddit attribution | Reddit conversion payload, click ID, event value |

### da_s2s_events Detail

- **Topic**: `da_s2s_events`
- **Trigger**: Janus Tier2/Tier3 event is processed by `continuumS2sService_consentEventProcessor` and passes the consent check via Consent Service
- **Payload**: Consent-verified event enriched with IV/GP calculation (from Orders Service and partner click ID cache), hashed customer PII, and grouped purchase batching metadata
- **Consumers**: Partner event processors (Facebook, Google, TikTok, Reddit) consuming from this filtered stream
- **Guarantees**: at-least-once (Kafka consumer with offset commit after processing)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `janus-tier2` | Janus Tier2 purchase/engagement event | `continuumS2sService_consentEventProcessor` | Consent check, IV enrichment, publish to `da_s2s_events` |
| `janus-tier3` | Janus Tier3 purchase/engagement event | `continuumS2sService_consentEventProcessor` | Consent check, IV enrichment, publish to `da_s2s_events` |
| Partner-specific Kafka topics (Facebook) | Facebook-routed consent-filtered event | `continuumS2sService_facebookEventProcessor` | Facebook CAPI dispatch, delayed event queuing on failure |
| Partner-specific Kafka topics (Google) | Google-routed consent-filtered event | `continuumS2sService_googleEventProcessor` | Google Ads/Enhanced Conversions dispatch |
| Partner-specific Kafka topics (TikTok) | TikTok-routed consent-filtered event | `continuumS2sService_tiktokEventProcessor` | TikTok Ads API dispatch (web/iOS/Android) |
| Partner-specific Kafka topics (Reddit) | Reddit-routed consent-filtered event | `continuumS2sService_redditEventProcessor` | Reddit Ads API dispatch, delayed event queuing on failure |
| MBus booster topics (NA/EMEA) | Booster deal update | `continuumS2sService_dataBreakerItemsProcessor` via `continuumS2sService_databreakerMBusMapper` | Deal enrichment (MDS, pricing, deal catalog), DataBreaker items/events ingestion |

### Janus Tier2/Tier3 Detail

- **Topic**: `janus-tier2`, `janus-tier3`
- **Handler**: `continuumS2sService_consentEventProcessor` — filters events, checks consent via `continuumS2sService_consentService`, computes IV/GP via `continuumS2sService_ivCalculationService`, and publishes filtered events to outbound topics
- **Idempotency**: At-least-once delivery; events are deduplicated where possible via Postgres tracking of grouped purchases and delayed events
- **Error handling**: Failed enrichment retried via `continuumS2sService_delayedEventsService` (Postgres-backed replay). Grouped purchase batches persisted by `continuumS2sService_groupedPurchaseEventsService`
- **Processing order**: Unordered (Kafka partition-level ordering; no global ordering guarantee)

### MBus Booster Deal Update Detail

- **Topic**: Regional MBus booster topics (NA and EMEA)
- **Handler**: `continuumS2sService_dataBreakerItemsProcessor` — receives deal updates, routes through `continuumS2sService_databreakerMBusMapper` to enrich with deal catalog, pricing, and MDS data, then posts to DataBreaker
- **Idempotency**: MDS failures are persisted via `continuumS2sService_mdsRetryService` for retry
- **Error handling**: MDS call failures stored in Postgres for scheduled retry. Failed MBus events not explicitly DLQ'd based on available evidence
- **Processing order**: Unordered

## Dead Letter Queues

> No evidence found of explicit DLQ topic configuration in the architecture model. Failed events are persisted to Postgres (`continuumS2sPostgres`) via `continuumS2sService_delayedEventsService` and replayed on schedule or via `/jobs/edw/aesRetry` trigger.
