---
service: "itier-merchant-inbound-acquisition"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Merchant Inbound Acquisition.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Lead Capture — Account Creation Path](lead-capture-account-creation.md) | synchronous | Merchant submits signup form (account-creation-enabled country) | Collects form data, validates, and creates a draft merchant record via Metro |
| [Lead Capture — Salesforce Path](lead-capture-salesforce.md) | synchronous | Merchant submits signup form (non-account-creation country) | Collects form data and creates a CRM Lead object in Salesforce |
| [Address Autocomplete](address-autocomplete.md) | synchronous | User types in city/address field | Proxies address suggestions from Groupon V2 address API to the browser form |
| [Field Deduplication Validation](field-deduplication.md) | synchronous | Form field loses focus (client-side trigger) | Validates a single field against the Metro draft service to detect duplicate businesses |
| [Merchant Configuration and PDS Load](config-and-pds-load.md) | synchronous | Page load / form initialization | Loads locale-specific merchant configuration and product-deal-service taxonomy from Metro |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The lead capture flows span this service and downstream platforms:

- [Lead Capture — Account Creation Path](lead-capture-account-creation.md) involves `continuumMerchantInboundAcquisitionService` and `continuumMetroPlatform` (draft merchant service)
- [Lead Capture — Salesforce Path](lead-capture-salesforce.md) involves `continuumMerchantInboundAcquisitionService` and `salesForce`
- [Address Autocomplete](address-autocomplete.md) involves `continuumMerchantInboundAcquisitionService` and `continuumApiLazloService`

The architecture dynamic view for lead capture is: `dynamic-merchant-lead-capture-flow`
