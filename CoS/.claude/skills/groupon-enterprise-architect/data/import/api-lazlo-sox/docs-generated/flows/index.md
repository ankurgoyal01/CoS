---
service: "api-lazlo-sox"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for API Lazlo / API Lazlo SOX.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Mobile API Request Flow](mobile-api-request-flow.md) | synchronous | HTTP request from mobile client | End-to-end flow of a typical mobile API request through the gateway |
| [SOX Request Flow](sox-request-flow.md) | synchronous | HTTP request from SOX-regulated client | Request flow through the SOX-scoped gateway with compliance controls |
| [User Authentication Flow](user-authentication-flow.md) | synchronous | User login / OTP / session validation | User authentication and account verification flow |
| [Deal Discovery Flow](deal-discovery-flow.md) | synchronous | User browsing deals | Deal discovery, search, and listing aggregation flow |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- All API Lazlo flows are cross-service by nature, as the gateway aggregates responses from multiple downstream domain services for each request.
- The central architecture model contains dynamic views for key flows; see the Structurizr workspace views for animated sequences.
