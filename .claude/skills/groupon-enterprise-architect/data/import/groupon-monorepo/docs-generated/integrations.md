---
service: "groupon-monorepo"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 14
internal_count: 9
---

# Integrations

## Overview

The Encore Platform integrates with 14 external systems and 9 internal Continuum legacy services. External integrations span CRM (Salesforce), analytics (BigQuery, Teradata), media processing (Mux, Bynder), messaging (Twilio, SendGrid), personalization (Bloomreach), search (Vespa.ai, Booster), and location (Google Places). Internal integrations wrap Continuum legacy services through dedicated proxy services, enabling gradual migration while maintaining backward compatibility.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | REST (jsforce) | CRM bidirectional sync for accounts and deals | yes | `salesForce` |
| BigQuery | REST (googleapis) | Analytics queries, deal alert data, reporting | yes | `bigQuery` |
| Mux | REST (mux-node SDK) | Video upload, transcoding, playback | no | `mux` |
| Twilio | REST (Twilio SDK) | SMS messaging and delivery tracking | no | `twilio` |
| SendGrid | REST (@sendgrid/mail) | Transactional email delivery | no | -- |
| Bloomreach | REST | Personalization and search integration | no | `bloomreach` |
| Bynder | REST | Digital asset management | no | `bynderService` |
| Google Places | REST (googleapis) | Place lookup and merchant location enrichment | no | `googlePlaces` |
| Vespa.ai | REST (HTTP/2) | Search and deal recommendations | yes | -- |
| Booster | REST (HMAC-signed) | Personalized deal recommendations | yes | `booster` |
| Teradata EDW | ODBC (teradatasql) | Legacy enterprise data warehouse queries | no | `edw` |
| GitHub Enterprise | REST | Webhook triggers, deployment automation | no | `githubEnterprise` |
| Atlassian (Jira/Confluence) | REST | Ticket integration, documentation sync | no | -- |
| OpenAI / Anthropic | REST (LLM SDKs) | AI/LLM inference for content generation | no | -- |

### Salesforce Detail

- **Protocol**: REST via jsforce SDK
- **Base URL / SDK**: jsforce v3.9.1 (`apps/encore-ts/services/_tribe_b2b/salesforce/`)
- **Auth**: OAuth 2.0 (Salesforce Connected App)
- **Purpose**: Bidirectional sync of merchant accounts, deal metadata, and sales pipeline data. Account records are synced periodically and on-demand. AIDG service uses Salesforce data for AI deal generation context.
- **Failure mode**: Account sync fails; local data becomes stale. Deal creation can continue without Salesforce sync. Pub/Sub events queue for retry.
- **Circuit breaker**: Graceful degradation -- sync failures are logged and retried via scheduled crons.

### BigQuery Detail

- **Protocol**: REST via googleapis SDK
- **Base URL / SDK**: googleapis v148.0.0 (`apps/encore-ts/services/_core_system/big-query/`)
- **Auth**: GCP Service Account (key in Encore secrets)
- **Purpose**: Analytics queries for deal performance dashboards, alert threshold calculations, and reporting. Read-only access.
- **Failure mode**: Analytics dashboards show stale data; alerts may not trigger. Core deal operations unaffected.
- **Circuit breaker**: No (read-only, non-critical path)

### Mux Detail

- **Protocol**: REST via @mux/mux-node SDK v11.1.0
- **Base URL / SDK**: `apps/encore-ts/services/_core_system/video/`
- **Auth**: Mux API token (Encore secrets)
- **Purpose**: Video upload, transcoding, and playback URL generation for deal media.
- **Failure mode**: Video uploads fail; text and image content unaffected.
- **Circuit breaker**: No

### Booster Detail

- **Protocol**: REST with HMAC-SHA1 authentication
- **Base URL / SDK**: Custom Go HTTP client (`apps/encore-go/gorapi/internal/infrastructure/clients/booster/`)
- **Auth**: HMAC-SHA1 (timestamp + URL path hash)
- **Purpose**: Personalized deal recommendations and search ranking for autocomplete and discovery.
- **Failure mode**: Recommendations fall back to Vespa.ai adapter or return empty results.
- **Circuit breaker**: Configurable adapter switch (Booster vs Vespa)

### Vespa.ai Detail

- **Protocol**: REST (HTTP/2) with connection pooling
- **Base URL / SDK**: Custom Go HTTP client (`apps/encore-go/vespa-reader/`)
- **Auth**: Certificate-based
- **Purpose**: Full-text deal search with faceting, filtering, and ranking.
- **Failure mode**: Search returns empty results; autocomplete degrades.
- **Circuit breaker**: Retry with exponential backoff, rate limiting for 429 responses

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Continuum Orders Service | REST | Order management and status queries | `continuumOrdersService` |
| Continuum Deal Management API (DMAPI) | REST | Deal creation, update, publishing to legacy system | `continuumDealManagementApi` |
| Continuum Universal Merchant API (UMAPI) | REST | Merchant data lookup and updates | `continuumUniversalMerchantApi` |
| Continuum Lazlo Service | REST | Deal data enrichment and detail decoration | `continuumApiLazloService` |
| Continuum Bhuvan Service | REST | Merchant data service for extended attributes | `continuumBhuvanService` |
| Continuum M3 Merchant Service | REST | M3 merchant data integration | `continuumM3MerchantService` |
| Continuum M3 Places Service | REST | M3 place read integration | `continuumM3PlacesService` |
| Continuum Users Service | REST | Legacy user profile lookup | `continuumUsersService` |
| Continuum Marketing Deal Service | REST | Legacy marketing deal data | `continuumMarketingDealService` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Admin React Frontend | REST (generated TS client) | All admin operations |
| AIDG React Frontend | REST (generated TS client) | AI deal generation workflows |
| Support Angular Frontend | REST (generated TS client) | Customer support operations |
| IQ Chrome Extension | REST (generated TS client) | Internal productivity features |
| MBNXT Consumer Frontend | REST | Consumer-facing deal display (via Go search APIs) |

> Additional upstream consumers are tracked in the central architecture model.

## Dependency Health

- **Encore Built-in Health**: Encore Cloud provides built-in health monitoring for all services, with automatic restart on crash.
- **Legacy Service Wrappers**: Continuum proxy services (UMAPI, DMAPI, Lazlo, Bhuvan) include timeout configuration and error mapping. Failures are logged and surfaced in the admin UI.
- **Go Service Resilience**: The Go backend implements connection pooling, retry with exponential backoff (5xx only), and HTTP/2 keep-alive for Vespa.ai. DealDataProvider uses Redis cache with Lazlo fallback and async refresh.
- **Kafka Bridge**: Kafka consumer includes offset management and reconnection logic. Message processing failures trigger Encore Pub/Sub retry.
- **STOMP Message Bus**: The mbus publisher/subscriber includes STOMP reconnection handling with a cron-based stop/start mechanism.
