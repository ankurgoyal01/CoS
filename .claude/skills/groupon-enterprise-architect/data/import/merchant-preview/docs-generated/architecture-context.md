---
service: "merchant-preview"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMerchantPreviewService, continuumMerchantPreviewCronWorker, continuumMerchantPreviewDatabase]
---

# Architecture Context

## System Context

Merchant Preview operates within the Continuum platform as a deal-lifecycle support service. It sits between external deal stakeholders (merchants and account managers) and the core deal data layer. Merchants access preview pages through the Akamai CDN; account managers access them via an internal gateway. The service reads deal creative data from `continuumDealCatalogService` and writes approval state to `salesForce`. A scheduled cron worker runs independently to keep Salesforce synchronized with unresolved comments and workflow records.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Merchant Preview Service | `continuumMerchantPreviewService` | Web Application | Ruby on Rails | — | Legacy Rails application serving merchant and account manager preview workflows, comments, and approval actions |
| Merchant Preview Cron Worker | `continuumMerchantPreviewCronWorker` | Worker | Ruby (Rake/Cron) | — | Scheduled rake-task worker running background jobs such as Salesforce comment sync and notification processing |
| Merchant Preview Database | `continuumMerchantPreviewDatabase` | Database | MySQL | — | Primary relational datastore for preview comments, feature records, and workflow state |

## Components by Container

### Merchant Preview Service (`continuumMerchantPreviewService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Preview Web Controller Layer (`mpPreviewWebController`) | Rails controllers and presenters handling preview pages and user actions | Ruby on Rails MVC |
| Comment Workflow Engine (`mpCommentWorkflow`) | Comment create/update/resolve logic and merchant approval handling | Ruby Domain Logic |
| Deal Aggregation Client (`mpDealAggregationClient`) | Integrates Deal Catalog and Deal Estate responses into rendered preview models | Ruby HTTP Client |
| Salesforce API Client (`mpSalesforceApiClient`) | databasedotcom-backed client for Salesforce query and mutation workflows | Ruby Client (databasedotcom) |
| Preview Mailer (`mpPreviewMailer`) | ActionMailer templates and delivery logic for preview-related emails | ActionMailer |

### Merchant Preview Cron Worker (`continuumMerchantPreviewCronWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Salesforce Case Sync Job (`mpSfCaseCronJob`) | Scheduled rake workflow for comment sync and status updates | Ruby Rake Task |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMerchantPreviewService` | `continuumMerchantPreviewDatabase` | Reads and writes comments and feature state | MySQL |
| `continuumMerchantPreviewService` | `continuumDealCatalogService` | Retrieves deal IDs and creative content | HTTP |
| `continuumMerchantPreviewService` | `salesForce` | Reads and updates Opportunity/Task data | HTTPS (databasedotcom) |
| `continuumMerchantPreviewService` | `smtpRelay` | Sends transactional preview emails via SMTP | SMTP |
| `continuumMerchantPreviewService` | `loggingStack` | Emits structured application logs | — |
| `continuumMerchantPreviewService` | `metricsStack` | Emits application and request metrics | — |
| `continuumMerchantPreviewService` | `tracingStack` | Emits traces and timing spans | — |
| `continuumMerchantPreviewCronWorker` | `continuumMerchantPreviewDatabase` | Reads unresolved comments and workflow records | MySQL |
| `continuumMerchantPreviewCronWorker` | `salesForce` | Queries and updates Salesforce task/opportunity records | HTTPS (databasedotcom) |
| `continuumMerchantPreviewCronWorker` | `smtpRelay` | Sends scheduled email notifications | SMTP |
| `continuumMerchantPreviewCronWorker` | `loggingStack` | Emits cron task logs | — |
| `mpPreviewWebController` | `mpDealAggregationClient` | Fetches deal and creative content for preview rendering | direct |
| `mpCommentWorkflow` | `mpSalesforceApiClient` | Updates deal approval/task state in Salesforce | direct |
| `mpCommentWorkflow` | `mpPreviewMailer` | Sends merchant/account manager notification emails | direct |
| `mpSfCaseCronJob` | `mpSalesforceApiClient` | Synchronizes pending comments and Salesforce tasks | direct |

## Architecture Diagram References

- Component (service): `components-continuum-merchant-preview-service`
- Component (cron worker): `components-continuum-merchant-preview-cron-worker`
- Dynamic flow: `dynamic-merchant-preview-request-mpCommentWorkflow`
