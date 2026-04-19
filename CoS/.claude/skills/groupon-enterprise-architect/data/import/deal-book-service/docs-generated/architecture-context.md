---
service: "deal-book-service"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumDealManagementSystem"
  containers: [dealBookServiceApp, dealBookMessageWorker, dealBookRakeTasks, continuumDealBookMysql, continuumDealBookRedis]
---

# Architecture Context

## System Context

Deal Book Service sits within the Continuum platform's Deal Management domain. It acts as the authoritative data service for fine print clauses used during deal creation. The service is consumed primarily by Deal Wizard for fine print compilation and persistence. Content originates in Google Sheets and is periodically synchronized into the local MySQL database. Taxonomy change events are consumed via message bus to keep clause categorization current. The service has no direct user-facing interface — all interactions are API-driven.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| API Application | `dealBookServiceApp` | API Service | Ruby on Rails | 3.2.22.5 | REST API exposing fine print clause retrieval, compilation, and persistence endpoints |
| Message Worker | `dealBookMessageWorker` | Background Process | Ruby / messagebus | 0.2.15 | Consumes taxonomy update events from the message bus and updates clause mappings |
| Rake Task Runner | `dealBookRakeTasks` | Scheduled Jobs | Ruby / whenever | 0.9.4 | Scheduled rake tasks for Google Sheets sync and content version management |
| MySQL Database | `continuumDealBookMysql` | Database | MySQL | — | Stores fine print clauses, attributes, categories, rules, persisted fine prints, content versions, and mappings |
| Redis Cache | `continuumDealBookRedis` | Cache | Redis | — | Caches API responses to reduce load on MySQL and downstream services |

## Components by Container

### API Application (`dealBookServiceApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Fine Print Clauses Controller (V1-V4) | Serves fine print clause recommendations by geo/taxonomy across versions | Rails MVC |
| Compile Controller | Compiles a set of fine print clauses into a single fine print document | Rails MVC |
| Persisted Fine Prints Controller (V1-V2) | CRUD operations for persisted fine print sets per deal | Rails MVC |
| Content Version Controller | Reports the current content version of fine print data | Rails MVC |
| Health Controller | Provides health/liveness endpoint | Rails MVC |
| Entries Controller (V1) | Serves fine print entry data (V1 compatibility) | Rails MVC |
| Google Sheets Sync | Pulls clause data from Google Sheets and reconciles with MySQL | google_drive 3.0.0 |
| Taxonomy Client Integration | Calls Taxonomy Service for category resolution | taxonomy_service_client |
| Model API Integration | Calls Model API for deal record lookups | model_api_client 0.1.1 |
| Salesforce Integration | Maps fine print records to Salesforce external UUIDs | faraday 0.17.3 |

### Message Worker (`dealBookMessageWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Taxonomy Update Handler | Processes `jms.topic.taxonomyV2.content.update` events; updates clause-category mappings | messagebus 0.2.15 |

### Rake Task Runner (`dealBookRakeTasks`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Google Sheets Refresh Task | Scheduled rake task to sync fine print content from Google Sheets | whenever 0.9.4 |
| Content Version Management Task | Maintains and increments content version records | whenever 0.9.4 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `dealBookServiceApp` | `continuumDealBookMysql` | Reads and writes fine print data | MySQL |
| `dealBookServiceApp` | `continuumDealBookRedis` | Caches API responses | Redis |
| `dealBookServiceApp` | `continuumTaxonomyService` | Resolves taxonomy categories for clause filtering | REST/HTTP |
| `dealBookServiceApp` | `continuumGoogleSheetsApi` | Fetches fine print clause source content | Google Drive API |
| `dealBookServiceApp` | `salesForce` | Maps fine print records to Salesforce external UUIDs | REST/HTTP |
| `dealBookMessageWorker` | `continuumTaxonomyContentUpdateTopic` | Consumes taxonomy content update events | Message bus (JMS) |
| `dealBookRakeTasks` | `continuumGoogleSheetsApi` | Scheduled sync of Google Sheets content | Google Drive API |
| `continuumDealWizard` | `dealBookServiceApp` | Requests fine print compilations and persists fine print sets | REST/HTTP |

## Architecture Diagram References

- System context: `contexts-continuum-deal-management`
- Container: `containers-deal-book-service`
- Component: `components-deal-book-service`
