---
service: "taxonomyV2"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 4
---

# Integrations

## Overview

Taxonomy V2 integrates with 4 external systems (Slack, SMTP, Varnish cluster, and the Jenkins-backed Varnish validation service) and 4 internal Groupon infrastructure services (PostgreSQL DaaS, Redis RaaS, JMS message bus, and the Taxonomy Authoring Service). External integrations are focused on notifications and edge cache management; internal integrations cover data persistence, caching, and messaging. All outbound HTTP calls use the `jtier-okhttp` client library.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Slack Incoming Webhook API | HTTPS, Webhook | Send deployment and cache build notifications to the #taxonomy channel | No | `continuumTaxonomyV2SlackApi` |
| SMTP Email Gateway | SMTP | Send email alerts for deployment failures and cache build issues to taxonomy-dev@groupon.com | No | `continuumTaxonomyV2EmailGateway` |
| Varnish Edge Cache Cluster | HTTP BAN | Invalidate edge cache nodes when taxonomy content is activated or rebuilt | Yes | `continuumTaxonomyV2VarnishCluster` |
| Varnish Validation Service | HTTPS | Trigger Jenkins-based Varnish validation jobs after deployments to verify cache behavior | No | `continuumTaxonomyV2VarnishValidationService` |

### Slack Incoming Webhook API Detail

- **Protocol**: HTTPS (Slack HTTP API)
- **Base URL / SDK**: Slack incoming webhook URL (configured via service config; client class: `SlackClient.java`)
- **Auth**: Webhook token embedded in the webhook URL (secret)
- **Purpose**: Sends real-time notifications about snapshot deployment start, success, and failure to the #taxonomy Slack channel
- **Failure mode**: Non-critical — Slack delivery failures are logged but do not block deployment workflows
- **Circuit breaker**: No evidence found in codebase

### SMTP Email Gateway Detail

- **Protocol**: SMTP
- **Base URL / SDK**: `javax.mail` (version 1.4.7); client class: `EmailClient.java`; configured in `MailerConfig.java`
- **Auth**: SMTP server credentials (secrets via deployment configuration)
- **Purpose**: Sends email alerts to taxonomy-dev@groupon.com for deployment failures and cache build issues
- **Failure mode**: Non-critical — email delivery failures do not block deployment workflows
- **Circuit breaker**: No evidence found in codebase

### Varnish Edge Cache Cluster Detail

- **Protocol**: HTTP BAN (Varnish cache purge/invalidation protocol)
- **Base URL / SDK**: Internal Varnish cluster host list; client class: `VarnishClient.java`
- **Auth**: Internal network access only (no external auth)
- **Purpose**: Invalidates Varnish edge cache after taxonomy content is activated so that downstream consumers pick up fresh data
- **Failure mode**: Critical for cache consistency — if Varnish invalidation fails, stale taxonomy data may be served at the edge until TTL expiry
- **Circuit breaker**: No evidence found in codebase

### Varnish Validation Service Detail

- **Protocol**: HTTPS (Jenkins webhook)
- **Base URL / SDK**: Jenkins HTTP endpoint; client class: `VarnishValidationClient.java`
- **Auth**: Internal network/credentials (configured via deployment config)
- **Purpose**: Triggers automated validation jobs to verify Varnish behavior and cache correctness after each taxonomy deployment
- **Failure mode**: Non-critical — validation failures generate notifications but do not roll back deployments automatically
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| PostgreSQL DaaS | JDBC, JDBI | Authoritative data persistence for all taxonomy content, snapshots, and metadata | `continuumTaxonomyV2Postgres` |
| Redis RaaS | Redis (Redisson) | Denormalized cache-aside store for low-latency taxonomy reads | `continuumTaxonomyV2Redis` |
| JMS Message Bus (mbus) | JMS, jtier-messagebus | Publish/consume cache invalidation and content update events | `continuumTaxonomyV2MessageBus` |
| Taxonomy Authoring Service | HTTP, JSON | Consume upstream-authored taxonomy content for deployment and caching | `continuumTaxonomyV2AuthoringService` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Taxonomy V2 is a Tier 1 platform service consumed broadly across Groupon's internal platform — known consumer domains include deal platform, merchant platform, search, browse, and the Bynder integration service (evidenced by `jms.topic.taxonomyV2.content.update` consumer in message bus metrics).

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Deal platform services | REST (HTTP) | Resolve category GUIDs for deal classification |
| Merchant platform services | REST (HTTP) | Resolve category structures for merchant taxonomy |
| Bynder integration service | JMS | Consume `jms.topic.taxonomyV2.content.update` for downstream content sync |
| Internal consumers (general) | REST (HTTP) | Category lookup, relationship browsing, taxonomy hierarchy queries |

## Dependency Health

- **PostgreSQL**: Health-checked via `continuumTaxonomyV2Service_healthChecks` component (lightweight Postgres connectivity check at service startup and runtime)
- **Redis**: Health-checked via `continuumTaxonomyV2Service_healthChecks` component (Redis connectivity verified via Redisson)
- **Message Bus**: Connection managed by `jtier-messagebus-client`; JMS reconnection is handled by the JTier framework
- **Varnish / Slack / Email**: No explicit circuit breaker or retry policy evidence; failures generate notifications via `continuumTaxonomyV2Service_notificationOrchestration`
