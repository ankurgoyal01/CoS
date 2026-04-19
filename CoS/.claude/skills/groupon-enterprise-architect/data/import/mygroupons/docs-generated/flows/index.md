---
service: "mygroupons"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for My Groupons.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Render My Groupons Page](render-mygroupons-page.md) | synchronous | User navigates to `/mygroupons` | Orchestrates fetching and rendering of the full post-purchase deal list |
| [Request Voucher PDF Download](request-voucher-pdf-download.md) | synchronous | User requests `/mygroupons/vouchers/:id/pdf` | Renders a voucher as a PDF using headless Chromium and streams it to the browser |
| [Submit Return Request](submit-return-request.md) | synchronous | User submits return form at `/mygroupons/returns` | Validates return eligibility and submits return request to Voucher Inventory Service |
| [Exchange Voucher](exchange-voucher.md) | synchronous | User submits exchange at `/mygroupons/exchanges` | Checks third-party inventory, validates eligibility, and submits exchange to Voucher Inventory Service |
| [Send Voucher Gift](send-voucher-gift.md) | synchronous | User submits gifting form at `/mygroupons/gifting` | Delivers a voucher gift to a recipient via email or SMS |
| [Load Order Tracking](load-order-tracking.md) | synchronous | User views `/mygroupons/track-order/:id` | Fetches shipment tracking data from Orders and Third-Party Inventory services |
| [Manage Groupon Bucks Balance](manage-groupon-bucks-balance.md) | synchronous | User views `/mygroupons/my-bucks` | Retrieves and displays the user's Groupon Bucks balance and transaction history |
| [Render Account Details Editor](render-account-details-editor.md) | synchronous | User views `/mygroupons/account/details` | Fetches and renders user account details for editing |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 8 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All My Groupons flows span multiple services via `continuumMygrouponsService`'s request orchestration layer (`myGroupons_requestOrchestration`). Key cross-service interactions are described in each flow file. Central architecture dynamic views covering these flows are referenced as `dynamic-mygroupons-*` and catalogued in the Continuum architecture model.
