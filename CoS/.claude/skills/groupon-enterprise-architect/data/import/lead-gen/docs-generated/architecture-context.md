---
service: "lead-gen"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [leadGenService, leadGenWorkflows, leadGenDb]
---

# Architecture Context

## System Context

LeadGen is a backend subsystem within the Continuum platform dedicated to prospect acquisition for Groupon's Sales organization. It sits at the boundary between internal data intelligence services (PDS inference, merchant quality scoring) and external SaaS providers (Apify for web scraping, Mailgun for email outreach, Salesforce for CRM). The n8n workflow engine orchestrates scheduled and triggered jobs, while the Java service handles the core business logic of scraping, deduplication, enrichment, validation, and outreach. All state is persisted in a dedicated PostgreSQL database.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| LeadGen Service | `leadGenService` | Backend | Java | 21 | Java service orchestrating Apify scraping, deduplication, enrichment, validation, inbox warmup, and outreach |
| LeadGen Workflows | `leadGenWorkflows` | Backend | n8n | — | n8n workflows coordinating lead scraping, enrichment, and distribution |
| LeadGen DB | `leadGenDb` | Database | PostgreSQL | — | Stores leads, contacts, enrichment and outreach status, logs |

## Components by Container

### LeadGen Service (`leadGenService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| (not yet documented) | Components not yet modeled in architecture DSL | Java |

> Component-level decomposition is pending. The service handles scraping orchestration, deduplication, enrichment coordination, validation, inbox warmup, outreach execution, and Salesforce sync as logical concerns.

### LeadGen Workflows (`leadGenWorkflows`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| (not yet documented) | Components not yet modeled in architecture DSL | n8n |

> Workflow-level decomposition is pending. Workflows handle job scheduling, trigger management, and status/log persistence.

### LeadGen DB (`leadGenDb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| (not yet documented) | Components not yet modeled in architecture DSL | PostgreSQL |

> Table-level decomposition is pending. See [Data Stores](data-stores.md) for known entity documentation.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `leadGenWorkflows` | `leadGenService` | Schedules and triggers jobs | Internal |
| `leadGenService` | `leadGenDb` | Read/Write leads, enrichment, outreach state | JDBC |
| `leadGenWorkflows` | `leadGenDb` | Persist workflow status and logs | SQL |
| `leadGenService` | `apify` | Scrape leads | API |
| `leadGenService` | `inferPDS` | Enrich with PDS | REST |
| `leadGenService` | `merchantQuality` | Enrich with quality score | REST |
| `leadGenService` | `mailgun` | Email outreach | API |
| `leadGenService` | `salesForce` | Create Accounts and attach contacts | REST |

## Architecture Diagram References

- Component: `components-continuum-leadgen-service`
- Component: `components-continuum-leadgen-workflows`
- Component: `components-continuum-leadgen-db`

> Dynamic views are not yet defined for this service. See [Flows](flows/index.md) for process-level sequence documentation.
