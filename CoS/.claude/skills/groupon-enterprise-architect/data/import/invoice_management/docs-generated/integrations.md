---
service: "invoice_management"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 6
---

# Integrations

## Overview

invoice_management integrates with two external systems (NetSuite and AWS S3) and six internal Continuum/Goods platform services. The most critical external integration is NetSuite, which is the financial system of record for all invoices and payments. Internal integrations cover messaging (Message Bus), order data, shipment tracking, email notification, and accounting. The service is both a producer (NetSuite transmissions, S3 uploads) and a consumer (Message Bus events, Shipment Tracker queries).

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| NetSuite | rest (OAuth 1.0a) | Invoice transmission and payment pull; financial system of record | yes | > No Structurizr ID in inventory. |
| AWS S3 | sdk | Remittance report file storage | yes | > No Structurizr ID in inventory. |

### NetSuite Detail

- **Protocol**: REST / HTTPS
- **Base URL / SDK**: NetSuite REST API (SuiteTalk REST or SuiteScript endpoint)
- **Auth**: OAuth 1.0a via `scribe` library 1.3.7 — consumer key, consumer secret, token, and token secret
- **Purpose**: Receives invoice transmissions from IAS for Goods vendor invoicing; provides payment data pulled by IAS for reconciliation; sends payment status callbacks to `/ns_callback`
- **Failure mode**: Critical — invoice transmission and payment reconciliation halt; invoices queue up in PostgreSQL pending retry; Quartz scheduler retries on next scheduled run
- **Circuit breaker**: > No evidence found in codebase.

### AWS S3 Detail

- **Protocol**: AWS SDK (`aws-java-sdk` 1.11.402)
- **Base URL / SDK**: AWS SDK S3 client (`AmazonS3Client`)
- **Auth**: AWS IAM credentials (access key + secret key or IAM role)
- **Purpose**: Upload generated Excel remittance reports for vendor and finance consumption
- **Failure mode**: Remittance report upload fails; report is generated but not persisted; Quartz scheduler retries on next run
- **Circuit breaker**: > No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Message Bus | mbus | Consumes PO, Receiver, SRS, GMO, STS events | > No Structurizr ID in inventory. |
| Rocketman (email service) | rest | Sends invoice and remittance notification emails to vendors | > No Structurizr ID in inventory. |
| Shipment Tracker | rest | Queries shipment status for invoice and PO enrichment | > No Structurizr ID in inventory. |
| Goods Stores API | rest | Queries vendor/store data for invoice creation and enrichment | > No Structurizr ID in inventory. |
| Accounting Service | rest | Sends accounting entries for invoice lifecycle events | > No Structurizr ID in inventory. |
| Commerce Interface | rest | Queries order data to correlate with invoices | > No Structurizr ID in inventory. |
| GPAPI | rest | Queries goods platform data for invoice context | > No Structurizr ID in inventory. |

### Message Bus Detail

- **Protocol**: Groupon Message Bus (`mbus-client` 1.2.7)
- **Auth**: Internal mbus authentication
- **Purpose**: Primary event source — PO events trigger invoice creation; Receiver events create receiver records; GMO events trigger marketplace invoice creation; SRS and STS events update invoice/shipment state
- **Failure mode**: If mbus is unavailable, event processing halts; events will be redelivered upon reconnection per mbus guarantees

### Rocketman Detail

- **Protocol**: REST / HTTP
- **Auth**: Internal service-to-service auth
- **Purpose**: Sends email notifications to vendors when invoices are ready and remittance reports are uploaded
- **Failure mode**: Non-critical — invoice processing continues; email not sent; operators can retry manually

## Consumed By

> Upstream consumers are tracked in the central architecture model. invoice_management REST endpoints are consumed by internal Goods finance tooling and scheduled operational scripts.

## Dependency Health

> No evidence found in codebase for explicit circuit breaker or health check patterns beyond Quartz scheduler retry logic. NetSuite and AWS S3 failures are handled by job rescheduling. Refer to the [Runbook](runbook.md) for dependency failure procedures.
