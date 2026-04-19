---
service: "gdpr"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumGdprService]
---

# Architecture Context

## System Context

`continuumGdprService` is a container within the `continuumSystem` (Continuum Platform). It sits at the intersection of support operations and Groupon's consumer data ecosystem. Application Operations agents interact with it directly through a web browser. The service has no public-facing endpoints — it is an internal tool accessible only within the Groupon network. It acts as an orchestration layer: it calls multiple Continuum backend services to assemble a complete picture of a consumer's personal data, then delivers the assembled export to the requesting agent.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| GDPR Service | `continuumGdprService` | Service | Go, Gin | 1.23.5 / 1.10.1 | Collects GDPR-related consumer data across internal systems and exports CSV bundles for support agents |

## Components by Container

### GDPR Service (`continuumGdprService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Manual CLI | Handles manual command-line execution of GDPR exports using flag-parsed arguments | Go |
| Web Server | Provides the HTML web UI and HTTP endpoints (`/`, `POST /data`, `GET /grpn/healthcheck`) for browser-based exports | Go, Gin |
| GDPR Orchestrator | Coordinates the sequential data collection pipeline and triggers ZIP packaging | Go |
| Token Client | Requests scoped authentication tokens from `cs-token-service` for each downstream API call | Go |
| Lazlo Client | Calls Lazlo API (`api-lazlo`) for orders and consumer preferences | Go |
| HTTP Client | Shared HTTP client used for all outbound calls; TLS verification is disabled for internal service communication | Go |
| Orders Collector | Retrieves paginated consumer order history from Lazlo and formats it as a CSV file | Go |
| Preferences Collector | Retrieves consumer preference/interest category data from Lazlo and formats it as a CSV file | Go |
| Subscriptions Collector | Retrieves consumer subscription data from `global-subscription-service` and formats it as a CSV file | Go |
| UGC Collector | Retrieves consumer reviews from `ugc-api-jtier` and enriches them with merchant/place details from `m3-placeread`; formats as CSV | Go |
| Profile Address Collector | Retrieves consumer profile location data from `consumer-data-service` and formats it as a CSV file | Go |
| CSV Writer | Writes structured CSV export files to the OS temp directory | Go |
| ZIP Exporter | Packages all CSV files into a single ZIP archive for delivery | Go |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGdprService` | `cs-token-service` | Requests scoped access tokens before each downstream API call | HTTP POST (`/api/v1/{country}/token`) |
| `continuumGdprService` | `api-lazlo` | Fetches paginated orders, preferences, user profile, Groupon Bucks, and SMS consent data | HTTP GET (`/api/mobile/{country}/...`) |
| `continuumGdprService` | `global-subscription-service` | Fetches active and inactive consumer subscriptions | HTTP GET (`/v2/subscriptions/user/{uuid}`) |
| `continuumGdprService` | `ugc-api-jtier` | Fetches paginated consumer reviews | HTTP GET (`/v1.0/users/{uuid}/reviews`) |
| `continuumGdprService` | `m3-placeread` | Fetches place/merchant name and city to enrich review records | HTTP GET (`/placereadservice/v3.0/places/{uuid}`) |
| `continuumGdprService` | `continuumConsumerDataService` | Fetches consumer profile address locations | HTTP GET (`v1/consumers/{uuid}/locations`) |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-GdprServiceComponents`
- Dynamic view: `dynamic-GdprManualExport`
