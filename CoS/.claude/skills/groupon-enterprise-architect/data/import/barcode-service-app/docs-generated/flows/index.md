---
service: "barcode-service-app"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Barcode Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Barcode Generation (Standard)](barcode-generation.md) | synchronous | HTTP GET request | Core flow: validates inputs, generates, and returns a barcode image using the v2 or v3 API |
| [JEDI Barcode Generation](jedi-barcode-generation.md) | synchronous | HTTP GET request | Variant flow for merchant center redemption URLs using unencoded path segments |
| [Legacy Mobile Barcode Generation](legacy-mobile-barcode-generation.md) | synchronous | HTTP GET request | Legacy v1 flow for mobile clients with explicit file extension in path |
| [Barcode Width Lookup](barcode-width-lookup.md) | synchronous | HTTP GET request | Computes and returns the pixel width of a barcode for a given code type and base64 payload |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

All flows are fully contained within Barcode Service — no cross-service calls are made at runtime. The architecture dynamic view `dynamic-barcode-generation-flow` in the Structurizr model documents the canonical generation flow. See [Architecture Context](../architecture-context.md) for component-level flow details.
