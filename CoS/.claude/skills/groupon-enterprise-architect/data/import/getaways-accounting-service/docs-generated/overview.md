---
service: "getaways-accounting-service"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Getaways / Travel Accounting"
platform: "Continuum"
team: "Getaways Engineering"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Dropwizard"
  framework_version: "via jtier-service-pom 5.14.0"
  runtime: "JVM"
  runtime_version: "11"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Getaways Accounting Service (GAS) Overview

## Purpose

The Getaways Accounting Service (GAS) is a Dropwizard Java microservice that serves as the primary accounting and financial reconciliation engine for Groupon's Getaways hotel-booking platform. It generates daily accounting CSV files (summary and detail) once per day via a scheduled job, and exposes two REST API endpoints consumed by Enterprise Data Warehouse (EDW) and Finance Engineering (FED) teams for reservation lookup and financial reconciliation. It reads reservation and transaction data from the Travel Itinerary Service (TIS) PostgreSQL database and enriches summary reports with hotel metadata from the Content Service.

## Scope

### In scope
- Daily generation of summary and detail accounting CSV reports for hotel reservations
- SFTP upload of CSV files and corresponding MD5 checksum files to the accounting server
- Remote validation of uploaded CSV files after transfer
- REST API endpoint for finance lookup by record locator (`GET /v1/finance`)
- REST API endpoint for paginated reservation search by date range (`GET /v1/reservations/search`)
- MD5 integrity checking of generated and uploaded CSV files

### Out of scope
- Reservation booking, cancellation, or modification (owned by Travel Itinerary Service)
- Hotel content management (owned by Content Service / Getaways Inventory)
- Payment processing
- Consumer-facing UIs or mobile APIs

## Domain Context

- **Business domain**: Getaways / Travel Accounting and Financial Reconciliation
- **Platform**: Continuum (Groupon's core commerce engine)
- **Upstream consumers**: Enterprise Data Warehouse (EDW), Finance Engineering (FED) teams
- **Downstream dependencies**: TIS PostgreSQL database (reservation data), Content Service API (hotel metadata), SFTP accounting server (CSV delivery)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Getaways Engineering — nranjanray (owner) |
| Members | anarao, mann, venkb, sdash |
| Mailing list | getaways-eng@groupon.com |
| Alerts | getaways-gas-alerts@groupon.com |
| On-call | PagerDuty service PN688R9 |
| Finance consumers | EDW and FED teams who consume accounting CSVs and API responses |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `pom.xml` (`project.build.targetJdk`) |
| Framework | Dropwizard (via jtier) | via jtier-service-pom 5.14.0 | `pom.xml` parent |
| Runtime | JVM | 11 | `.ci/Dockerfile` (`dev-java11-maven`) |
| Build tool | Maven | — | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jtier-jdbi | via parent | db-client | JDBI-based JDBC wrapper for PostgreSQL access |
| jtier-daas-postgres | via parent | db-client | Groupon DaaS-managed PostgreSQL connection pooling |
| jtier-retrofit | via parent | http-framework | Retrofit HTTP client for Content Service calls |
| jsch (JSch) | 0.1.54 | sftp | SFTP channel for CSV upload and download |
| jackson-dataformat-csv | via parent | serialization | CSV file generation via Jackson |
| joda-money | 1.0.1 | validation | Monetary amount handling and conversion |
| failsafe | 1.1.0 | validation | Retry and resilience patterns |
| commons-codec | via parent | serialization | MD5 checksum generation |
| stringtemplate | 3.2.1 | db-client | SQL template binding for JDBI queries |
| testcontainers | 1.17.5 | testing | Integration test containers |
| mockito-inline | 3.7.7 | testing | Unit test mocking |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
