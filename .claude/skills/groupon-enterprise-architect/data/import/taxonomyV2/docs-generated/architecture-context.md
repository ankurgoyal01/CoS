---
service: "taxonomyV2"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumTaxonomyV2Service"
    - "continuumTaxonomyV2Postgres"
    - "continuumTaxonomyV2Redis"
    - "continuumTaxonomyV2MessageBus"
    - "continuumTaxonomyV2VarnishCluster"
    - "continuumTaxonomyV2VarnishValidationService"
    - "continuumTaxonomyV2SlackApi"
    - "continuumTaxonomyV2EmailGateway"
    - "continuumTaxonomyV2AuthoringService"
---

# Architecture Context

## System Context

Taxonomy V2 sits within the `continuumSystem` (Continuum Platform) as the canonical category data service. Internal Groupon services — deal platform, merchant platform, search, and browse — call Taxonomy V2 to resolve category hierarchies and attributes. Content is authored upstream in the `continuumTaxonomyV2AuthoringService` and deployed into Taxonomy V2 via snapshot activation workflows. When content is activated, the service invalidates the `continuumTaxonomyV2VarnishCluster` and sends notifications via Slack and SMTP. The service is multi-region (US and EMEA) and backed by PostgreSQL with a Redis cache-aside layer.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| TaxonomyV2 Service | `continuumTaxonomyV2Service` | Backend API | Java 11, Dropwizard, JTier | Core REST API service providing taxonomy, category, relationship, snapshot, and internal management endpoints |
| TaxonomyV2 Postgres DB | `continuumTaxonomyV2Postgres` | Database | PostgreSQL (DaaS) | Primary relational store for taxonomy structures, content versions, snapshots, locales, relationships, and service users |
| TaxonomyV2 Redis Cache | `continuumTaxonomyV2Redis` | Cache | Redis via Redisson (RaaS) | Distributed cache storing denormalized taxonomy content and lookup data for low-latency read access |
| TaxonomyV2 Message Bus | `continuumTaxonomyV2MessageBus` | Messaging | JMS Message Bus | Asynchronous messaging for content update and cache invalidation events |
| Varnish Edge Cache Cluster | `continuumTaxonomyV2VarnishCluster` | Cache | Varnish | Edge caching layer whose hosts are invalidated when taxonomy content is deployed |
| Varnish Validation Service | `continuumTaxonomyV2VarnishValidationService` | Backend | HTTP, Jenkins | Jenkins-backed validation pipeline verifying Varnish behavior after deployments |
| Slack Incoming Webhook API | `continuumTaxonomyV2SlackApi` | External | Slack HTTP API | External Slack webhook for deployment and cache build notifications |
| SMTP Email Gateway | `continuumTaxonomyV2EmailGateway` | External | SMTP | External SMTP server for email notifications about taxonomy deployments and failures |
| Taxonomy Authoring Service | `continuumTaxonomyV2AuthoringService` | Backend | HTTP, JSON | Upstream authoring UI and workflow service providing taxonomy content via HTTP |

## Components by Container

### TaxonomyV2 Service (`continuumTaxonomyV2Service`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| REST API Resources (`continuumTaxonomyV2Service_restApi`) | Exposes taxonomy, category, relationship, snapshot, PT snapshot, and internal HTML endpoints | Jersey, Dropwizard |
| Frontend Views (`continuumTaxonomyV2Service_frontendViews`) | Renders HTML views and serves static assets for internal taxonomy management pages | Dropwizard Views, Freemarker |
| Request Filters & Authorization (`continuumTaxonomyV2Service_requestFilters`) | Enforces authorization and cache validation on incoming requests | Jersey Filters |
| Domain Model & Builders (`continuumTaxonomyV2Service_domainModel`) | Core taxonomy domain objects and builder classes for attributes, categories, relationships, locales, and taxonomy trees | Java |
| Postgres Repositories (`continuumTaxonomyV2Service_postgresRepositories`) | JDBI DAOs and mappers accessing Postgres tables for taxonomy content, snapshots, relationships, locales, and service users | JDBI, PostgreSQL |
| Caching & Cache Builder Services (`continuumTaxonomyV2Service_cachingCore`) | Redis-backed caching and builders that materialize and refresh cached taxonomy structures for live and test environments | Redisson, Redis |
| Snapshot & PT Snapshot Management (`continuumTaxonomyV2Service_snapshotManagement`) | Manages content snapshots, deploys content to test/live, coordinates cache invalidation, and updates snapshot state | Java |
| Search Service (`continuumTaxonomyV2Service_searchService`) | Provides search over cached taxonomy data for categories and relationships | Java |
| User & Role Management (`continuumTaxonomyV2Service_userManagement`) | Manages service users and roles used by authorization filters | Java |
| Notification Orchestration Service (`continuumTaxonomyV2Service_notificationOrchestration`) | Orchestrates notifications to Slack, email, Varnish validation, and message bus clients about cache builds and deployments | Java |
| External Notification Clients (`continuumTaxonomyV2Service_externalNotificationClients`) | HTTP and SMTP clients for Slack webhooks and email delivery | OkHttp, SMTP |
| Varnish Edge Cache Client (`continuumTaxonomyV2Service_varnishEdgeClient`) | HTTP client that invalidates Varnish edge cache nodes when taxonomy content is deployed | OkHttp |
| Message Bus Integration & Processors (`continuumTaxonomyV2Service_messageBusIntegration`) | JMS-based writers/readers and processors handling content update and cache invalidation events | JMS, jtier-messagebus |
| Health Checks & Diagnostics (`continuumTaxonomyV2Service_healthChecks`) | Health checks for Redis connectivity and Postgres availability | Dropwizard HealthChecks |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumTaxonomyV2Service` | `continuumTaxonomyV2Postgres` | Reads and writes taxonomy content, categories, relationships, locales, content versions, snapshots | JDBC, JDBI |
| `continuumTaxonomyV2Service` | `continuumTaxonomyV2Redis` | Caches denormalized taxonomy data for fast read access | Redisson, Redis |
| `continuumTaxonomyV2Service` | `continuumTaxonomyV2MessageBus` | Publishes and consumes content update and cache invalidation events | JMS, jtier-messagebus |
| `continuumTaxonomyV2Service` | `continuumTaxonomyV2SlackApi` | Sends deployment and cache build notifications | HTTPS, Slack Webhook |
| `continuumTaxonomyV2Service` | `continuumTaxonomyV2EmailGateway` | Sends email alerts for deployment failures and cache build issues | SMTP |
| `continuumTaxonomyV2Service` | `continuumTaxonomyV2VarnishCluster` | Invalidates edge cache hosts when taxonomy content is activated or rebuilt | HTTP BAN |
| `continuumTaxonomyV2Service` | `continuumTaxonomyV2VarnishValidationService` | Triggers Jenkins-based Varnish validation jobs after deployments | HTTPS |
| `continuumTaxonomyV2Service` | `continuumTaxonomyV2AuthoringService` | Consumes taxonomy content authored upstream for deployment and caching | HTTP, JSON |
| `continuumTaxonomyV2MessageBus` | `continuumTaxonomyV2Service` | Delivers cache invalidation messages that drive worker pool processing inside the service | JMS |
| `continuumTaxonomyV2Service_restApi` | `continuumTaxonomyV2Service_snapshotManagement` | Invokes snapshot and PT snapshot operations for activating taxonomy content | In-process |
| `continuumTaxonomyV2Service_snapshotManagement` | `continuumTaxonomyV2Service_cachingCore` | Flushes and rebuilds Redis caches as part of snapshot activation | In-process |
| `continuumTaxonomyV2Service_snapshotManagement` | `continuumTaxonomyV2Service_notificationOrchestration` | Notifies stakeholders of deployment and cache build outcomes | In-process |
| `continuumTaxonomyV2Service_messageBusIntegration` | `continuumTaxonomyV2Service_snapshotManagement` | Dispatches cache invalidation messages to snapshot services | In-process |

## Architecture Diagram References

- System context: `contexts-taxonomyV2`
- Container: `containers-taxonomyV2`
- Component: `components-continuum-taxonomy-v2-service-components-view`
- Dynamic (cache invalidation): `dynamic-taxonomy-v2-cache-invalidation-flow`
