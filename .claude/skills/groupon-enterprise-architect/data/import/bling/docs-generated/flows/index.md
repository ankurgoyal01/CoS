---
service: "bling"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for bling (Finance & Accounting SPA).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Finance Data Viewing](finance-data-viewing.md) | synchronous | User navigates to invoice, contract, or payment list in browser | User loads financial records from Accounting Service via the Nginx proxy |
| [Invoice Approval](invoice-approval.md) | synchronous | Finance staff submits approval or rejection action in the invoice detail view | Invoice status transitions through the v3 API via PATCH to Accounting Service |
| [Paysource File Upload](paysource-file-upload.md) | synchronous | Finance staff selects and submits a file in the paysource upload view | File is uploaded to File Sharing Service and the paysource record is created in Accounting Service |
| [Contract Management](contract-management.md) | synchronous | User navigates to contract detail or edits contract line items | Contract and line item data is fetched and updated via Accounting Service v1 API |
| [Search and Batch](search-and-batch.md) | synchronous | User enters search criteria or navigates to batch status view | Cross-entity search and payment batch records are fetched from Accounting Service |
| [User Authentication](user-authentication.md) | synchronous | User accesses bling in the browser for the first time or session expires | Okta SSO is initiated via Hybrid Boundary OAuth2 proxy |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All bling flows cross service boundaries through the `blingNginx` reverse proxy to `continuumAccountingService` and `fileSharingService`. Authentication for every flow passes through the Hybrid Boundary OAuth2 proxy, which validates Okta tokens before requests reach the backend.

- The [Finance Data Viewing](finance-data-viewing.md) and [Invoice Approval](invoice-approval.md) flows are the highest-frequency operations and depend entirely on `continuumAccountingService` availability.
- The [Paysource File Upload](paysource-file-upload.md) flow is the only flow that involves `fileSharingService` as a primary participant.
- The [User Authentication](user-authentication.md) flow is a prerequisite for all other flows; Hybrid Boundary / Okta must be available for any user session to be established.
