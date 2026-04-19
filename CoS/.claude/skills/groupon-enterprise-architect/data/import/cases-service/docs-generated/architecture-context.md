---
service: "cases-service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumMerchantCaseService", "continuumMerchantCaseRedis"]
---

# Architecture Context

## System Context

The Merchant Cases Service (MCS) sits within the **Continuum** platform as a backend service in the Merchant Experience domain. It is the primary integration point between Groupon's Merchant Center portal and Salesforce CRM for all merchant support case management. Merchants interact with MCS through the Merchant Center frontend. MCS calls Salesforce for case persistence, Inbenta for knowledge management content, and several internal Groupon microservices for merchant data, user identity, notifications, and deal information. It also asynchronously consumes Salesforce-originated events from the Groupon message bus to keep case state and notifications current.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Merchant Case Service (MCS) | `continuumMerchantCaseService` | Backend | Java / Dropwizard / JTier | 4.5.x | Merchant case management workflows, API surface, business orchestration, and integration clients |
| Merchant Cases Redis | `continuumMerchantCaseRedis` | Cache | Redis | — | Transient cache for unread case counts and knowledge management data |

## Components by Container

### Merchant Case Service (MCS) (`continuumMerchantCaseService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`cases_apiResources`) | Exposes REST endpoints for case CRUD, support contacts, knowledge management, payment status, and deal approval | Java / Dropwizard JAX-RS Resources |
| Case Domain Services (`cases_domainServices`) | Orchestrates business logic for case creation, retrieval, update, status management, refund cases, counts, and merchant contact lookups | Java Services |
| Integration Clients (`cases_integrationClients`) | Outbound HTTP adapters for Salesforce, Inbenta, Rocketman, Users, M3, notification, and access services | Retrofit + RxJava3 / Generated API clients |
| Knowledge and Cache Management (`cases_knowledgeAndCache`) | Serves knowledge management content from Inbenta and caches unread counts and support-tree lookups in Redis | Java Services + Redis |
| Notification Processing (`cases_notificationProcessing`) | Consumes message bus topics for case, case-event, opportunity, notification, and account events; triggers downstream notification actions | Java / mbus-client JMS consumers |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMerchantCaseService` | `salesForce` | Creates, queries, and updates case-related Salesforce objects | HTTPS/REST |
| `continuumMerchantCaseService` | `continuumUsersService` | Retrieves merchant user details | HTTP/REST |
| `continuumMerchantCaseService` | `continuumM3MerchantService` | Retrieves merchant account context | HTTP/REST |
| `continuumMerchantCaseService` | `continuumDealCatalogService` | Retrieves deal metadata and attributes | HTTP/REST |
| `continuumMerchantCaseService` | `continuumMerchantCaseRedis` | Stores and reads transient cache values | Redis |
| `continuumMerchantCaseService` | `messageBus` | Consumes case, case-event, opportunity, onboarding, and account topics | JMS |
| `continuumMerchantCaseService` | `inbentaKnowledgeApi` | Searches and retrieves knowledge management content | HTTPS/REST (stub-only in federated model) |
| `continuumMerchantCaseService` | `rocketmanEmailApi` | Sends transactional case emails | HTTPS/REST (stub-only in federated model) |
| `continuumMerchantCaseService` | `issuesTranslationsApi` | Loads issue/category translations | HTTPS/REST (stub-only in federated model) |
| `continuumMerchantCaseService` | `mxNotificationService` | Triggers merchant notifications | HTTP/REST (stub-only in federated model) |
| `continuumMerchantCaseService` | `mxMerchantPreparationService` | Executes preparation and payment-related operations | HTTP/REST (stub-only in federated model) |
| `continuumMerchantCaseService` | `salesforceCacheService` | Fetches cached Salesforce-related data | HTTP/REST (stub-only in federated model) |
| `continuumMerchantCaseService` | `mxMerchantAccessService` | Validates merchant access permissions | HTTP/REST (stub-only in federated model) |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-merchant-case-service-components`
- Dynamic flow: `dynamic-cases-case-flow`
