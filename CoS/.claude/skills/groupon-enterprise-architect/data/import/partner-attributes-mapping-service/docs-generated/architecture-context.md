---
service: "partner-attributes-mapping-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumPartnerAttributesMappingService", "continuumPartnerAttributesMappingPostgres"]
---

# Architecture Context

## System Context

The Partner Attributes Mapping Service is a container within the `continuumSystem` (Continuum Platform). It serves as the authoritative translation layer for ID mapping and request signing between Groupon internal systems and third-party distribution partners participating in the Groupon Anywhere program. All requests are synchronous REST calls; the service has no messaging dependencies and owns its own PostgreSQL database. Internal Groupon services call PAMS to create, query, and maintain partner mappings, and to generate or validate HMAC signatures before communicating with external partner APIs.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Partner Attributes Mapping Service | `continuumPartnerAttributesMappingService` | Service | Java, Dropwizard | JTier 5.14.0 | Dropwizard microservice that manages partner attribute mappings and partner secrets, and exposes signature endpoints |
| Partner Attributes Mapping PostgreSQL | `continuumPartnerAttributesMappingPostgres` | Database | PostgreSQL | — | Primary datastore for partner attribute mappings and partner secrets |

## Components by Container

### Partner Attributes Mapping Service (`continuumPartnerAttributesMappingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `pams_requestFilters` | Validates required headers (`client-id`, `X-Brand`) and logs request payloads | Jersey Filters (`HeadersValidationFilter`, `RequestPayloadLoggingFilter`) |
| `pams_apiResources` | Exposes JAX-RS endpoints for mapping, secret, and signature operations | Jersey Resources (`PartnerAttributesMappingResource`, `PartnerAttributesSecretsResource`, `PartnerSignatureServiceResource`) |
| `pams_mappingService` | Business logic for partner attribute mapping CRUD operations including duplicate detection and bulk creation | Service (`PartnerAttributesMappingService`) |
| `pams_secretService` | Business logic for generating and updating partner HMAC secrets stored in the database | Service (`PartnerAttributesSecretService`) |
| `pams_signatureService` | Signature creation and validation path; resolves partner secrets and computes/verifies HMAC-SHA1 | Resource + Service (`PartnerSignatureServiceResource`, `Signature`, `SignatureValidator`) |
| `pams_partnerRegistry` | Registry abstraction that resolves partner secret material for signature operations, merging DB secrets with config-file secrets | Registry (`PartnerRegistry`) |
| `pams_mappingDao` | JDBI DAO for partner attribute mappings — reads, writes, and deletes rows in `partner_attributes_map` | JDBI DAO (`PartnerAttributeMapDao`) |
| `pams_secretDao` | JDBI DAO for partner secrets — reads, writes, and updates rows in `partner_secrets` | JDBI DAO (`PartnerAttributeSecretDao`) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `pams_requestFilters` | `pams_apiResources` | Validates request headers and logs payload context | Jersey filter chain |
| `pams_apiResources` | `pams_mappingService` | Handles mapping API requests | Direct (in-process) |
| `pams_apiResources` | `pams_secretService` | Handles partner secret API requests | Direct (in-process) |
| `pams_apiResources` | `pams_signatureService` | Handles signature create/validate API requests | Direct (in-process) |
| `pams_mappingService` | `pams_mappingDao` | Reads/writes partner attribute mappings | Direct (in-process) |
| `pams_secretService` | `pams_secretDao` | Creates/updates partner secrets | Direct (in-process) |
| `pams_signatureService` | `pams_partnerRegistry` | Resolves partner secret material | Direct (in-process) |
| `pams_partnerRegistry` | `pams_secretDao` | Reads partner secrets from the database | Direct (in-process) |
| `pams_mappingDao` | `continuumPartnerAttributesMappingPostgres` | Reads/writes mapping data | JDBI / PostgreSQL |
| `pams_secretDao` | `continuumPartnerAttributesMappingPostgres` | Reads/writes secret data | JDBI / PostgreSQL |
| `continuumPartnerAttributesMappingService` | `continuumPartnerAttributesMappingPostgres` | Reads and writes partner mappings and partner secrets | JDBI / PostgreSQL |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumPartnerAttributesMappingService`
- Dynamic — Mapping Request Flow: `dynamic-pams-mapping-request-flow`
- Dynamic — Signature Request Flow: `dynamic-pams-signature-request-flow`
