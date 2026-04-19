---
service: "tripadvisor-api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumTripadvisorApi"
  containers: ["continuumTripadvisorApiV1Webapp"]
---

# Architecture Context

## System Context

The Getaways Affiliate API sits within the Continuum platform as the outward-facing integration point for external travel distribution partners. It receives availability and feed requests from TripAdvisor, Trivago, and Google Hotel Ads, translates them into calls to internal Groupon Getaways APIs (`getawaysSearchApi`, `getawaysContentApi`), and returns partner-formatted responses. Google Hotel Ads (`continuumGoogleHotelAds`) is a known in-model caller; TripAdvisor and Trivago partners connect externally over HTTPS to the public endpoint `http://api.groupon.com/getaways/v2/affiliates`.

The service has no persistent data store of its own for business data; availability and pricing data are retrieved on demand from downstream Getaways services. A MySQL database (gpn-db-vip.snc1) is referenced in configuration for the Groupon Platform Network (GPN) framework integration, though no service-owned entities are documented.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| TripAdvisor API v1 Webapp | `continuumTripadvisorApiV1Webapp` | Service | Java / Spring MVC WAR | 1.8 / 4.1.6 | Spring MVC WAR that serves TripAdvisor, Trivago, and Google Hotel Ads availability and feed endpoints, integrating with Getaways APIs |

## Components by Container

### TripAdvisor API v1 Webapp (`continuumTripadvisorApiV1Webapp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Hotel Availability API Controller | Handles TripAdvisor/Trivago availability requests (`POST /hotel_availability`, `POST /{partnerSeoName}/hotel_availability`) and builds responses | Spring MVC Controller |
| Google Transaction Message Controller | Serves Google Hotel Ads transaction messages with pricing and room bundle data (`POST /google/transaction_query`) | Spring MVC Controller |
| Google Hotel List Feed Controller | Serves Google hotel list feed responses (`POST /google/hotel_list_feed`) | Spring MVC Controller |
| Google Query Control Message Controller | Serves Google query control XML responses (`POST /google/query_control_message`) | Spring MVC Controller |
| Utility Controller | Provides heartbeat, status, and config endpoints | Spring MVC Controller |
| Getaways Hotel Availability Service | Coordinates availability requests to downstream Getaways APIs and orchestrates response transformation | Service |
| Hotel Pricing Summary Manager | Builds per-hotel pricing summaries from Getaways API data | Manager |
| Hotel Bundles Summary Manager | Builds room bundle summaries from Getaways API data | Manager |
| Query Control Message Factory | Builds Google query control XML responses from a static configuration file | Service |
| XSD Validation Service | Validates inbound and outbound XML payloads for Google Hotel Ads integrations | Service |
| Remote Getaways API Client | HTTP client that calls `getawaysSearchApi` (`/getaways/v2/search`) and `getawaysContentApi` (`/v2/getaways/content/product_sets`, `/v2/getaways/content/hotelDetailBatch`) | HTTP Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGoogleHotelAds` | `continuumTripadvisorApiV1Webapp` | Requests query control, transaction, and hotel list feeds | HTTPS |
| TripAdvisor Partner (external) | `continuumTripadvisorApiV1Webapp` | Requests hotel availability | HTTPS |
| Trivago Partner (external) | `continuumTripadvisorApiV1Webapp` | Requests hotel availability | HTTPS |
| `hotelAvailabilityApiController` | `getawaysHotelAvailabilityService` | Requests availability and pricing summaries | direct |
| `getawaysHotelAvailabilityService` | `hotelPricingSummaryManager` | Aggregates pricing summaries | direct |
| `getawaysHotelAvailabilityService` | `hotelBundlesSummaryManager` | Aggregates room bundle summaries | direct |
| `hotelPricingSummaryManager` | `remoteGetawaysApiClient` | Fetches pricing from Getaways APIs | direct |
| `hotelBundlesSummaryManager` | `remoteGetawaysApiClient` | Fetches bundle data from Getaways APIs | direct |
| `googleTransactionMessageController` | `hotelPricingSummaryManager` | Builds transaction message pricing | direct |
| `googleTransactionMessageController` | `hotelBundlesSummaryManager` | Builds room bundle payloads | direct |
| `googleTransactionMessageController` | `xsdValidationService` | Validates XML payloads | direct |
| `googleHotelListFeedController` | `remoteGetawaysApiClient` | Fetches hotel list feed data | direct |
| `googleQueryControlMessageController` | `queryControlMessageFactory` | Builds query control response | direct |
| `remoteGetawaysApiClient` | `getawaysSearchApi` (stub) | Queries availability and pricing | HTTP |
| `remoteGetawaysApiClient` | `getawaysContentApi` (stub) | Fetches product sets and hotel details | HTTP |

## Architecture Diagram References

- System context: `contexts-tripadvisor-system-context`
- Component: `components-tripadvisorApiV1WebappComponents`
