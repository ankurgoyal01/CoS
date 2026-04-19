---
service: "tronicon-cms"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [troniconCmsService, continuumTroniconCmsDatabase]
---

# Architecture Context

## System Context

Tronicon CMS is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It acts as a dedicated content management backend for static and legal pages. Downstream consumers (frontends and other internal services) call the CMS REST API to retrieve validated content by path, locale, and brand. The service owns a dedicated MySQL database for all content persistence. It has no upstream event dependencies and does not emit async events — all interactions are synchronous HTTP REST.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Tronicon CMS Service | `troniconCmsService` | Backend API | Java/Dropwizard (JTier) | 1.0.x / Java 17 | REST API for managing CMS content, audit logs, and usability stats for legal pages |
| Tronicon CMS MySQL | `continuumTroniconCmsDatabase` | Database | MySQL (DaaS) | — | Stores CMS content, audit logs, and usability statistics |

## Components by Container

### Tronicon CMS Service (`troniconCmsService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `TroniconCmsResource` | Handles CMS content CRUD and query endpoints (`/cms/*`) | JAX-RS Resource |
| `TroniconCmsStatsResource` | Handles CMS usability statistics endpoints (`/cms-stats/*`) | JAX-RS Resource |
| `CMSService` | Coordinates CMS content operations and validation | Service |
| `CMSUsabilityStatsService` | Coordinates CMS usability statistics operations | Service |
| `CMSContentValidator` | Validates CMS content payloads (locale, contentType, status, brand) | Validator |
| `CMSContentDao` | Persists and queries CMS content records via JDBI | JDBI DAO |
| `CMSContentAuditLogDao` | Persists and queries CMS content audit log entries | JDBI DAO |
| `CMSUsabilityStatsDao` | Persists and queries usability statistics | JDBI DAO |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `troniconCmsService` | `continuumTroniconCmsDatabase` | Reads from and writes to | JDBI/MySQL |
| `TroniconCmsResource` | `CMSService` | Delegates content operations | Direct (in-process) |
| `TroniconCmsStatsResource` | `CMSUsabilityStatsService` | Delegates statistics operations | Direct (in-process) |
| `CMSService` | `CMSContentValidator` | Validates content payloads | Direct (in-process) |
| `CMSService` | `CMSContentDao` | Reads and writes CMS content | JDBI |
| `CMSService` | `CMSContentAuditLogDao` | Writes audit log entries on content changes | JDBI |
| `CMSUsabilityStatsService` | `CMSUsabilityStatsDao` | Reads and writes usability statistics | JDBI |

## Architecture Diagram References

- System context: `continuumSystem`
- Container: `troniconCmsService`
- Component view: `tronicon-cms-cmsService-components` (defined in `architecture/views/components/tronicon-cms-service.dsl`)
