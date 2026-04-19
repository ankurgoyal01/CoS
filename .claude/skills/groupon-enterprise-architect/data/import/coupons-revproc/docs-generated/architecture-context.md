---
service: "coupons-revproc"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumCoupons"
  containers:
    - "continuumCouponsRevprocService"
    - "continuumCouponsRevprocDatabase"
    - "continuumCouponsRevprocRedis"
---

# Architecture Context

## System Context

`continuumCouponsRevprocService` sits within the Continuum platform's Coupons domain. It is a back-end processing service with no direct consumer-facing surface — it pulls data from the AffJet affiliate network API, enriches transactions using the VoucherCloud API, and pushes results to three downstream systems: the Groupon message bus (`messageBus`), Salesforce (`salesForce`), and the Dotidot SFTP server. It owns two data stores — a MySQL database for durable transaction state and a Redis cache for redirect URL buffering. Upstream callers are limited to internal Groupon services that query processed transactions or trigger manual ingestion via the HTTP API.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Coupons Revproc Service | `continuumCouponsRevprocService` | Backend API + Cron Host | Java / Dropwizard / JTier | 1.36.x | JTier service that ingests affiliate transactions, processes coupon redemptions, and publishes downstream messages |
| Revproc MySQL | `continuumCouponsRevprocDatabase` | Database | MySQL | 5.6+ | Stores processed and unprocessed transactions, merchant slug mappings, Quartz job state, and migrations |
| Revproc Redis | `continuumCouponsRevprocRedis` | Cache | Redis | managed | Caches redirect URL mappings and buffers messages for downstream processing |

## Components by Container

### Coupons Revproc Service (`continuumCouponsRevprocService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Resources (`revproc_apiResources`) | Exposes JAX-RS endpoints for transaction query and manual ingestion triggers | JAX-RS (Dropwizard) |
| AffJet Ingestion Service (`revproc_affJetIngestion`) | Fetches affiliate transactions from AffJet endpoints per country/network; pages through results | Java / Retrofit |
| Transaction Processor (`revproc_transactionProcessor`) | Validates, deduplicates, and transforms inbound unprocessed transactions; fetches click details | Java |
| Processed Transaction Finalizer (`revproc_finalizer`) | Builds Janus click and redemption payloads; persists to MySQL; publishes to Mbus | Java |
| Click Service (`revproc_clickService`) | Fetches click details from VoucherCloud API and maps them into internal Click models | Java |
| Coupons Feed Service (`revproc_feedService`) | Reads processed transactions and builds coupon feed export payloads | Java |
| Coupons Feed Exporter (`revproc_feedExporter`) | Assembles feed files and uploads to Dotidot SFTP | Java / JSch |
| Coupons Redirects Sanitizer (`revproc_redirectsSanitizer`) | Normalizes and sanitizes redirect URLs fetched from VoucherCloud | Java |
| Redirect Cache Service (`revproc_redirectCacheService`) | Manages the in-Redis redirect mapping store | Java / Jedis |
| Redirect Cache Prefill Service (`revproc_redirectCachePrefill`) | Preloads redirect cache from VoucherCloud on a schedule (every 15 min) | Java |
| Salesforce Service (`revproc_salesforceService`) | Sends bonus payment and reconciliation data to Salesforce REST API | Java / SalesforceHttpClient |
| VoucherCloud API Client (`revproc_voucherCloudClient`) | HTTP client for VoucherCloud click, merchant, and redirect endpoints | Retrofit2 / OkHttp |
| Message Bus Client (`revproc_messageBusClient`) | Publishes serialized click and redemption messages to Mbus destinations | JMS / jtier-messagebus-client |
| Transaction DAOs (`revproc_transactionDao`) | JDBI3 DAOs for processed/unprocessed transactions, merchant slug mappings, VoucherCloud domain mappings | JDBI3 |
| Redis Client (`revproc_redisClient`) | Jedis-based access layer for redirect cache and message buffers | Jedis |
| SFTP Client (`revproc_sftpClient`) | Uploads coupon feed files to Dotidot SFTP server | JSch |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCouponsRevprocService` | `continuumCouponsRevprocDatabase` | Reads/writes transactions and Quartz state | JDBC (MySQL) |
| `continuumCouponsRevprocService` | `continuumCouponsRevprocRedis` | Caches redirects and buffers messages | Redis |
| `continuumCouponsRevprocService` | `voucherCloudApi` | Fetches clicks, merchants, and offers | HTTPS |
| `continuumCouponsRevprocService` | `salesForce` | Sends bonus payments and reconciliation updates | HTTPS |
| `continuumCouponsRevprocService` | `messageBus` | Publishes click and redemption messages | JMS |
| `revproc_apiResources` | `revproc_transactionProcessor` | Submits transactions for processing | Direct |
| `revproc_affJetIngestion` | `revproc_transactionProcessor` | Creates unprocessed transactions from AffJet data | Direct |
| `revproc_transactionProcessor` | `revproc_transactionDao` | Persists transaction state | JDBI3 |
| `revproc_finalizer` | `revproc_messageBusClient` | Publishes click/redemption messages | JMS |
| `revproc_feedExporter` | `revproc_sftpClient` | Uploads feed files to Dotidot | SFTP |
| `revproc_redirectCachePrefill` | `revproc_redirectCacheService` | Stores prefilled redirects | Direct |
| `revproc_redirectCacheService` | `revproc_redisClient` | Caches redirect mappings | Redis |

## Architecture Diagram References

- System context: `contexts-continuumCoupons`
- Container: `containers-continuumCouponsRevproc`
- Component: `components-coupons-revproc-components`
