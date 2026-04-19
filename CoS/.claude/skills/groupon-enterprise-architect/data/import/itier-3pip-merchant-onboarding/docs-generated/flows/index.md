---
service: "itier-3pip-merchant-onboarding"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for 3PIP Merchant Onboarding (itier-square).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Square Onboarding](square-onboarding.md) | synchronous | Merchant initiates Square account connection | Full OAuth2 install and callback flow for linking a Square POS account to Groupon |
| [Mindbody Onboarding](mindbody-onboarding.md) | synchronous | Merchant initiates Mindbody account connection | OAuth and API activation flow for linking a Mindbody account to Groupon |
| [Shopify Onboarding](shopify-onboarding.md) | synchronous | Merchant initiates Shopify store connection | OAuth2 install and callback flow for linking a Shopify store to Groupon |
| [MSS Onboarding](mss-onboarding.md) | synchronous | Merchant submits MSS onboarding form | Merchant Self-Service onboarding data submission and partner activation via Partner Service |
| [Connection Management](connection-management.md) | synchronous | Merchant views or modifies existing 3PIP connection | Retrieves current partner connection state and allows re-authorization or disconnection |
| [SSO Token Verification](sso-token-verification.md) | synchronous | Merchant arrives via SSO link | Decodes and validates an Okta-signed SSO token to establish merchant identity |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 6 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Square Onboarding flow has a defined architecture dynamic view (`square-oauth-callback`) in the DSL — currently stub-only because the Square external platform is not modeled in the central Continuum architecture. See [Square Onboarding](square-onboarding.md) for the full step sequence and [Architecture Context](../architecture-context.md) for the diagram reference.
