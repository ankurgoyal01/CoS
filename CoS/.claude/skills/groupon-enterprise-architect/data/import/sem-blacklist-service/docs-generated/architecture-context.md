---
service: "sem-blacklist-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumSemBlacklistService", "continuumSemBlacklistPostgres"]
---

# Architecture Context

## System Context

The SEM Blacklist Service is a component of the **Continuum Platform** (`continuumSystem`), Groupon's core commerce engine. It operates as a standalone microservice within the SEM (Search Engine Marketing) domain. Internal SEM tooling and bidding systems consume the denylist REST API to determine which entities (deal permalinks, keywords, merchants) should be suppressed from SEM campaigns. The service reads from and writes to its own owned PostgreSQL database, and reaches out to two external systems: the Asana REST API for task-driven denylist management and the Google Sheets API for spreadsheet-driven PLA blacklist synchronization.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| SEM Blacklist Service | `continuumSemBlacklistService` | API Service | Java, Dropwizard/JTier | 5.14.1 | Provides denylist/blacklist REST API and background processing for SEM blacklists |
| SEM Blacklist Postgres | `continuumSemBlacklistPostgres` | Database | PostgreSQL | (DaaS managed) | Stores denylist/blacklist entries in the `sem_raw_blacklist` table |

## Components by Container

### SEM Blacklist Service (`continuumSemBlacklistService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `apiResources_SemBla` (REST Resources) | Exposes JAX-RS resources for all denylist/blacklist API endpoints and the Asana task trigger endpoint | JAX-RS |
| `blacklistDao` (RawBlacklistDAO) | JDBI DAO for all blacklist database operations — insert, update (soft-delete), fetch, batch refresh | JDBI |
| `asanaClient` (AsanaClient) | HTTP client for polling open tasks from Asana sections and updating task status fields | Java HTTP Client |
| `asanaTaskProcessor` (DenylistAsanaTaskProcessor) | Validates Asana task data and translates tasks into blacklist add/delete operations | Java |
| `asanaTaskJob` (DenylistAsanaTaskProcessingJob) | Quartz scheduled job that triggers Asana task processing on a recurring schedule | Quartz |
| `gdocClient` (GoogleDocsClient) | Google Sheets API client for reading meta-sheets and blacklist spreadsheets | Google Sheets API |
| `gdocBlacklistStore` (GDocBlacklistStore) | Loads and performs full refresh of PLA blacklists from Google Sheets into the database | Java |
| `gdocRefreshJob` (GDocRefreshBlacklistJob) | Quartz scheduled job that triggers Google Sheets blacklist refresh on a recurring schedule | Quartz |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumSemBlacklistService` | `continuumSemBlacklistPostgres` | Reads and writes blacklist data | JDBC / SQL |
| `continuumSemBlacklistService` | `asanaApi` (external stub) | Fetches open tasks from a configured Asana section and updates task status fields | HTTPS / REST |
| `continuumSemBlacklistService` | `googleSheetsApi` (external stub) | Reads PLA blacklist spreadsheets for scheduled refresh | HTTPS / Google Sheets API v4 |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-sem-blacklist-components`
