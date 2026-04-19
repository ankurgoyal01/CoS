---
service: "selfsetup-fd"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for EMEA BT Self-Setup (Food & Drinks).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Employee Initiates F&D Setup](employee-initiate-fd-setup.md) | synchronous | Employee submits opportunity ID in the setup wizard | Employee-driven initiation: opportunity lookup, capping validation, and job enqueue |
| [Validate F&D Deal Eligibility](validate-fd-deal-eligibility.md) | synchronous | Called during setup wizard submission | Applies capping and validation rules against the Salesforce opportunity before enqueuing |
| [Async Configure BT Options](async-configure-bt-options.md) | scheduled | Cron job processes pending queue entries | Cron-driven: dequeues setup jobs, resolves merchant IDs from Salesforce, calls Booking Tool API |
| [Fetch Merchant BT Details](fetch-merchant-bt-details.md) | synchronous | Employee or cron requests current BT configuration | Retrieves existing Booking Tool instance details for a merchant via the BT API |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

Both the web-initiated setup flow and the async cron flow span `continuumEmeaBtSelfSetupFdApp`, `salesForce`, and `bookingToolSystem_7f1d`. The authoritative dynamic view is defined in the Structurizr model as `dynamic-ssu_fd_self_setup_flow` and covers the end-to-end path from opportunity fetch through BT creation.
