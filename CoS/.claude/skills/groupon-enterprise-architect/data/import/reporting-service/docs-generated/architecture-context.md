---
service: "reporting-service"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumReportingApiService", "continuumReportingDb", "continuumDealCapDb", "continuumFilesDb", "continuumVouchersDb", "continuumVatDb", "continuumEuVoucherDb"]
---

# Architecture Context

## System Context

The reporting service is a container within the `continuumSystem` software system — Groupon's core commerce engine. It occupies the merchant operations layer: it reads from multiple Continuum-owned PostgreSQL databases, calls a broad set of internal Continuum APIs (deal catalog, merchant metadata, vouchers, pricing, orders, UGC), stores generated report files on AWS S3, and exchanges events with the Continuum message bus (MBus). Merchants and internal tooling call its REST API to trigger report generation and download finished reports.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Reporting API Service | `continuumReportingApiService` | Service | Java/Spring (WAR) | Java 11, Spring 4.0.7 | Merchant reporting API, report generation, and background processing |
| Reporting Database | `continuumReportingDb` | Database | PostgreSQL | — | Core reporting data store |
| Deal Cap Database | `continuumDealCapDb` | Database | PostgreSQL | — | Deal cap data store for risk and caps |
| Files Database | `continuumFilesDb` | Database | PostgreSQL | — | Metadata store for reporting files |
| Vouchers Database | `continuumVouchersDb` | Database | PostgreSQL | — | Voucher reporting data store |
| VAT Database | `continuumVatDb` | Database | PostgreSQL | — | VAT reporting data store |
| EU Voucher Database | `continuumEuVoucherDb` | Database | PostgreSQL | — | EU voucher reporting data store |

## Components by Container

### Reporting API Service (`continuumReportingApiService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers (`reportingService_apiControllers`) | HTTP endpoints for reporting, bulk redemption, deal cap audit, and VAT invoices | Spring MVC |
| Report Generation (`reportGenerationService`) | Coordinates report creation, template rendering, and artifact storage | Spring |
| Persistence Layer (`reportingService_persistenceDaos`) | Hibernate/JPA DAOs reading and writing all six PostgreSQL databases | Hibernate |
| Campaign Scheduler (`campaignScheduler`) | Weekly summary and campaign automation jobs | Spring Scheduler + ShedLock |
| Deal Cap Scheduler (`dealCapScheduler`) | Daily deal cap trigger and processing | Spring Scheduler + ShedLock |
| MBus Consumers (`reportingService_mbusConsumers`) | Processes inbound PaymentNotification, ugc.reviews, VatInvoicing, and BulkVoucherRedemption messages | MBus |
| MBus Producer (`mbusProducer`) | Publishes BulkVoucherRedemption events | MBus |
| S3 Client (`reportingService_s3Client`) | Uploads and downloads report artifacts to/from AWS S3 | AWS SDK |
| External API Clients (`reportingService_externalApiClients`) | HTTP clients for merchant, deal, voucher, and inventory APIs | HTTP/JSON |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumReportingApiService` | `continuumReportingDb` | Reads and writes reporting data | JDBC |
| `continuumReportingApiService` | `continuumDealCapDb` | Reads and writes deal cap data | JDBC |
| `continuumReportingApiService` | `continuumFilesDb` | Reads and writes file metadata | JDBC |
| `continuumReportingApiService` | `continuumVouchersDb` | Reads voucher reporting data | JDBC |
| `continuumReportingApiService` | `continuumVatDb` | Reads and writes VAT reporting data | JDBC |
| `continuumReportingApiService` | `continuumEuVoucherDb` | Reads EU voucher data | JDBC |
| `continuumReportingApiService` | `continuumPricingApi` | Fetches pricing data | REST |
| `reportingService_apiControllers` | `reportGenerationService` | Submits report generation requests | direct |
| `reportingService_apiControllers` | `reportingService_persistenceDaos` | Reads and writes reporting data | direct |
| `reportingService_apiControllers` | `reportingService_s3Client` | Uploads and downloads files | direct |
| `reportingService_apiControllers` | `mbusProducer` | Publishes bulk redemption events | direct |
| `reportGenerationService` | `reportingService_persistenceDaos` | Reads and writes reporting data | direct |
| `reportGenerationService` | `reportingService_externalApiClients` | Fetches merchant, deal, and inventory data | direct |
| `reportGenerationService` | `reportingService_s3Client` | Stores and retrieves artifacts | direct |
| `reportingService_mbusConsumers` | `reportingService_persistenceDaos` | Persists message data | direct |
| `reportingService_mbusConsumers` | `reportGenerationService` | Triggers reporting workflows | direct |
| `campaignScheduler` | `reportGenerationService` | Runs scheduled campaign reports | direct |
| `dealCapScheduler` | `reportingService_persistenceDaos` | Updates deal cap state | direct |
| `dealCapScheduler` | `reportingService_externalApiClients` | Queries deal/merchant status | direct |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `Reporting-reportGenerationService-Containers`
- Component: `Reporting-API-Components`
