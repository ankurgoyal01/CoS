---
service: "cases-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 8
---

# Integrations

## Overview

MCS has a rich integration landscape: two external third-party systems (Salesforce, Inbenta) and eight internal Groupon microservices. Salesforce is the critical dependency — if it is unavailable, case creation, retrieval, and update operations all fail. All HTTP integrations use Retrofit clients wrapped in RxJava3 singles/completables. Internal service URLs follow the pattern `http://<service-name>.<environment>.service`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce CRM | HTTPS/REST | Create, query, and update all case-related Salesforce objects | yes | `salesForce` |
| Inbenta Knowledge API | HTTPS/REST | Search and retrieve knowledge management articles, topics, and sessions | no | `inbentaKnowledgeApi` |

### Salesforce CRM Detail

- **Protocol**: HTTPS/REST (Salesforce REST API + OAuth2 password grant)
- **Base URL / SDK**: `https://groupon-dev--staging.sandbox.my.salesforce.com` (staging); production URL configured via `JTIER_RUN_CONFIG`
- **Auth**: OAuth2 password grant — `username`, `password`, `clientId`, `clientSecret`, `grantType=password` configured in `clients.salesforceAuthConfig`; access token retrieved via `salesforceAuth` client and applied via `SalesforceClientCustomizer`
- **Purpose**: Primary case persistence — creates Cases, EmailMessages, Attachments, and queries Account/Contact/Opportunity objects via SOQL
- **Failure mode**: All case CRUD API endpoints return errors; MCS cannot create or retrieve cases without Salesforce
- **Circuit breaker**: No evidence of circuit breaker configured; relies on Retrofit timeout settings (`connectTimeout: 2s`, `readTimeout: 30s`, `writeTimeout: 30s`, `maxRequestsPerHost: 15`)

### Inbenta Knowledge API Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Per-locale endpoints — `https://api-gcu1.inbenta.io` (EN, UK, IE, JA, BE_NL), `https://api-gce3.inbenta.io` (DE, ES, FR, IT, NL, PL, BE_FR), `https://api-gcu3.inbenta.io` (AE_EN, AU_EN, QC_FR), `https://api-gcu2.inbenta.io` (NZ_EN), `https://api.inbenta.io` (auth). Auth via `x-inbenta-key` header.
- **Auth**: Per-locale API key (`x-inbenta-key` header) + JWT secret configured as env vars (`${EN_APIKEY}`, `${DE_APIKEY}`, etc.)
- **Purpose**: Serves knowledge management content — topics, articles, popular/suggested articles, and full-text search — for all supported locales
- **Failure mode**: Knowledge management endpoints degrade gracefully; case creation and management remain functional
- **Circuit breaker**: No evidence of circuit breaker; timeouts: `connectTimeout: 2s`, `readTimeout: 5s`

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Users Service | HTTP/REST | Retrieve merchant user details for case owner resolution | `continuumUsersService` |
| M3 Merchant Service | HTTP/REST | Retrieve merchant account context (Salesforce account mapping) | `continuumM3MerchantService` |
| Deal Catalog Service | HTTP/REST | Retrieve deal metadata and attributes for deal-edit cases | `continuumDealCatalogService` |
| MX Notification Service (nots) | HTTP/REST | Trigger merchant-facing notifications after case events | `mxNotificationService` |
| Salesforce Cache Service (Reading Rainbow) | HTTP/REST | Fetch cached Salesforce-related data to reduce direct SF API calls | `salesforceCacheService` |
| MX Merchant Access Service (mas) | HTTP/REST | Validate merchant access permissions | `mxMerchantAccessService` |
| MX Merchant Preparation Service (mpres) | HTTP/REST | Execute preparation and payment-related operations | `mxMerchantPreparationService` |
| Issues Translations / Localize Service | HTTP/REST | Load issue category and sub-category translations for supported locales | `issuesTranslationsApi` |

### Users Service Detail

- **Protocol**: HTTP/REST
- **Base URL**: `http://users-service.staging.service` (staging)
- **Auth**: `X-API-KEY` header (`${USERS_AUTH_OPTS_VALUE}`)
- **Purpose**: Resolves merchant user profile for case ownership and reply operations
- **Failure mode**: Case operations requiring user context fail; others are unaffected

### M3 Merchant Service Detail

- **Protocol**: HTTP/REST
- **Base URL**: `http://m3-merchant-service.staging.service` (staging)
- **Auth**: `client_id` query parameter (`${M3_AUTH_OPTS_VALUE}`)
- **Purpose**: Retrieves Salesforce account ID and merchant account context needed for all Salesforce queries
- **Failure mode**: Case creation and retrieval fail without merchant account context

### Deal Catalog Service Detail

- **Protocol**: HTTP/REST
- **Base URL**: `http://deal-catalog.staging.service` (staging)
- **Auth**: `clientId` query parameter (`${DC_AUTH_OPTS_VALUE}`)
- **Purpose**: Fetches deal metadata for deal-edit case creation workflows
- **Failure mode**: Deal-edit case creation fails; other case types are unaffected

### MX Notification Service Detail

- **Protocol**: HTTP/REST
- **Base URL**: `http://mx-notification-service.staging.service` (staging)
- **Auth**: `X_API_KEY` header (`${NOTS_AUTH_OPTS_VALUE}`)
- **Purpose**: Delivers push/web notifications to merchants after case lifecycle events
- **Failure mode**: Notification delivery fails but case operations succeed; errors logged via `NotsErrorLogData`

### Rocketman Transactional Email

- **Protocol**: HTTP/REST
- **Base URL**: `http://rocketman-transactional.staging.service` (staging)
- **Auth**: `client_id` query parameter (`${ROCKETMAN_AUTH_OPTS_VALUE}`)
- **Purpose**: Sends transactional emails for case-related events (confirmation, updates)
- **Failure mode**: Email notifications fail; case data is unaffected

## Consumed By

> Upstream consumers are tracked in the central architecture model. The primary consumer is the Merchant Center frontend (`merchantSupportClient`) which calls all case management and knowledge management endpoints.

## Dependency Health

- All internal and external HTTP clients use Retrofit with configurable `connectTimeout`, `readTimeout`, `writeTimeout`, and `maxRequestsPerHost` / `maxConcurrentRequests` pool settings defined in the per-environment YAML config.
- No circuit breaker pattern (e.g., Hystrix, Resilience4j) was found in the codebase.
- Health check available at `GET /grpn/healthcheck` (HTTP 200 = healthy).
- Wavefront alert fires if outgoing call failure rate exceeds 100 per 4-minute window (see [Runbook](runbook.md)).
