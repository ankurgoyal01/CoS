---
service: "merchant-preview"
title: "Merchant Preview Review Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "merchant-preview-review"
flow_type: synchronous
trigger: "Merchant opens merchant preview link"
participants:
  - "merchant"
  - "akamai"
  - "continuumMerchantPreviewService"
  - "continuumDealCatalogService"
  - "continuumMerchantPreviewDatabase"
  - "salesForce"
architecture_ref: "dynamic-merchant-preview-request-mpCommentWorkflow"
---

# Merchant Preview Review Flow

## Summary

This flow describes the end-to-end path taken when a merchant opens a deal preview link to review creative content. The service retrieves deal details from the Deal Catalog Service, loads existing comments and workflow state from its database, and reads current approval state from Salesforce in order to render a complete, up-to-date preview page for the merchant.

## Trigger

- **Type**: user-action
- **Source**: Merchant opens the merchant preview link (public URL fronted by Akamai CDN)
- **Frequency**: On demand, per merchant review session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant | Initiates review by opening preview URL | — |
| Akamai CDN | Routes external merchant request to service backend | `akamai` |
| Merchant Preview Service | Orchestrates page rendering, fetches deal content and state | `continuumMerchantPreviewService` |
| Deal Catalog Service | Provides deal IDs and creative content for preview | `continuumDealCatalogService` |
| Merchant Preview Database | Stores and serves existing comments and workflow state | `continuumMerchantPreviewDatabase` |
| Salesforce | Provides current Opportunity and Task approval workflow state | `salesForce` |

## Steps

1. **Merchant opens preview link**: Merchant accesses the merchant preview URL.
   - From: `merchant`
   - To: `akamai`
   - Protocol: HTTPS

2. **Akamai routes request**: Akamai CDN forwards the public request to the service backend.
   - From: `akamai`
   - To: `continuumMerchantPreviewService`
   - Protocol: HTTP (internal routing)

3. **Fetch deal catalog details**: Service requests deal IDs and creative content from Deal Catalog Service.
   - From: `continuumMerchantPreviewService`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP

4. **Read comments and workflow state**: Service reads existing comments and current workflow state from database.
   - From: `continuumMerchantPreviewService`
   - To: `continuumMerchantPreviewDatabase`
   - Protocol: MySQL

5. **Read approval workflow state**: Service reads current Opportunity and Task state from Salesforce.
   - From: `continuumMerchantPreviewService`
   - To: `salesForce`
   - Protocol: HTTPS (databasedotcom)

6. **Render and return preview page**: Service assembles deal creative, comments, and approval state into a preview page and returns it to the merchant.
   - From: `continuumMerchantPreviewService`
   - To: `merchant` (via `akamai`)
   - Protocol: HTTP response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unavailable | HTTP error from `continuumDealCatalogService` | Preview page cannot render deal creative; error returned to merchant |
| Database unreachable | Connection error to `continuumMerchantPreviewDatabase` | Preview page cannot load; error returned to merchant |
| Salesforce unavailable | API error from `salesForce` | Approval state unavailable; page may render partially or show stale state |
| Akamai routing failure | Edge-level error | Merchant receives network error before reaching service |

## Sequence Diagram

```
Merchant -> Akamai: Opens merchant preview link (HTTPS)
Akamai -> continuumMerchantPreviewService: Forwards request (HTTP)
continuumMerchantPreviewService -> continuumDealCatalogService: Fetches deal catalog details (HTTP)
continuumDealCatalogService --> continuumMerchantPreviewService: Returns deal creative content
continuumMerchantPreviewService -> continuumMerchantPreviewDatabase: Reads/writes comments (MySQL)
continuumMerchantPreviewDatabase --> continuumMerchantPreviewService: Returns comments and workflow state
continuumMerchantPreviewService -> salesForce: Reads/updates approval workflow state (HTTPS)
salesForce --> continuumMerchantPreviewService: Returns Opportunity/Task state
continuumMerchantPreviewService --> Akamai: Returns rendered preview page (HTTP)
Akamai --> Merchant: Delivers preview page (HTTPS)
```

## Related

- Architecture dynamic view: `dynamic-merchant-preview-request-mpCommentWorkflow`
- Related flows: [Comment Workflow](comment-workflow.md), [Cron Salesforce Sync](cron-salesforce-sync.md)
