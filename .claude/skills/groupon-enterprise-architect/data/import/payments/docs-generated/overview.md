---
service: "payments"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Finance & Accounting"
platform: "Continuum"
team: "Payments Team"
status: active
tech_stack:
  language: "Java"
  language_version: ""
  framework: "Spring Boot"
  framework_version: ""
  runtime: "JVM"
  runtime_version: ""
  build_tool: ""
  package_manager: ""
---

# Payments Service Overview

## Purpose

The Payments Service (internally referenced as Kill Bill) is the central payment processing microservice within the Continuum commerce platform. It handles payment authorization, capture, and routing to external payment service providers (PSPs) for all Groupon consumer transactions. The service abstracts gateway complexity behind a unified API, enabling the Orders Service and other upstream callers to process payments without knowledge of the underlying provider.

## Scope

### In scope

- Payment authorization requests from upstream services
- Payment capture operations following successful authorization
- Provider routing to select the appropriate external payment gateway
- Integration with external payment gateways (PSP authorization and capture)
- Persistence of payment and transaction records to the Payments DB
- Payment schedule and detail retrieval for merchant-facing applications
- PCI-compliant handling of payment data

### Out of scope

- Order lifecycle management (owned by `continuumOrdersService`)
- Refund origination decisions (initiated by `continuumOrdersService`; execution may be delegated)
- Billing record storage and deactivation (owned by `continuumOrdersService`)
- User account and billing method management (owned by `continuumUsersService`)
- Deal pricing and discount calculation (owned by `continuumPricingService`)
- Financial reconciliation and accounting (owned by `continuumAccountingService`)
- Fraud screening and risk scoring (owned by `continuumFraudArbiterService`)

## Domain Context

- **Business domain**: Finance & Accounting
- **Platform**: Continuum
- **Upstream consumers**: Orders Service (`continuumOrdersService`), API Gateway/Lazlo (`continuumApiLazloService`), Merchant Flutter App (`continuumMobileFlutterMerchantApp`)
- **Downstream dependencies**: Payment Gateways (`paymentGateways`), Payments DB (`continuumPaymentsDb`), Logging Stack, Metrics Stack, Tracing Stack

## Stakeholders

| Role | Description |
|------|-------------|
| Payments Team | Primary owners; responsible for development, operations, and PCI compliance |
| Orders Team | Primary upstream consumer; depends on payment authorization and capture for order checkout |
| Finance / Accounting | Depends on payment transaction records for reconciliation; Payments DB data replicated to EDW and BigQuery |
| Compliance / Security | Responsible for PCI-DSS audit scope; Payments Service is tagged PCI and CriticalPath |
| Merchant Products | Consumes payment schedule and detail data via Merchant Flutter App |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | — | `continuum-payments-service-components.dsl` (container technology: "Java") |
| Framework | Spring Boot | — | Component technology annotations in DSL ("Spring Boot") |
| Runtime | JVM | — | Implied by Java/Spring Boot |
| Build tool | — | — | > No evidence found in codebase. |
| Package manager | — | — | > No evidence found in codebase. |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Spring Boot | — | http-framework | HTTP endpoint framework for the Payments API |
| JPA | — | orm | Object-relational mapping for payment and transaction persistence |
| HTTP client | — | http-framework | External gateway integration (Provider Client component) |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
