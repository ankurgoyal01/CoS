---
service: "service-portal"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumServicePortalWeb, continuumServicePortalWorker, continuumServicePortalDb, continuumServicePortalRedis]
---

# Architecture Context

## System Context

Service Portal sits within the **Continuum** platform as an internal engineering governance tool. Engineering teams and CI pipelines interact with it directly via its REST API. It depends on GitHub Enterprise for repository data (receiving webhooks and making outbound API calls), Google services for team identity and notifications, and Jira Cloud for ORR issue management. It has no end-user-facing traffic; all consumers are internal Groupon engineering systems and engineers.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Web App | `continuumServicePortalWeb` | Web Application | Ruby on Rails / Puma | Rails 8.0.2.1 | Serves the REST API, handles GitHub webhook ingestion, and renders reports |
| Workers | `continuumServicePortalWorker` | Background Worker | Sidekiq | < 7.2 | Runs scheduled and on-demand checks, cost tracking, and inactivity reporting |
| MySQL Database | `continuumServicePortalDb` | Database | MySQL | — | Primary relational store for service records, check results, ORR data, costs |
| Redis | `continuumServicePortalRedis` | Cache / Queue | Redis | 5.0.0 | Sidekiq job queue and application-level caching |

## Components by Container

### Web App (`continuumServicePortalWeb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Services API (v2) | CRUD for service records; metadata, check results, dependencies, costs sub-resources | Rails controllers, JSON |
| Checks API (v2) | Query and trigger service check results | Rails controllers, JSON |
| Service Attributes API (v1) | Legacy attribute management for backward compatibility | Rails controllers, JSON |
| Validation endpoint | Validates uploaded `service.yml` files for CI pipelines | Rails controller |
| GitHub Webhook processor | Ingests push/PR events from GitHub Enterprise and enqueues sync jobs | Rails controller, HMAC verification |
| Reports endpoint | Generates and serves inactivity and cost reports | Rails controllers |

### Workers (`continuumServicePortalWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Scheduled check runner | Executes governance checks against all registered services on a cron schedule | Sidekiq, sidekiq-cron |
| GitHub sync worker | Syncs repository metadata from GitHub Enterprise after webhook events | Sidekiq, Faraday |
| Cost tracking worker | Collects and evaluates cost data per service; triggers alerts | Sidekiq, sidekiq-cron |
| Inactivity report worker | Identifies and reports stale/inactive services | Sidekiq, sidekiq-cron |
| Google Chat notifier | Sends alert and status notifications to team spaces | Sidekiq, google-apis-chat_v1 |

> No component IDs are defined in the central architecture model. The components above are derived from the service inventory.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumServicePortalWeb` | `continuumServicePortalDb` | Reads and writes all service catalog data | TCP / MySQL protocol |
| `continuumServicePortalWeb` | `continuumServicePortalRedis` | Enqueues background jobs; reads cached data | TCP / Redis protocol |
| `continuumServicePortalWeb` | GitHub Enterprise | Receives inbound webhooks; makes outbound REST API calls | HTTPS / REST + HMAC |
| `continuumServicePortalWeb` | Google Chat | Sends notifications to team spaces | HTTPS / REST |
| `continuumServicePortalWorker` | `continuumServicePortalDb` | Reads service records; writes check results, cost records | TCP / MySQL protocol |
| `continuumServicePortalWorker` | `continuumServicePortalRedis` | Reads job queue; writes job state and cache entries | TCP / Redis protocol |
| `continuumServicePortalWorker` | GitHub Enterprise | Fetches repository metadata for sync | HTTPS / REST |
| `continuumServicePortalWorker` | Google Chat | Sends scheduled alert notifications | HTTPS / REST |
| `continuumServicePortalWorker` | Google Directory | Looks up team ownership and group membership | HTTPS / REST |

## Architecture Diagram References

- System context: `contexts-service-portal`
- Container: `containers-service-portal`
- Component: `components-service-portal`
