---
service: "payments"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumPaymentsService, continuumPaymentsDb]
---

# Architecture Context

## System Context

The Payments Service sits within the **Continuum** commerce platform as the authoritative system for payment processing. It is called by the Orders Service during checkout to authorize and capture payments, by the API Gateway (Lazlo) for billing and payment operations, and by the Merchant Flutter App for payment schedule retrieval. Externally, it integrates with Payment Gateways (PSPs) that handle the actual credit card, debit card, and alternative payment method processing in a PCI-compliant manner. The service emits structured logs, metrics, and traces to the platform's observability stacks. Its database is replicated to the Enterprise Data Warehouse and BigQuery for analytics and financial reporting.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Payments Service (Kill Bill) | `continuumPaymentsService` | Backend API | Java / Spring Boot | — | Microservice handling payment processing, authorization, capture, and provider routing |
| Payments DB | `continuumPaymentsDb` | Database | MySQL (DaaS) | — | Primary relational store for payment and transaction records; PCI-scoped |

## Components by Container

### Payments Service (Kill Bill) (`continuumPaymentsService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Payments API (`payments_api`) | HTTP endpoints for payment operations (authorization, capture, queries) | Spring Boot |
| Provider Router (`payments_providerRouter`) | Routes payment requests to the configured external payment provider | Spring Boot |
| Payment Repository (`payments_repository`) | CRUD operations for payments and transactions; persists authorization and capture results | JPA |
| Provider Client (`payments_providerClient`) | Integrates with external payment gateways; executes PSP authorization and capture calls | HTTP client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumPaymentsService` | `continuumPaymentsDb` | Reads/writes payment and transaction records | JDBC |
| `continuumOrdersService` | `continuumPaymentsService` | Initiates payment authorization, capture, refund, and billing record operations | JSON/HTTPS |
| `continuumApiLazloService` | `continuumPaymentsService` | Billing/payments operations | HTTP/JSON over internal network |
| `continuumMobileFlutterMerchantApp` | `continuumPaymentsService` | Retrieves payment schedules and payment details | HTTP |
| `continuumPaymentsService` | `paymentGateways` | Processes payments (authorization and capture) via external PSPs | API (SyncAPI, CriticalPath) |
| `continuumPaymentsService` | `loggingStack` | Emits structured logs | Async |
| `continuumPaymentsService` | `metricsStack` | Publishes metrics | Stats/OTel |
| `continuumPaymentsService` | `tracingStack` | Emits distributed traces | OpenTelemetry |
| `continuumPaymentsDb` | `edw` | Replicates payment data for analysis | ETL (Batch) |
| `continuumPaymentsDb` | `bigQuery` | Replicates payment data for analysis | ETL (Batch) |
| `payments_api` | `payments_providerRouter` | Routes payment requests to provider selection logic | Internal |
| `payments_api` | `payments_repository` | Reads/writes payment records | Internal |
| `payments_providerRouter` | `payments_providerClient` | Invokes the selected external provider | Internal |
| `payments_providerClient` | `paymentGateways` | Processes payment with external gateway | payments_api |

## Architecture Diagram References

- System context: `contexts-continuum-payments`
- Container: `containers-continuum-commerce`
- Component: `components-continuum-payments`
- Dynamic (authorization & capture): `dynamic-continuum-payments-service`
- Dynamic (checkout flow): `dynamic-continuum-orders-service`
