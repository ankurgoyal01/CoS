---
service: "merchant-preview"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Merchant Preview.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Preview Review](merchant-preview-review.md) | synchronous | Merchant opens preview link | End-to-end flow for a merchant accessing a deal preview, viewing creative content, and submitting comments or an approval decision |
| [Comment Workflow](comment-workflow.md) | synchronous | Merchant or account manager submits a comment or approval action | Lifecycle of a comment or approval action from creation through Salesforce update and email notification |
| [Cron Salesforce Sync](cron-salesforce-sync.md) | scheduled | Scheduled cron execution (Rake task) | Background synchronization of unresolved comments and workflow records from the local database to Salesforce |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The merchant preview review flow spans multiple systems. The canonical dynamic view is `dynamic-merchant-preview-request-mpCommentWorkflow` in the central Continuum architecture model. This view captures:

- Merchant accesses preview via `akamai`
- `continuumMerchantPreviewService` fetches deal content from `continuumDealCatalogService`
- `continuumMerchantPreviewService` reads/writes comments in `continuumMerchantPreviewDatabase`
- `continuumMerchantPreviewService` reads/updates approval state in `salesForce`
