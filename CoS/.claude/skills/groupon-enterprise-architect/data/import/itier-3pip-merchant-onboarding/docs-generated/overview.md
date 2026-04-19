---
service: "itier-3pip-merchant-onboarding"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Merchant Services / Third-Party Integrations"
platform: "Continuum"
team: "Merchant Services"
status: active
tech_stack:
  language: "Node.js"
  language_version: "16.20.2"
  framework: "itier-server"
  framework_version: "7.9.1"
  runtime: "Node.js"
  runtime_version: "16.20.2"
  build_tool: "npm"
  package_manager: "npm"
---

# 3PIP Merchant Onboarding (itier-square) Overview

## Purpose

The 3PIP Merchant Onboarding service (`itier-3pip-merchant-onboarding`, also known as itier-square) provides the web-based UI and OAuth callback endpoints that guide merchants through connecting their Square, Mindbody, or Shopify accounts to Groupon. It orchestrates the full onboarding lifecycle — from initiating an OAuth redirect to persisting the resulting partner mapping and navigating the merchant onward to Merchant Center.

## Scope

### In scope

- Rendering onboarding and connection management UI pages for Square, Mindbody, and Shopify merchants
- Handling OAuth install redirects (`GET /install`) and OAuth callback returns (`GET /oauth-redirect`) for all three partner platforms
- Executing MSS (Merchant Self-Service) onboarding requests (`POST /mss-onboarding`)
- Decoding Okta-signed SSO tokens for merchant identity verification (`POST /decode-sso-token`)
- Calling Merchant API, Partner Service, and Users Service to persist and retrieve onboarding state
- Forwarding merchants to Merchant Center draft/deal and reservation landing pages after successful onboarding

### Out of scope

- Storing persistent merchant data (stateless service; all state lives in downstream APIs)
- Payment processing or transaction management
- Square, Mindbody, or Shopify platform-side configuration
- Salesforce CRM ownership (synchronized to, not owned by, this service)

## Domain Context

- **Business domain**: Merchant Services / Third-Party Integrations
- **Platform**: Continuum
- **Upstream consumers**: Merchant-facing browser clients initiating 3PIP onboarding
- **Downstream dependencies**: `continuumUniversalMerchantApi`, `continuumPartnerService`, `continuumUsersService`, `salesForce`, `merchantCenter`

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant Services Team | Owns and maintains this service |
| Platform Merchants | End users performing partner onboarding via the UI |
| Partner Integrations | Downstream teams consuming onboarding state from Partner Service and Merchant API |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Node.js | 16.20.2 | models/components.dsl |
| Framework | itier-server | 7.9.1 | service inventory |
| UI Framework | Preact | 10.5.13 | service inventory |
| Runtime | Node.js | 16.20.2 | models/containers.dsl |
| Build tool | npm | — | standard iTier toolchain |
| Package manager | npm | — | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.9.1 | http-framework | Core HTTP server and iTier application shell |
| preact | 10.5.13 | ui-framework | Server-side and client-side UI rendering |
| itier-user-auth | 8.1.0 | auth | User authentication middleware for iTier |
| @okta/jwt-verifier | — | auth | Validates Okta-signed JWT/SSO tokens |
| itier-merchant-api-client | — | http-client | Client for the internal Merchant API |
| @grpn/partner-service-client | — | http-client | Client for the internal Partner Service |
| @grpn/users-service-client | — | http-client | Client for the internal Users Service |
| @grpn/mindbody-client | — | http-client | Client for Mindbody API interactions |
| gofer | — | http-client | Base HTTP fetch abstraction used across clients |
| itier-cached | — | state-management | In-memory session cache |
| itier-feature-flags | — | validation | Runtime feature flag evaluation |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
