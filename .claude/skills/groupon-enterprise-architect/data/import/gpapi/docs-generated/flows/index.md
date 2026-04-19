---
service: "gpapi"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for Goods Product API (gpapi).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Vendor Onboarding](vendor-onboarding.md) | synchronous | New vendor registration request from Vendor Portal | Creates vendor account, links users, initiates compliance checks, and provisions vendor in downstream systems |
| [User-Vendor Linking](user-vendor-linking.md) | synchronous | Admin or vendor user links a portal user to a vendor account | Associates a portal user account with one or more vendor records in gpapi and downstream Users Service |
| [Product Lifecycle](product-lifecycle.md) | synchronous | Vendor submits product create/update/deactivate action | Manages full product lifecycle from draft through approval to active/deactivated state across gpapi and Goods Product Catalog |
| [Item Master Management](item-master-management.md) | synchronous | Vendor creates or updates item attributes and pricing | Creates and maintains item master records including vendor pricing via Pricing Service |
| [Contract Lifecycle](contract-lifecycle.md) | synchronous | Vendor or Groupon initiates contract create/update | Manages vendor contract creation, amendment, and status transitions coordinated with Commerce Interface |
| [Promotion Management](promotion-management.md) | synchronous | Vendor submits promotion or co-op agreement request | Creates and manages promotions and co-op agreements via Goods Promotion Manager |
| [Session Auth 2FA](session-auth-2fa.md) | synchronous | Vendor submits login credentials with reCAPTCHA token | Authenticates vendor portal user with reCAPTCHA Enterprise 2FA verification and establishes session |
| [Vendor Compliance Onboarding](vendor-compliance-onboarding.md) | synchronous | Vendor submits compliance documentation | Orchestrates vendor compliance data submission and verification through Vendor Compliance Service |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 8 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Vendor Onboarding** spans gpapi, Vendor Compliance Service (`continuumVendorComplianceService`), Users Service, DMAPI, and Goods Product Catalog. Referenced in the central architecture dynamic view: `dynamic-vendorOnboardingFlow`.
- **Product Lifecycle** spans gpapi, Goods Product Catalog, and Deal Catalog.
- **Promotion Management** spans gpapi and Goods Promotion Manager (`continuumGoodsPromotionManager`).
- **Contract Lifecycle** spans gpapi and Commerce Interface.
- All flows are documented in the central architecture model under the Continuum platform containers.
