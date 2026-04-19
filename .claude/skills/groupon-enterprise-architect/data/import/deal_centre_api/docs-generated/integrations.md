---
service: "deal_centre_api"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 3
internal_count: 2
---

# Integrations

## Overview

Deal Centre API has five active downstream dependencies: two synchronous HTTP integrations with internal Continuum services (Deal Management API and Deal Catalog Service), one async bidirectional integration with the internal Message Bus, one HTTP integration with the Email Service, and one owned PostgreSQL database. The `dca_externalClients` component encapsulates all outbound HTTP clients. The `dca_messageBusIntegration` component handles all MBus producers and consumers.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Deal Management API | rest | Creates and updates deals, options, and products | yes | `continuumDealManagementApi` |
| Deal Catalog Service | rest | Looks up deal IDs and catalog data | yes | `continuumDealCatalogService` |
| Email Service | rest | Sends transactional emails for merchant and buyer notifications | no | `continuumEmailService` |

### Deal Management API (`continuumDealManagementApi`) Detail

- **Protocol**: HTTP (REST/JSON)
- **Base URL / SDK**: Internal Continuum service endpoint — see service registry
- **Auth**: Internal service-to-service authentication
- **Purpose**: All deal, option, and product create/update operations are delegated to Deal Management API. Deal Centre API acts as an orchestrator, not the authoritative owner of deal lifecycle mutations.
- **Failure mode**: Deal create/update operations fail; merchant workflow returns error
- **Circuit breaker**: No evidence found

### Deal Catalog Service (`continuumDealCatalogService`) Detail

- **Protocol**: HTTP (REST/JSON)
- **Base URL / SDK**: Internal Continuum service endpoint — see service registry
- **Auth**: Internal service-to-service authentication
- **Purpose**: Catalog lookups by deal ID and catalog data retrieval to support buyer browsing and admin catalog management
- **Failure mode**: Catalog lookups degrade; buyer browsing and catalog admin views may be unavailable
- **Circuit breaker**: No evidence found

### Email Service (`continuumEmailService`) Detail

- **Protocol**: HTTP (REST/JSON)
- **Base URL / SDK**: Internal Continuum Mailman service endpoint — see service registry
- **Auth**: Internal service-to-service authentication
- **Purpose**: Dispatches transactional emails for deal confirmation, merchant notifications, and buyer receipts
- **Failure mode**: Transactional emails are not sent; core deal workflows remain available
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Message Bus | mbus | Bidirectional: publishes inventory and deal catalog events; consumes inventory and catalog events | `messageBus` |
| Deal Centre Postgres | JPA/JDBC | Reads and writes all deal centre and catalog data | `continuumDealCentrePostgres` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Deal Centre UI | HTTPS/JSON | Primary consumer — merchant, buyer, and admin UI for deal centre workflows |
| Internal Groupon tooling | HTTPS/JSON | Administrative and operational access |

> Upstream consumers beyond Deal Centre UI are tracked in the central architecture model (`continuumSystem`).

## Dependency Health

> No evidence found for explicit circuit breaker, retry, or health-check configuration on outbound HTTP clients in the architecture model. Dependency health patterns to be confirmed with the service owner.
