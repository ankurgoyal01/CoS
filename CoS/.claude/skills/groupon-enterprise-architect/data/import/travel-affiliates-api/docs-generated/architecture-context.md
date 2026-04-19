---
service: "travel-affiliates-api"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumTravelAffiliatesApi"
  containers: [continuumTravelAffiliatesApi, continuumTravelAffiliatesCron, continuumTravelAffiliatesDb, continuumTravelAffiliatesFeedBucket, continuumGetawaysApi, continuumSeoNameService, continuumGoogleHotelAds, continuumSkyscanner, continuumTripAdvisor]
---

# Architecture Context

## System Context

The Travel Affiliates API sits within the Groupon Continuum platform as the outbound-facing integration layer for external CPC travel affiliate partners. Three partners — Google Hotel Ads, Skyscanner, and TripAdvisor — call this service over HTTPS to query hotel availability, pricing, and feed data. Internally the service delegates all inventory queries to `continuumGetawaysApi` and partner identity resolution to `continuumSeoNameService`. Generated hotel feed XML artifacts are written to an AWS S3 bucket (`continuumTravelAffiliatesFeedBucket`). A separate cron container runs scheduled feed export jobs that follow the same upstream dependency pattern.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Travel Affiliates API | `continuumTravelAffiliatesApi` | Backend | Java 11, Spring MVC on Tomcat | 8.5.73-jre11 | Spring MVC web app exposing partner-facing hotel availability, pricing, and feed endpoints |
| Travel Affiliates Cron | `continuumTravelAffiliatesCron` | Backend | Java 11, Spring + JobRunner | 11 | Batch image running scheduled hotel feed export jobs and uploading to S3 |
| Travel Affiliates DB | `continuumTravelAffiliatesDb` | Database | MySQL | — | Relational datasource configured via JNDI; stores operational data when enabled |
| Travel Affiliates S3 Feed Bucket | `continuumTravelAffiliatesFeedBucket` | Database | AWS S3 | — | Blob storage for generated hotel feed XML artifacts |
| Getaways API | `continuumGetawaysApi` | Backend | HTTP/JSON | — | Upstream inventory, availability, and bundle API |
| SEO Name Service | `continuumSeoNameService` | Backend | HTTP/JSON | — | Maps partner SEO names to internal partner definitions |
| Google Hotel Ads | `continuumGoogleHotelAds` | WebApp | External Partner | — | Affiliate partner consuming feed and transaction endpoints |
| Skyscanner | `continuumSkyscanner` | WebApp | External Partner | — | Affiliate partner invoking availability transactions |
| TripAdvisor | `continuumTripAdvisor` | WebApp | External Partner | — | Legacy partner using hotel availability endpoint |

## Components by Container

### Travel Affiliates API (`continuumTravelAffiliatesApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Hotel Availability API Controller (`continuumTravelAffiliatesApi_hotelAvailabilityApiController`) | Handles partner hotel availability requests, maps partner identifiers, delegates to availability services | Spring MVC Controller |
| Google Transaction Controller (`continuumTravelAffiliatesApi_googleTransactionMessageController`) | Processes Google Hotel Ads transaction queries for bundles and pricing | Spring MVC Controller |
| Skyscanner Transaction Controller (`continuumTravelAffiliatesApi_skyscannerTransactionController`) | Processes Skyscanner partner availability transactions | Spring MVC Controller |
| Google Hotel List Feed Controller (`continuumTravelAffiliatesApi_googleHotelListFeedController`) | Exposes CSV/JSON hotel list feeds for Google by aggregating active deals and hotel metadata | Spring MVC Controller |
| Hotel Feed Controller (`continuumTravelAffiliatesApi_hotelFeedController`) | On-demand endpoint to trigger HotelsFeedJob generation | Spring MVC Controller |
| Utility Controller (`continuumTravelAffiliatesApi_utilityController`) | Warmup and liveness utility endpoint | Spring MVC Controller |
| Getaways Hotel Availability Service (`continuumTravelAffiliatesApi_getawaysHotelAvailabilityService`) | Transforms partner availability requests and calls Getaways API for availability summaries | Spring Service |
| Transaction Service (`continuumTravelAffiliatesApi_transactionService`) | Coordinates pricing and bundle flows, validates requests, builds Transaction XML responses | Spring Service |
| Hotel Pricing Summary Manager (`continuumTravelAffiliatesApi_hotelPricingSummaryManager`) | Builds hotel pricing summary by invoking Getaways availability API for requested hotels and dates | Spring Service |
| Hotel Bundles Summary Manager (`continuumTravelAffiliatesApi_hotelBundlesSummaryManager`) | Retrieves room bundles for hotels using Getaways bundle API and filters open deals | Spring Service |
| Active Deals Summary Manager (`continuumTravelAffiliatesApi_activeDealsSummaryManager`) | Aggregates active deals and hotel metadata from Deal Catalog and Getaways APIs to produce hotel lists | Spring Service |
| Getaways API Client (`continuumTravelAffiliatesApi_getawaysApiClient`) | HTTP client encapsulating Getaways availability, bundles, product sets, and hotel detail endpoints | RestTemplate Client |
| Deal Catalog API Client (`continuumTravelAffiliatesApi_dealCatalogApiClient`) | HTTP client fetching active deal UUIDs and regional mappings from Deal Catalog API | RestTemplate Client |
| Hotels Feed Service (`continuumTravelAffiliatesApi_hotelsFeedService`) | Generates hotel feed XML files from active hotel data | Spring Service |
| AWS File Upload Service (`continuumTravelAffiliatesApi_awsFileUploadService`) | Uploads generated feed files to S3 using AWS SDK v2 | Spring Service |
| Getaways AWS Bucket Configuration (`continuumTravelAffiliatesApi_getawaysAwsBucketConfiguration`) | Loads AWS bucket, prefix, region, and credentials from configuration | Spring Component |
| User Country Mapper (`continuumTravelAffiliatesApi_userCountryMapper`) | Maps point-of-sale and user_country codes to locales and regions | Mapper Utility |
| Country Name to ISO Code Mapper (`continuumTravelAffiliatesApi_countryNameToISOCodeMapper`) | Normalizes country names to ISO codes for feeds | Mapper Utility |
| SEO Resolver (`continuumTravelAffiliatesApi_seoResolver`) | Resolves partner SEO names to PartnerEnum definitions | Integration Component |
| XSD Validation Service (`continuumTravelAffiliatesApi_xsdValidationService`) | Validates generated XML responses against bundled XSD schemas | Spring Service |

### Travel Affiliates Cron (`continuumTravelAffiliatesCron`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Job Runner (`continuumTravelAffiliatesCron_jobRunner`) | CLI entrypoint that loads CronConfig and executes scheduled jobs | Java main |
| Hotels Feed Job (`continuumTravelAffiliatesCron_hotelsFeedJob`) | Generates hotel feed XML files per region and orchestrates upload | Spring Component |
| Hotels Feed Service - Cron (`continuumTravelAffiliatesCron_hotelsFeedService`) | Builds hotel XML feeds using active deals and hotel metadata | Spring Service |
| Active Deals Summary Manager - Cron (`continuumTravelAffiliatesCron_activeDealsSummaryManager`) | Aggregates active deals and hotel details for feed generation | Spring Service |
| Getaways API Client - Cron (`continuumTravelAffiliatesCron_getawaysApiClient`) | HTTP client to Getaways APIs used by feed job | RestTemplate Client |
| Deal Catalog API Client - Cron (`continuumTravelAffiliatesCron_dealCatalogApiClient`) | HTTP client to Deal Catalog API for active deals | RestTemplate Client |
| AWS File Upload Service - Cron (`continuumTravelAffiliatesCron_awsFileUploadService`) | Uploads generated feed files to S3 bucket | Spring Service |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGoogleHotelAds` | `continuumTravelAffiliatesApi` | Sends hotel availability and transaction queries; consumes hotel list feeds | HTTPS |
| `continuumSkyscanner` | `continuumTravelAffiliatesApi` | Requests availability transactions | HTTPS |
| `continuumTripAdvisor` | `continuumTravelAffiliatesApi` | Calls legacy hotel availability endpoint | HTTPS |
| `continuumTravelAffiliatesApi` | `continuumGetawaysApi` | Queries availability, bundles, product sets, and hotel details | REST/JSON |
| `continuumTravelAffiliatesApi` | `continuumSeoNameService` | Resolves partner SEO identifiers | HTTP |
| `continuumTravelAffiliatesApi` | `continuumTravelAffiliatesFeedBucket` | Uploads generated hotel feed XML files | AWS SDK |
| `continuumTravelAffiliatesApi` | `continuumTravelAffiliatesDb` | Reads/writes operational data via JNDI datasource | JDBC |
| `continuumTravelAffiliatesCron` | `continuumGetawaysApi` | Pulls hotel availability and details for feed generation | REST/JSON |
| `continuumTravelAffiliatesCron` | `continuumTravelAffiliatesFeedBucket` | Uploads scheduled hotel feed XML exports | AWS SDK |

## Architecture Diagram References

- System context: `contexts-travel-affiliates-api`
- Container: `containers-travel-affiliates-api`
- Component: `components-continuum-travel-affiliates-api`
- Component (Cron): `components-continuum-travel-affiliates-cron`
- Dynamic: `dynamic-affiliate-availability-flow`
