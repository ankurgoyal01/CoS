---
service: "gazebo"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumGazebo"
  containers: [continuumGazeboWebApp, continuumGazeboWorker, continuumGazeboMbusConsumer, continuumGazeboCron, continuumGazeboMysql, continuumGazeboRedis]
---

# Architecture Context

## System Context

Gazebo is the editorial tooling service within the Continuum platform. It is used exclusively by internal editorial staff to manage deal copy and publishing workflows. It depends on the Groupon Message Bus for asynchronous event exchange with other Continuum services, on Salesforce CRM for deal and opportunity data, on the Users Service for profile lookups, on the Deal Catalog Service for deal metadata, and on Bynder for media assets. Gazebo publishes content change events back to the Message Bus when copy is updated or published, enabling downstream services to react to editorial changes.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Gazebo Web App | `continuumGazeboWebApp` | Web Application | Ruby on Rails | 4.1 | Primary Rails application serving the editorial UI and REST API endpoints |
| Gazebo Worker | `continuumGazeboWorker` | Background Worker | Ruby | 2.1.2 | Background job processor handling async tasks and data sync operations |
| Gazebo MBus Consumer | `continuumGazeboMbusConsumer` | Event Consumer | Ruby / Messagebus | 0.2.8 | Subscribes to Message Bus topics and routes events to handlers |
| Gazebo Cron | `continuumGazeboCron` | Scheduled Job Runner | Ruby / Rake | 4.1 | Executes scheduled jobs including Salesforce CRM sync |
| Gazebo MySQL | `continuumGazeboMysql` | Database | MySQL | — | Primary relational data store for deals, tasks, users, channels, and content |
| Gazebo Redis | `continuumGazeboRedis` | Cache | Redis | 3.3.0 | Session data, feature flag state, and cached objects |

## Components by Container

### Gazebo Web App (`continuumGazeboWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deals Controller | Fetch and update deal information via `/v2/deals` endpoints | Rails |
| Tasks Controller | Manage editorial task lifecycle (claim, unclaim, complete) | Rails |
| Merchandising Checklist Controller | Serve and persist checklist state for quality validation | Rails |
| Users Controller | Serve user profile and permissions data | Rails |
| Recycle Bin Controller | Handle content recovery for deleted items | Rails |
| API Controllers | JSON API endpoints for tasks and translation requests | Rails |
| Flipper UI | Feature flag management at `/flipper` | Flipper gem |
| Salesforce Client | Real-time CRM reads and updates via Restforce | Restforce |
| Bynder Client | Media asset lookup and management | Typhoeus / REST |
| Feature Flag Store | Redis-backed flag state read by Flipper | Flipper / Redis |

### Gazebo Worker (`continuumGazeboWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Async Job Processor | Executes background jobs queued from the web app | Ruby |
| User/Deal Data Refresher | Fetches updated profiles and deal data from upstream services | Typhoeus |
| Media Asset Syncer | Syncs Bynder assets into local data store | Typhoeus |

### Gazebo MBus Consumer (`continuumGazeboMbusConsumer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Event Router | Dispatches incoming Message Bus events to the appropriate handler | Messagebus 0.2.8 |
| Deal Updated Handler | Processes `deal.updated` events and updates local deal records | Ruby |
| Opportunity Changed Handler | Processes `opportunity.changed` events from Salesforce-derived notifications | Ruby |
| Task Notification Handler | Processes `task_notification`, `goods_task` events | Ruby |
| Contract/Info Request Handler | Processes `contract_stage_notification`, `information_request_notification` | Ruby |

### Gazebo Cron (`continuumGazeboCron`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Salesforce Sync Job | Queries Salesforce via Restforce and updates MySQL with latest CRM data | Ruby / Rake |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGazeboWebApp` | `continuumGazeboMysql` | Reads and writes data | MySQL |
| `continuumGazeboWorker` | `continuumGazeboMysql` | Reads and writes data | MySQL |
| `continuumGazeboMbusConsumer` | `continuumGazeboMysql` | Reads and writes data | MySQL |
| `continuumGazeboCron` | `continuumGazeboMysql` | Reads and writes data | MySQL |
| `continuumGazeboWebApp` | `continuumGazeboRedis` | Caches data (sessions, flags, objects) | Redis |
| `continuumGazeboWorker` | `continuumGazeboRedis` | Caches data | Redis |
| `continuumGazeboWebApp` | `continuumUsersService` | Fetches user profiles | REST |
| `continuumGazeboWebApp` | `continuumDealCatalogService` | Fetches deal data | REST |
| `continuumGazeboWebApp` | `salesForce` | Reads and updates CRM data | Restforce SDK |
| `continuumGazeboWebApp` | `continuumBynderIntegrationService` | Manages media assets | REST |
| `continuumGazeboWorker` | `continuumUsersService` | Fetches user profiles | REST |
| `continuumGazeboWorker` | `continuumDealCatalogService` | Fetches deal data | REST |
| `continuumGazeboWorker` | `salesForce` | Syncs CRM data | Restforce SDK |
| `continuumGazeboWorker` | `continuumBynderIntegrationService` | Syncs media assets | REST |
| `continuumGazeboMbusConsumer` | `mbusSystem_18ea34` | Consumes events | Message Bus |
| `continuumGazeboWebApp` | `mbusSystem_18ea34` | Publishes content change events | Message Bus |

## Architecture Diagram References

- System context: `contexts-gazebo`
- Container: `containers-gazebo`
- Component: `components-gazebo`
