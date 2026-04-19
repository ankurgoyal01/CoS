---
service: "ingestion-jtier"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 5
---

# Integrations

## Overview

ingestion-jtier integrates with four external partner APIs (Viator, Mindbody, Booker, RewardsNetwork) via HTTP/REST (and potentially SFTP for feed file delivery), and five internal Groupon services (Deal Management API, TPIS, Partner Service, Taxonomy Service, Message Bus). All outbound HTTP calls are wrapped through `ingestionClientGateway` using jtier-retrofit and Apache httpclient. No inbound integrations from other internal services are confirmed — callers interact exclusively via the REST API.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Viator | REST / SFTP | Extracts Viator experience partner feed data | yes | `viatorApi` |
| Mindbody | REST | Extracts Mindbody fitness/wellness partner feed data | yes | `mindbodyApi` |
| Booker | REST | Extracts Booker spa/salon partner feed data | yes | `bookerApi` |
| RewardsNetwork | REST | Extracts RewardsNetwork dining partner feed data | yes | `rewardsNetworkApi` |

### Viator Detail

- **Protocol**: HTTP/REST (and SFTP for bulk feed file delivery)
- **Base URL / SDK**: External Viator API; URL configured via service configuration
- **Auth**: API key or OAuth credentials — exact method not confirmed from inventory
- **Purpose**: Fetches Viator's experiences and activity offer catalog for ingestion into Groupon deals
- **Failure mode**: Feed extraction job fails; IngestionOperationalEvent published with ERROR severity; run marked failed in PostgreSQL
- **Circuit breaker**: No evidence found

### Mindbody Detail

- **Protocol**: HTTP/REST
- **Base URL / SDK**: External Mindbody API; URL configured via service configuration
- **Auth**: API key — exact method not confirmed from inventory
- **Purpose**: Fetches Mindbody fitness and wellness class/session offers for ingestion
- **Failure mode**: Feed extraction job fails for Mindbody partner; other partners unaffected
- **Circuit breaker**: No evidence found

### Booker Detail

- **Protocol**: HTTP/REST
- **Base URL / SDK**: External Booker API (`bookerApi`); URL configured via service configuration
- **Auth**: API key or token — exact method not confirmed from inventory
- **Purpose**: Fetches Booker spa and salon service offers for ingestion
- **Failure mode**: Feed extraction job fails for Booker partner; other partners unaffected
- **Circuit breaker**: No evidence found

### RewardsNetwork Detail

- **Protocol**: HTTP/REST
- **Base URL / SDK**: External RewardsNetwork API (`rewardsNetworkApi`); URL configured via service configuration
- **Auth**: API key — exact method not confirmed from inventory
- **Purpose**: Fetches RewardsNetwork dining and restaurant offer data for ingestion
- **Failure mode**: Feed extraction job fails for RewardsNetwork partner; other partners unaffected
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Deal Management API | REST | Creates, updates, pauses, and unpauses deals from ingested offers | `continuumDealManagementApi` |
| Third-Party Inventory Service (TPIS) | REST | Retrieves third-party inventory metadata and classification data | `thirdPartyInventory` |
| Partner Service | REST | Fetches partner configuration, credentials, and metadata | `continuumPartnerService` |
| Taxonomy Service | REST | Resolves category taxonomy mappings for offer classification | `continuumTaxonomyService` |
| Message Bus | Message Bus | Publishes FeedExtractionCompleteEvent, OfferIngestionEvent, IngestionOperationalEvent | `mbusPlatform` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Direct API callers include Jenkins pipeline jobs and internal operations tooling that trigger on-demand ingestion runs via the REST API.

## Dependency Health

- All outbound REST calls are made through `ingestionClientGateway` using jtier-retrofit wrappers backed by Apache httpclient.
- Connection timeout and read timeout configuration is expected per dependency via service YAML configuration.
- No circuit breaker implementation is confirmed from the inventory.
- Redis distributed locks (`continuumIngestionJtierRedis`) guard against duplicate concurrent job execution per partner.
- Failures against external partners result in per-partner job failure and IngestionOperationalEvent publishing; they do not cascade to other partners.
- Failures against Deal Management API during deal creation are the most impactful failure mode, as they leave extracted offers without corresponding deals.
