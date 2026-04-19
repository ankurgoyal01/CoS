---
service: "transporter-itier"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Transporter I-Tier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [CSV Upload Flow](csv-upload-flow.md) | synchronous | User selects CSV file and clicks Upload on `/new-upload` | User-initiated bulk Salesforce data operation via CSV; proxied through I-Tier to jtier backend |
| [Salesforce OAuth Login Flow](salesforce-oauth-login-flow.md) | synchronous | User accesses a protected page without a valid jtier user record | Redirects user to Salesforce OAuth2, handles callback, and validates the resulting token with jtier |
| [Job List and Pagination Flow](job-list-pagination-flow.md) | synchronous | User loads the `/` home page or changes page/filter state | Fetches paginated upload job records from jtier and renders the job history table |
| [Salesforce Read-Only View Flow](salesforce-readonly-view-flow.md) | synchronous | User navigates to `/sfdata` or submits an object/ID lookup | Fetches Salesforce object types and record data from jtier and renders a read-only view |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows in Transporter I-Tier span the boundary to `transporter-jtier`. The CSV upload flow is documented as a Structurizr dynamic view:

- Architecture dynamic view: `dynamic-upload-flow` (`continuumSystem`)

See [Architecture Context](../architecture-context.md) for container and component relationship details.
