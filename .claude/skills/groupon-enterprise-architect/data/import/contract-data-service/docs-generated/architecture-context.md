---
service: "contract-data-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "continuumContractDataService"
    - "continuumContractDataServicePostgresRw"
    - "continuumContractDataServicePostgresRo"
---

# Architecture Context

## System Context

Contract Data Service sits within the Continuum platform as the authoritative data store for merchant contracts. It is called by internal services that need contract, term, or invoicing data. For historical data migration, CoDS reaches out to the Deal Management API (`continuumDealManagementApi`) to pull legacy deal/contract records and to Deal Catalog Service (`continuumDealCatalogService`) to resolve secondary deal associations. The service is SOX-scoped and resides in the `sox-inscope` GitHub organization.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Contract Data Service | `continuumContractDataService` | Backend service | Java/Dropwizard | 1.0.x | Canonical source of merchant contract information, including payment terms, source, and party. |
| Contract Data Service DB (RW) | `continuumContractDataServicePostgresRw` | Database | PostgreSQL | 9.4+ | Primary read/write Postgres database for contract data. |
| Contract Data Service DB (RO) | `continuumContractDataServicePostgresRo` | Database | PostgreSQL | 9.4+ | Read-only Postgres replica for contract data reads. |

## Components by Container

### Contract Data Service (`continuumContractDataService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `cds_contractResource` | Accepts POST requests to create aggregate contract records (party + terms + invoicing config) | JAX-RS |
| `cds_contractTermResource` | Accepts POST to upsert contract terms by hash; GET to retrieve a term by UUID | JAX-RS |
| `cds_contractPartyResource` | Accepts PUT to upsert contract parties; GET to retrieve a party by contract ID | JAX-RS |
| `cds_paymentInvoicingConfigResource` | Accepts PUT to upsert invoicing configurations; GET to retrieve by external reference ID | JAX-RS |
| `cds_backfillDealResource` | Accepts GET to trigger backfill of legacy deal data from DMAPI and Deal Catalog | JAX-RS |
| `cds_clientIdRequestFilter` | Validates `CLIENT-ID` header on all inbound requests | Jersey Filter |
| `cds_contractTermDao` | Writes contract terms, external IDs, amounts, adjustments, event actions to Postgres (RW) | JDBI DAO |
| `cds_contractTermReadOnlyDao` | Reads contract terms and related entities from Postgres (RO) | JDBI DAO |
| `cds_paymentInvoicingConfigDao` | Writes payment invoicing configuration records to Postgres (RW) | JDBI DAO |
| `cds_paymentInvoicingConfigReadOnlyDao` | Reads payment invoicing configuration records from Postgres (RO) | JDBI DAO |
| `cds_contractPartyDao` | Writes contract party records to Postgres (RW) | JDBI DAO |
| `cds_contractPartyReadOnlyDao` | Reads contract party records from Postgres (RO) | JDBI DAO |
| `cds_clientIdReadOnlyDao` | Reads client ID configuration from Postgres (RO) for request filter validation | JDBI DAO |
| `cds_dealManagementApiClient` | Retrofit HTTP client for outbound calls to Deal Management API (v1 and v2) | Retrofit HTTP Client |
| `cds_dealCatalogApiClient` | Retrofit HTTP client for outbound calls to Deal Catalog Service | Retrofit HTTP Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumContractDataService` | `continuumContractDataServicePostgresRw` | reads/writes contract data | JDBI/PostgreSQL |
| `continuumContractDataService` | `continuumContractDataServicePostgresRo` | reads contract data | JDBI/PostgreSQL |
| `continuumContractDataService` | `continuumDealManagementApi` | backfills deal data | HTTP |
| `continuumContractDataService` | `continuumDealCatalogService` | backfills catalog data | HTTP |
| `cds_contractTermResource` | `cds_contractTermDao` | writes contract terms | JDBI |
| `cds_contractTermResource` | `cds_contractTermReadOnlyDao` | reads contract terms | JDBI |
| `cds_contractTermResource` | `cds_paymentInvoicingConfigReadOnlyDao` | reads invoicing configuration | JDBI |
| `cds_paymentInvoicingConfigResource` | `cds_paymentInvoicingConfigDao` | writes invoicing configuration | JDBI |
| `cds_paymentInvoicingConfigResource` | `cds_paymentInvoicingConfigReadOnlyDao` | reads invoicing configuration | JDBI |
| `cds_contractPartyResource` | `cds_contractPartyDao` | writes contract parties | JDBI |
| `cds_contractPartyResource` | `cds_contractPartyReadOnlyDao` | reads contract parties | JDBI |
| `cds_contractResource` | `cds_contractPartyDao` | reads/writes contract parties | JDBI |
| `cds_contractResource` | `cds_contractTermReadOnlyDao` | reads contract terms | JDBI |
| `cds_backfillDealResource` | `cds_dealManagementApiClient` | fetches deal data | HTTP |
| `cds_backfillDealResource` | `cds_dealCatalogApiClient` | fetches catalog data | HTTP |
| `cds_clientIdRequestFilter` | `cds_clientIdReadOnlyDao` | loads client ID configuration | JDBI |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-contract-data-service-components`
- Dynamic view: `dynamic-contract-data-service-backfill-sync`
