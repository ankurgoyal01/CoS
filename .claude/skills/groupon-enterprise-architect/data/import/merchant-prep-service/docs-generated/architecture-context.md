---
service: "merchant-prep-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumMerchantPrepService, continuumMerchantPrepPrimaryDb, continuumMerchantPrepMecosDb]
---

# Architecture Context

## System Context

The Merchant Preparation Service (`continuumMerchantPrepService`) belongs to the Continuum platform and sits within the Merchant Experience domain. It operates behind UMAPI, acting as the backend for Merchant Center's deal self-prep workflow. Merchants interact with the service through the Merchant Center front-end; the service reads and writes account, opportunity, and contact data to Salesforce and persists workflow tracking state in its own PostgreSQL databases. It emits merchant-setting-update events to the internal message bus and calls several downstream Continuum services for notifications, accounting, contracts, and merchant profiles.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Merchant Prep Service | `continuumMerchantPrepService` | Service / API | Java, Dropwizard/JTier | 5.14.0 | Backend service for merchant self-prep workflows, onboarding, verification, and account updates |
| Merchant Prep Primary DB | `continuumMerchantPrepPrimaryDb` | Database | PostgreSQL | — | Primary database storing merchant prep state, onboarding checklists, audit entries, TIN validation results, and scheduled-job data |
| Merchant Prep MECOS DB | `continuumMerchantPrepMecosDb` | Database | PostgreSQL | — | Read-only merchant backend configuration (MECOS) database |

## Components by Container

### Merchant Prep Service (`continuumMerchantPrepService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Merchant Prep API (`mps_merchantPrepApi`) | REST resources handling all merchant self-prep and onboarding endpoints | JAX-RS / Dropwizard |
| Onboarding Domain Services (`mps_onboardingDomain`) | Business logic for onboarding, verification, finance, payment-hold, and contract flows | Java Services |
| Persistence Layer (`mps_persistenceLayer`) | JDBI DAOs and Flyway-migration-backed adapters for PostgreSQL access | JDBI 3 / PostgreSQL |
| Integration Clients (`mps_integrationClients`) | Retrofit HTTP clients for Salesforce and all downstream services | Retrofit 2 / RxJava 3 |
| Scheduled Jobs (`mps_scheduledJobs`) | Quartz jobs for periodic merchant last-login sync and monthly survey dispatch | Quartz |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMerchantPrepService` | `continuumMerchantPrepPrimaryDb` | Stores merchant prep state and workflow data | JDBC |
| `continuumMerchantPrepService` | `continuumMerchantPrepMecosDb` | Reads merchant backend configuration | JDBC |
| `continuumMerchantPrepService` | `salesForce` | Reads and updates account, opportunity, and contact data | REST |
| `continuumMerchantPrepService` | `continuumM3MerchantService` | Retrieves merchant profile and account data | REST |
| `continuumMerchantPrepService` | `notsService` | Sends merchant notifications | REST |
| `continuumMerchantPrepService` | `messageBus` | Publishes merchant setting update events | JMS topic |
| `continuumMerchantPrepService` | `continuumAccountingService` | Checks accounting and payment hold information | REST |
| `continuumMerchantPrepService` | `continuumContractService` | Reads contract details | REST |

## Architecture Diagram References

- Component: `components-merchant-prep-service`
