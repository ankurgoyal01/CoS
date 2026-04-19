---
service: "forex-ng"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumForexService"
    - "continuumForexS3Bucket"
    - "continuumForexNetsuiteApi"
---

# Architecture Context

## System Context

Forex NG sits within the Continuum Platform (`continuumSystem`) — Groupon's core commerce engine. It is owned by the Orders team and operates as a supporting infrastructure service that supplies FX rate data to other Continuum services. The service depends on two external resources: the NetSuite exchange-rate scriptlet API (upstream data source) and an AWS S3 bucket (durable rate store). Internal Groupon consumers call the service's REST API directly over HTTP to retrieve conversion rates.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Forex NG Service | `continuumForexService` | Backend | Java, Dropwizard/JTier | 5.14.0 | Internal FX-rates service exposing `/v1/rates` APIs, refreshing rates from NetSuite, and publishing rate files to object storage |
| Forex Rates S3 Bucket | `continuumForexS3Bucket` | Database | AWS S3 | — | Object storage bucket holding published forex rate JSON files and healthcheck artifacts |
| NetSuite Exchange Rates API | `continuumForexNetsuiteApi` | External | HTTPS/REST | — | External NetSuite scriptlet endpoint used to fetch currency exchange-rate CSV exports |

## Components by Container

### Forex NG Service (`continuumForexService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Rates API Resource (`continuumForexService_ratesApiResource`) | Handles `GET /v1/rates/{currencyCode}.json` and `GET /v1/rates/data` endpoints; validates currency code format; returns JSON rate payload | JAX-RS (Jersey) |
| Exchange Rates Updater Job (`continuumForexService_exchangeRatesUpdaterJob`) | Quartz-scheduled job that periodically calls `ForexService.refreshRates()` | Quartz Job |
| Forex Service (`continuumForexService_forexService`) | Orchestrates rate retrieval from the data provider, applies transformations, and persists rates to the store | Service Layer (Java) |
| NetSuite Data Provider (`continuumForexService_netsuiteDataProvider`) | Calls the NetSuite exchange-rate API, validates CSV response headers and content, parses rows into rate maps | Retrofit Client Adapter |
| Rate Store Adapter (`continuumForexService_rateStoreAdapter`) | Abstracts storage backend — selects between in-memory store (development) and AWS S3 store (production) | Storage Adapter (Java) |
| AWS S3 Storage Client (`continuumForexService_s3StorageClient`) | Wraps `S3AsyncClient` from AWS SDK v2; performs concurrent async read, write, copy, and delete operations on S3 rate files | AWS SDK v2 S3AsyncClient Wrapper |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumForexService_ratesApiResource` | `continuumForexService_forexService` | Requests conversion rates for a currency code or pair | Direct (Java) |
| `continuumForexService_exchangeRatesUpdaterJob` | `continuumForexService_forexService` | Triggers scheduled or manual refresh of exchange rates | Direct (Java) |
| `continuumForexService_forexService` | `continuumForexService_netsuiteDataProvider` | Fetches raw FX rate data for all configured currencies | Direct (Java) |
| `continuumForexService_forexService` | `continuumForexService_rateStoreAdapter` | Reads and writes normalized conversion rates | Direct (Java) |
| `continuumForexService_rateStoreAdapter` | `continuumForexService_s3StorageClient` | Persists and retrieves rate JSON files | Direct (Java) |
| `continuumForexService` | `continuumForexNetsuiteApi` | Fetches exchange-rate CSV exports | HTTPS/REST |
| `continuumForexService` | `continuumForexS3Bucket` | Reads and writes conversion rate JSON files | AWS SDK v2 (HTTPS) |
| `continuumForexService` | `loggingStack` | Emits structured Steno application logs | Filebeat / Kafka |
| `continuumForexService` | `metricsStack` | Publishes service and job metrics | Telegraf (UDP/HTTP) |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumForexService`
- Dynamic (rate refresh flow): `dynamic-forex-refresh-rates`
