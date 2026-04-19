---
service: "client-id"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - continuumClientIdService
    - continuumClientIdDatabase
    - continuumClientIdReadReplica
---

# Architecture Context

## System Context

Client ID Service lives within the **Continuum** platform and acts as the authoritative registry for API client identities. It sits between internal tooling/developers (who create and manage clients) and the API gateway layer (API Proxy, API Lazlo) which periodically syncs client and token data to enforce access and rate limits at runtime. The service is deployed in multiple cloud regions (GCP US, GCP EU, AWS EU) and exposes both an HTML management UI and a machine-readable REST API.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Client ID Service | `continuumClientIdService` | Backend service | Java, Dropwizard | 1.3.29 | Dropwizard service that manages API clients, tokens, service mappings, schedules, and reCAPTCHA metadata |
| Client ID MySQL (Primary) | `continuumClientIdDatabase` | Database | MySQL | — | Primary MySQL datastore for client-id domain entities and reCAPTCHA configuration tables |
| Client ID MySQL (Read Replica) | `continuumClientIdReadReplica` | Database | MySQL | — | Read-replica MySQL datastore used for high-volume read paths |

## Components by Container

### Client ID Service (`continuumClientIdService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`continuumClientIdApiResources`) | REST resources for API and web endpoints — search, service, and web management workflows | JAX-RS Resources |
| Persistence Layer (`continuumClientIdPersistence`) | JDBI DAOs and row mappers for all client-id domain entities (clients, tokens, services, schedules, mobiles, recaptcha, users) | JDBI |
| Scheduled Change Handler (`continuumClientIdScheduler`) | Background task that polls for active schedules and applies or reverts temporary rate-limit changes at their start/end windows | Scheduled Executor |
| Jira Gateway (`continuumClientIdJiraGateway`) | HTTP client integration that creates Jira issues for self-service client registration requests | OkHttp Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumClientIdService` | `continuumClientIdDatabase` | Reads and writes client-id entities (clients, tokens, services, schedules, mobiles, recaptcha) | JDBI / MySQL |
| `continuumClientIdService` | `continuumClientIdReadReplica` | Reads client-id entities for query-heavy paths (API Proxy sync, search) | JDBI / MySQL |
| `continuumClientIdApiResources` | `continuumClientIdPersistence` | Reads and writes client-id domain data | In-process |
| `continuumClientIdApiResources` | `continuumClientIdJiraGateway` | Creates Jira tickets for self-service requests | In-process |
| `continuumClientIdScheduler` | `continuumClientIdPersistence` | Loads and applies scheduled rate-limit changes | In-process |
| API Proxy | `continuumClientIdService` | Periodically syncs clients and tokens via `/v3/services/{serviceName}` | HTTPS / REST |
| API Lazlo | `continuumClientIdService` | Queries client data via search endpoints | HTTPS / REST |

## Architecture Diagram References

- Container: `containers-continuum-client-id`
- Component: `components-continuum-client-id-service`
