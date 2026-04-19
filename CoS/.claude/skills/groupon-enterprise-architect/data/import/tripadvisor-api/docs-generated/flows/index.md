---
service: "tripadvisor-api"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Getaways Affiliate API (tripadvisor-api).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Partner Hotel Availability](partner-hotel-availability.md) | synchronous | POST from TripAdvisor or Trivago partner | Partner requests real-time hotel availability; service queries Getaways APIs and returns formatted response |
| [Google Transaction Query](google-transaction-query.md) | synchronous | POST from Google Hotel Ads with XML Query document | Receives Google pricing query, fetches availability and pricing, returns Transaction XML |
| [Google Hotel List Feed](google-hotel-list-feed.md) | synchronous | POST from Google Hotel Ads | Returns the complete list of Groupon Getaways hotel properties for Google indexing |
| [Google Query Control Message](google-query-control-message.md) | synchronous | POST from Google Hotel Ads | Returns the static XML query control document describing booking capability constraints |
| [Heartbeat Management](heartbeat-management.md) | synchronous | PUT/DELETE from load balancer management or operator | Enables or disables the heartbeat file that controls load balancer membership |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The partner hotel availability flow and Google transaction query flow span multiple services:

- `continuumTripadvisorApiV1Webapp` calls `getawaysSearchApi` for real-time hotel availability
- `continuumTripadvisorApiV1Webapp` calls `getawaysContentApi` for hotel product sets and detail

These cross-service interactions are modelled as relationships in the Structurizr DSL at `architecture/models/relations.dsl`. Dynamic views for these flows are pending (`architecture/views/dynamics.dsl` — no dynamic views defined yet).
