---
service: "rbac"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Identity / Access Control"
platform: "Continuum"
team: "Merchant Experience (MX)"
status: active
tech_stack:
  language: "Java"
  language_version: "21"
  framework: "Spring Boot"
  framework_version: "3.2.5"
  runtime: "JVM"
  runtime_version: "21"
  build_tool: "Maven"
  package_manager: "Maven (mvnw wrapper)"
---

# RBAC Overview

## Purpose

The RBAC service (Groupon Merchant Access) is a centralized role-based access control system for Groupon's internal services. It manages the full lifecycle of roles, permissions, categories, and scope types, and enforces authorization decisions for internal tooling. The service also synchronizes Salesforce user profiles to RBAC role assignments via a MBus event subscription, bridging Salesforce identity management with Groupon's internal permissions model.

## Scope

### In scope

- Creating, updating, deleting, and querying roles and permissions
- Organizing roles and permissions into categories and scope types
- Assigning and revoking roles to users within specific scopes (e.g., global, regional)
- Managing role ownership (which users own a role and can approve requests for it)
- Role request workflow: users request access to a role; role owners approve or reject; email notifications sent via Mailman
- Audit logging of all RBAC mutations (role changes, permission changes, user-role assignments)
- Synchronizing Salesforce user profile events from MBus into RBAC user-role assignments
- Providing a permission-check API for other services to query whether a user holds a specific permission in a given scope

### Out of scope

- Authentication (handled upstream; this service identifies requesters via the `requester_user_id` header)
- User account management (handled by `continuumUsersService`)
- Email delivery (delegated to the Mailman service)
- Consumer-facing authorization (this service is internal only)

## Domain Context

- **Business domain**: Identity / Access Control
- **Platform**: Continuum
- **Upstream consumers**: Internal Groupon tools and services that call the RBAC API to enforce or query permissions
- **Downstream dependencies**: `continuumRbacPostgres` (primary data store), `continuumUsersService` (user account lookup/creation), `messageBus` (Salesforce user event consumption), Mailman (email notification delivery)

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Experience (MX) Team | Owns and develops the service |
| Role Owners | Internal Groupon staff who own specific roles and approve role requests |
| Role Requesters | Internal staff who request access to roles through the role request workflow |
| Consuming Services | Internal Groupon services that query RBAC for permission checks |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 21 | `pom.xml` `<java.version>21</java.version>` |
| Framework | Spring Boot | 3.2.5 | `pom.xml` parent `spring-boot-starter-parent:3.2.5` |
| Runtime | JVM (Eclipse Temurin) | 21 | `src/main/docker/Dockerfile` base image `prod-java21` |
| Build tool | Maven | wrapper (mvnw) | `.mvn/wrapper/maven-wrapper.properties` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `spring-boot-starter-data-jpa` | 3.2.5 (managed) | orm | JPA/Hibernate for PostgreSQL entity persistence |
| `spring-boot-starter-web` | 3.2.5 (managed) | http-framework | REST controller support (Spring MVC) |
| `spring-boot-starter-webflux` | 3.2.5 (managed) | http-framework | Reactive WebClient for outbound HTTP calls to Users Service and Mailman |
| `spring-boot-starter-validation` | 3.2.5 (managed) | validation | Bean validation on request DTOs |
| `spring-boot-starter-aop` | 3.2.5 (managed) | metrics | AOP-based repository performance metrics |
| `flyway-core` + `flyway-database-postgresql` | 10.15.2 | db-client | Database schema migration management |
| `postgresql` (JDBC driver) | managed | db-client | PostgreSQL JDBC connectivity |
| `mbus-client` | 1.5.2 | message-client | Groupon MBus STOMP consumer for Salesforce events |
| `mapstruct` | 1.5.5.Final | serialization | DTO-to-entity and entity-to-DTO mapping |
| `lombok` | 1.18.32 | serialization | Boilerplate reduction (getters, builders, constructors) |
| `logback-steno` | 2.1.0 | logging | Structured JSON logging (Arpnetworking Steno) |
| `metrics-sma-influxdb` | 5.14.1 | metrics | InfluxDB metrics emission via Groupon JTier SMA |
| `guava` | 33.3.1-jre | validation | Rate limiting (`RateLimiter`) for outbound HTTP calls |
| `snakeyaml` | 2.2 | serialization | YAML parsing for Spring config |
| `wiremock-standalone` | 3.9.1 | testing | HTTP stubbing in integration tests |
| `testcontainers` (postgresql + junit-jupiter) | 1.19.8 | testing | PostgreSQL container for integration tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
