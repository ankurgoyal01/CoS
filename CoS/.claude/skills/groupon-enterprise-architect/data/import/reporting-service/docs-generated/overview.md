---
service: "reporting-service"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Merchant Reporting"
platform: "Continuum"
team: "MX Platform Team"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Spring Framework"
  framework_version: "4.0.7"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Reporting Service (mx-merchant-reporting) Overview

## Purpose

The reporting service (mx-merchant-reporting) is the merchant-facing reporting API within the Continuum platform. It generates, renders, and delivers deal performance reports in multiple formats (Excel, CSV, PDF), processes bulk voucher redemptions via CSV upload, enforces deal caps, and manages VAT invoicing. The service bridges multiple Continuum data stores and upstream APIs to produce consolidated merchant analytics.

## Scope

### In scope

- Generating merchant deal performance reports on demand and on schedule
- Rendering reports as Excel (Apache POI), CSV (SuperCSV), and PDF (Flying Saucer) files
- Storing and retrieving report artifacts on AWS S3
- Processing bulk voucher redemption uploads via CSV
- Enforcing deal cap limits through scheduled and event-driven checks
- Consuming payment, UGC review, VAT invoicing, and bulk redemption messages from the message bus
- Producing the weekly campaign summary report via scheduler
- Managing VAT invoice creation and retrieval
- Providing a deal cap audit trail via REST API

### Out of scope

- Merchant authentication and identity (handled by upstream API gateways and identity services)
- Deal creation and campaign management (handled by Deal Catalog and related services)
- Real-time order and payment processing (handled by Orders and Payments services)
- Consumer-facing voucher delivery (handled by VIS and voucher services)
- Raw data warehousing and long-term analytics (handled by Teradata integration, read-only from this service)

## Domain Context

- **Business domain**: Merchant Reporting
- **Platform**: Continuum
- **Upstream consumers**: Merchant portal clients, internal tools consuming the reporting API
- **Downstream dependencies**: Deal Catalog (`dcApi`), FED (`fedApi`, `fedVatApi`), M3 Merchant (`m3Api`, `m3PlacesApi`), GIA (`giaApi`), Booking Tool (`bookingToolApi`), VIS (`visApi`), Orders (`ordersApi`), UGC (`ugcApi`), Taxonomy (`taxonomyApi`), Refunds (`rrApi`), Geoplaces (`geoplacesApi`), NOTS (`notsApi`), Localization (`localizeApi`), Pricing (`continuumPricingApi`), Teradata (`teradataWarehouse`), AWS S3 (`reportingS3Bucket`), MBus (`mbus`)

## Stakeholders

| Role | Description |
|------|-------------|
| MX Platform Team | Service owner; responsible for development, operations, and on-call |
| Merchants | End consumers of generated reports via merchant portal |
| Finance / Accounting | Consumers of VAT invoicing and deal settlement data |
| Operations | Users of deal cap audit and bulk redemption tooling |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | Summary |
| Framework | Spring Framework | 4.0.7 | Summary |
| Runtime | JVM | 11 | Summary |
| Build tool | Maven | — | Summary |
| Package manager | Maven | — | Summary |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Spring MVC | 4.0.7 | http-framework | REST controller layer and HTTP dispatching |
| Hibernate | 3.6.10 | orm | ORM and JPA DAO layer for all six PostgreSQL databases |
| PostgreSQL JDBC | 42.7.3 | db-client | JDBC driver for all PostgreSQL connections |
| AWS SDK (S3/STS) | — | storage-client | Upload and download of report artifacts to/from S3 |
| ShedLock | 1.2.0 | scheduling | Distributed lock for scheduled jobs (campaign, deal cap) |
| Apache POI | 3.13 | serialization | Excel report rendering (.xls/.xlsx) |
| SuperCSV | 2.2.0 | serialization | CSV report generation and bulk redemption file parsing |
| Flying Saucer PDF | 9.0.6 | serialization | PDF report rendering from HTML/FreeMarker templates |
| FreeMarker | 2.3.20 | serialization | Template engine for PDF/HTML report generation |
| EhCache | 2.10.1 | state-management | In-process caching for reference data (deals, merchants) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
