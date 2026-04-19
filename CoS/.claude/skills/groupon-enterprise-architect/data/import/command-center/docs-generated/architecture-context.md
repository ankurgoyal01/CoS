---
service: "command-center"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumCommandCenterWeb, continuumCommandCenterWorker, continuumCommandCenterMysql]
---

# Architecture Context

## System Context

Command Center is an internal operational tooling platform within the `continuumSystem` (Continuum Platform). It is accessed exclusively by internal Groupon operations and support staff. The web container handles synchronous tool requests, validation, scheduling, and reporting. The worker container executes long-running or bulk operations asynchronously. Both containers share a single MySQL data store for job queue state, business data, and audit records. Command Center depends on multiple Continuum platform APIs (Deal Management, Voucher Inventory, Orders, Places) as well as Salesforce CRM and the internal message bus.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Command Center Web | `continuumCommandCenterWeb` | WebApp | Ruby on Rails | Rails web application hosting internal bulk support tooling UI and operational workflow endpoints |
| Command Center Worker | `continuumCommandCenterWorker` | Backend | Ruby / Delayed Job | Worker process polling and executing asynchronous and batch tool jobs |
| Command Center MySQL | `continuumCommandCenterMysql` | Database | MySQL | Primary relational store for users, jobs, tool metadata, report artifacts, and delayed job queue records |

## Components by Container

### Command Center Web (`continuumCommandCenterWeb`)

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Tool Controllers | `cmdCenter_webControllers` | Handles HTTP requests for internal tooling endpoints and dashboards | ActionController |
| Tool Domain Services | `cmdCenter_webDomainServices` | Coordinates business workflows, validations, and job creation | Ruby Service Objects |
| Persistence Layer | `cmdCenter_webPersistence` | ActiveRecord models and repositories for tool, user, and job state | ActiveRecord |
| Outbound API Clients | `cmdCenter_webApiClients` | HTTP clients for deal, inventory, orders, and place platform APIs | HTTParty / Typhoeus |
| Mailer Layer | `cmdCenter_webMailer` | Composes and sends workflow status and failure notifications | ActionMailer |

### Command Center Worker (`continuumCommandCenterWorker`)

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Delayed Job Runner | `cmdCenter_workerRunner` | Worker runtime polling delayed_job queue and dispatching work units | delayed_job |
| Background Job Handlers | `cmdCenter_workerJobs` | Job classes and tool workers for bulk asynchronous execution | Ruby Jobs / Workers |
| Worker Persistence Layer | `cmdCenter_workerPersistence` | Persistence logic for job progress, retries, and outcomes | ActiveRecord |
| Worker Outbound API Clients | `cmdCenter_workerApiClients` | HTTP clients used by workers for asynchronous downstream mutations | HTTParty / Typhoeus |

### Command Center MySQL (`continuumCommandCenterMysql`)

| Component | ID | Responsibility | Technology |
|-----------|-----|---------------|-----------|
| Command Center Schema | `cmdCenter_schema` | Tables for users, tools, logs, report artifacts, and delayed job queue state | MySQL Schema |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumCommandCenterWeb` | `continuumCommandCenterMysql` | Reads and writes command-center data and delayed job queue records | ActiveRecord / MySQL |
| `continuumCommandCenterWorker` | `continuumCommandCenterMysql` | Dequeues and updates delayed job records and business data | ActiveRecord / MySQL |
| `continuumCommandCenterWeb` | `continuumCommandCenterWorker` | Schedules background jobs for asynchronous processing | Delayed Job |
| `continuumCommandCenterWeb` | `continuumDealCatalogService` | Reads deal and product metadata for tooling workflows | HTTP / JSON |
| `continuumCommandCenterWeb` | `continuumDealManagementApi` | Mutates deal, option, and distribution-window data | HTTP / JSON |
| `continuumCommandCenterWeb` | `continuumVoucherInventoryService` | Reads voucher and inventory product data | HTTP / JSON |
| `continuumCommandCenterWeb` | `continuumOrdersService` | Reads order information for selected support tooling workflows | HTTP / JSON |
| `continuumCommandCenterWeb` | `continuumM3PlacesService` | Reads and updates place metadata for M3 place tools | HTTP / JSON |
| `continuumCommandCenterWeb` | `salesForce` | Reads and validates merchant/deal metadata in selected tools | REST |
| `continuumCommandCenterWeb` | `messageBus` | Consumes and publishes workflow events | MBus |
| `continuumCommandCenterWeb` | `cloudPlatform` | Stores and retrieves CSV/job artifacts in object storage | S3 APIs |
| `continuumCommandCenterWorker` | `continuumDealManagementApi` | Applies asynchronous deal and option mutations | HTTP / JSON |
| `continuumCommandCenterWorker` | `continuumVoucherInventoryService` | Processes asynchronous voucher workflows | HTTP / JSON |
| `continuumCommandCenterWorker` | `continuumOrdersService` | Processes asynchronous order-related workflows | HTTP / JSON |
| `continuumCommandCenterWorker` | `salesForce` | Performs asynchronous Salesforce-backed updates | REST |
| `messageBus` | `continuumCommandCenterWorker` | Delivers events consumed by erasure and support workflows | MBus |

## Internal Component Relationships

| From | To | Description |
|------|----|-------------|
| `cmdCenter_webControllers` | `cmdCenter_webDomainServices` | Validates and dispatches tool requests |
| `cmdCenter_webDomainServices` | `cmdCenter_webPersistence` | Reads and writes tool, user, and job records |
| `cmdCenter_webDomainServices` | `cmdCenter_webApiClients` | Invokes downstream platform APIs |
| `cmdCenter_webDomainServices` | `cmdCenter_webMailer` | Sends workflow and result notifications |
| `cmdCenter_webDomainServices` | `cmdCenter_workerRunner` | Enqueues asynchronous background jobs |
| `cmdCenter_webPersistence` | `cmdCenter_schema` | Persists application and queue state |
| `cmdCenter_workerRunner` | `cmdCenter_workerJobs` | Dequeues and executes delayed jobs |
| `cmdCenter_workerJobs` | `cmdCenter_workerPersistence` | Loads and updates job execution state |
| `cmdCenter_workerJobs` | `cmdCenter_workerApiClients` | Calls downstream APIs for batch mutations |
| `cmdCenter_workerPersistence` | `cmdCenter_schema` | Persists job progress and outcomes |

## Architecture Diagram References

- Container: `containers-command-center`
- Component (web): `components-command-center-web`
- Component (worker): `components-command-center-worker`
- Dynamic (tool request processing): `dynamic-cmdcenter-tool-request-processing`
