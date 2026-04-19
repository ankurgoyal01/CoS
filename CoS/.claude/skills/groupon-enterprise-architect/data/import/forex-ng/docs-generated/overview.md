---
service: "forex-ng"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Orders / Payments"
platform: "Continuum"
team: "orders"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard / JTier"
  framework_version: "5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Forex NG Overview

## Purpose

Forex NG is Groupon's internal foreign exchange rates service. It fetches daily currency conversion rates from NetSuite's exchange-rate API endpoint, validates and persists them to an AWS S3 bucket, and exposes an internal REST API that allows other Groupon services to query ISO 4217 currency conversion rates by base currency or base/quote currency pair. The service ensures rate freshness through a scheduled Quartz job and sanity-checks every rate update before it is published.

## Scope

### In scope

- Fetching exchange rates for 46 configured ISO 4217 currencies from NetSuite's exchange-rate CSV export endpoint
- Validating fetched rate data (header format, currency matching, data freshness checks)
- Writing validated rate JSON files to AWS S3 (`v1/rates/{currency}.json`)
- Performing multi-step sanity checks on staged rates before promoting them to the live S3 directory
- Serving live rate lookups via `GET /v1/rates/{currency}.json` REST endpoint
- Scheduling periodic rate refresh via a Quartz cron job (every 11 minutes in cloud production)
- Supporting an admin data-refresh endpoint `GET /v1/rates/data`
- Providing a CLI command `refresh-rates` for on-demand or cron-job-driven rate updates

### Out of scope

- Currency conversion arithmetic (the service provides rates only, not computed converted amounts)
- Merchant or consumer billing — currency conversion for actual orders is performed by downstream order services
- Real-time tick-by-tick market rate data (rates are refreshed on a scheduled basis, not streamed)
- NetSuite ERP integration beyond the exchange-rate scriptlet endpoint

## Domain Context

- **Business domain**: Orders / Payments
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon services requiring foreign exchange rates (e.g., order pricing, checkout, reporting). Consumers are tracked in the central architecture model.
- **Downstream dependencies**: NetSuite Exchange Rates API (`https://1202613.extforms.netsuite.com/app/site/hosting/scriptlet.nl`), AWS S3 (forex rates bucket)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Orders team (`forex@groupon.com`) |
| Team Lead | adisharma |
| SRE / On-Call | forex-alerts@groupon.com, PagerDuty P4TZ4L9 |
| Slack Channel | #orders-and-payments |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `src/main/docker/Dockerfile` (prod-java11-jtier base image) |
| Framework | Dropwizard via JTier | 5.14.0 | `pom.xml` — parent `jtier-service-pom:5.14.0` |
| Runtime | JVM | 11 | `.ci/Dockerfile` (dev-java11-maven base image) |
| Build tool | Maven | 3.6.3 | `mvnvm.properties` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `software.amazon.awssdk:s3` | 2.9.10 (BOM) | db-client | Async S3 reads, writes, copies, and deletes for forex rate files |
| `software.amazon.awssdk:sts` | 2.9.10 (BOM) | auth | AWS STS for web identity token credential exchange |
| `com.groupon.jtier:jtier-quartz-bundle` | via JTier BOM | scheduling | Quartz scheduler integration for periodic rate refresh jobs |
| `com.groupon.jtier.http:jtier-retrofit` | via JTier BOM | http-framework | Retrofit HTTP client bundle for calling NetSuite REST endpoint |
| `org.apache.httpcomponents:httpclient` | 4.5.9 | http-framework | Underlying HTTP transport for Retrofit |
| `com.fasterxml.jackson` | via JTier BOM | serialization | JSON serialization/deserialization of forex rate models |
| `com.fasterxml.jackson.datatype:guava` | via JTier BOM | serialization | Guava type support in Jackson (SortedMap, ImmutableMap) |
| `org.immutables:value` | via JTier BOM | serialization | Immutable value types for `ForexRate` model |
| `com.arpnetworking.steno` | via JTier BOM | logging | Structured Steno JSON logging |
| `com.codahale.metrics` | via JTier BOM | metrics | Dropwizard health check and metrics registry |
| `io.swagger:annotations` | via JTier BOM | validation | Swagger/OpenAPI annotation support on JAX-RS resources |
| `org.quartz-scheduler:quartz` | via JTier BOM | scheduling | Quartz job execution engine |
| `net.sourceforge.argparse4j` | via JTier BOM | validation | CLI argument parsing for `RefreshRatesCommand` |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
