---
service: "getaways-accounting-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumGetawaysAccountingService"]
---

# Architecture Context

## System Context

The Getaways Accounting Service is a backend microservice within Groupon's `continuumSystem` platform. It sits in the Getaways / Travel domain between the Travel Itinerary Service PostgreSQL database (its primary data source) and the Finance / EDW consumers who need reconciled reservation data. It calls out to the Content Service to enrich hotel summary data and pushes completed CSV reports to an SFTP accounting server for downstream financial processing.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Getaways Accounting Service | `continuumGetawaysAccountingService` | Service | Java, Dropwizard | jtier-service-pom 5.14.0 | Dropwizard service that exposes finance and reservations search APIs and produces accounting CSVs for Getaways. |

## Components by Container

### Getaways Accounting Service (`continuumGetawaysAccountingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Finance Resource | Exposes the `GET /v1/finance` endpoint | JAX-RS |
| Reservations Search Resource | Exposes the `GET /v1/reservations/search` endpoint | JAX-RS |
| Finance Service | Builds finance responses from reservations queried by record locator | Java |
| Reservations Search Service | Searches reservations by date range with pagination | Java |
| Reservation Repository | Coordinates reservation queries and domain object mapping | Java |
| Reservation DAO | JDBI-based SQL data access for the TIS PostgreSQL database | JDBI |
| Reservation Mapper | Maps raw database records into domain `Reservation` objects | Java |
| CSV Generation Task | Dropwizard admin task (`POST /tasks/createcsv`) that generates accounting CSVs | Dropwizard Task |
| Summary CSV Builder | Builds summary CSV lines, fetching hotel metadata from Content Service | Java |
| Detail CSV Builder | Builds detailed CSV lines for each reservation transaction | Java |
| CSV Builder | Serialises line objects to CSV files on local storage via Jackson CSV | Java |
| CSV Validator | Downloads uploaded files via SFTP and validates content integrity | Java |
| File Uploader | Uploads CSV and MD5 checksum files over SFTP | Java |
| SFTP Channel | Handles low-level SFTP uploads and downloads using JSch | SFTP / JSch |
| Content Service Client | Fetches hotel metadata for summary lines via Retrofit | Retrofit |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGetawaysAccountingService` | `contentServiceApi_abaf55` | Fetches hotel metadata for CSV summary lines | HTTPS |
| `continuumGetawaysAccountingService` | `tisPostgres_bf2737` | Reads reservation and transaction data | PostgreSQL |
| `continuumGetawaysAccountingService` | `accountingSftpServer_14db43` | Uploads and validates daily CSV accounting files | SFTP |

## Architecture Diagram References

- Component: `getaways-accounting-financeService-components`
