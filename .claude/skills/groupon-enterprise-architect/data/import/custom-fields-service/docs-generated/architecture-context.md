---
service: "custom-fields-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumCustomFieldsService", "continuumCustomFieldsDatabase"]
---

# Architecture Context

## System Context

Custom Fields Service sits within the `continuumSystem` — Groupon's legacy/modern commerce engine. It is called synchronously by upstream inventory services (TPIS, GLive, VIS, Getaways, Goods) during checkout flows to retrieve field definitions and validate purchaser-supplied values. The service reads from and writes to its own dedicated PostgreSQL database (`continuumCustomFieldsDatabase`) and makes outbound HTTP calls to `continuumUsersService` to prefill fields with purchaser profile data.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Custom Fields Service | `continuumCustomFieldsService` | Backend service | Java, Dropwizard | 2.0.x | Provides APIs to create, retrieve, and validate custom field templates and filled fields |
| Custom Fields Database | `continuumCustomFieldsDatabase` | Database | PostgreSQL | — | Stores custom field templates and metadata |

## Components by Container

### Custom Fields Service (`continuumCustomFieldsService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `CustomFieldsResource` | HTTP API entry point for all custom field operations | JAX-RS |
| `CustomFieldsTemplateValidator` | Validates a custom field template structure on creation | Java |
| `LocalizedCustomFieldsFetcher` | Loads custom fields from the database and applies locale-based label translation | Java |
| `CustomFieldsValidatorFetcher` | Loads the validator instance for a given field template | Java |
| `MergedLocalizedCustomFieldsFetcher` | Loads and merges multiple field templates into one combined set | Java |
| `MergedCustomFieldsValidatorFetcher` | Loads validators for all templates in a merged field set | Java |
| `UserDataFetcher` | Retrieves purchaser profile data for field prefill | Java |
| `UserServiceClient` | HTTP client for the Users Service, built with Retrofit2 | Retrofit |
| `CustomFieldsDAO` | Reads and writes custom field templates to PostgreSQL via JDBI3 | JDBI |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCustomFieldsService` | `continuumCustomFieldsDatabase` | Reads and writes custom field templates | JDBC (PostgreSQL) |
| `continuumCustomFieldsService` | `continuumUsersService` | Fetches purchaser profile data (GET users/v1/accounts) for field prefill | REST/HTTP |
| Upstream inventory services | `continuumCustomFieldsService` | Call APIs to retrieve, validate, and create field sets | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-CustomFieldsServiceComponents`
- Dynamic (validate flow): `dynamic-ValidateCustomFields`
