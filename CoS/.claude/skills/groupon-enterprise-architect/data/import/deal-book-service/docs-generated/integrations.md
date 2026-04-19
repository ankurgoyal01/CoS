---
service: "deal-book-service"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

Deal Book Service has two external dependencies (Google Sheets API and Salesforce) and three internal Continuum service dependencies (Taxonomy Service, Model API, and the taxonomy message bus topic). It is consumed by Deal Wizard as its primary client. All integrations are synchronous REST/HTTP or message bus, with no direct database sharing.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Sheets API | SDK (google_drive) | Source of truth for fine print clause content; used during scheduled sync | yes | `continuumGoogleSheetsApi` |
| Salesforce | REST/HTTP | Maps fine print records to Salesforce external UUIDs for cross-system identity | no | `salesForce` |

### Google Sheets API Detail

- **Protocol**: Google Drive API (via `google_drive 3.0.0` Ruby gem)
- **Base URL / SDK**: `google_drive` gem — Google Drive/Sheets REST API
- **Auth**: Google service account or OAuth credentials (specific credential not discoverable from inventory)
- **Purpose**: Acts as the human-editable source of truth for fine print clause content. Scheduled rake tasks read sheet data and reconcile it into MySQL
- **Failure mode**: Scheduled sync fails; MySQL content falls out of date. Existing fine print data continues to be served from MySQL/Redis cache until next successful sync
- **Circuit breaker**: No evidence found in codebase

### Salesforce Detail

- **Protocol**: REST/HTTP (via `faraday 0.17.3`)
- **Base URL / SDK**: Configured via environment variable
- **Auth**: Not discoverable from inventory — likely OAuth or API token
- **Purpose**: Provides or stores external UUIDs for fine print records to enable cross-system deal data mapping with Salesforce CRM
- **Failure mode**: UUID mapping unavailable; fine print records saved without Salesforce external UUID
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Taxonomy Service | REST/HTTP | Resolves taxonomy category IDs for fine print clause filtering by deal type | `continuumTaxonomyService` |
| Model API | REST/HTTP | Retrieves deal and model-level data for fine print association | `continuumModelApi` |
| Taxonomy Content Update Topic | Message bus (JMS) | Receives taxonomy change events to refresh clause-category mappings | `continuumTaxonomyContentUpdateTopic` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Deal Wizard (`continuumDealWizard`) | REST/HTTP | Retrieves fine print clause recommendations, compiles fine prints, and persists fine print sets during deal creation |

> Additional upstream consumers may exist but are tracked in the central architecture model.

## Dependency Health

- **Google Sheets API**: No circuit breaker configured. If unavailable, scheduled sync rake tasks will fail. MySQL data remains stale until the next successful sync run.
- **Taxonomy Service**: Called at request time for clause filtering. If unavailable, fine print clause responses may be degraded or fail.
- **Message bus**: If `jms.topic.taxonomyV2.content.update` is unavailable, taxonomy mapping updates are delayed. No DLQ configured per available evidence.
- **Redis**: Used as a read cache. If Redis is unavailable, requests fall back to MySQL directly.
