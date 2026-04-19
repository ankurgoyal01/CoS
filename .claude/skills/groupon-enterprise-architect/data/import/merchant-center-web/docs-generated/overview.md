---
service: "merchant-center-web"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Merchant Experience Platform"
platform: "continuum"
team: "Merchant Experience"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.9.3"
  framework: "React"
  framework_version: "19.0.0"
  runtime: "Bun / Node.js"
  runtime_version: "23.11.0"
  build_tool: "Vite 7.1.11"
  package_manager: "Bun"
---

# Merchant Center Web Overview

## Purpose

Merchant Center Web is the primary self-service web portal for Groupon merchants. It provides a unified interface for merchants to create and manage deals, track orders and voucher redemptions, monitor campaign performance, manage inventory, and configure their account settings. The application sits at the boundary between the merchant and Groupon's backend commerce platform (Continuum), translating merchant intent into API calls against UMAPI and related services.

## Scope

### In scope

- Merchant authentication and SSO via Doorman
- Two-factor authentication (2FA) enrollment and verification
- Merchant onboarding wizard
- Deal/campaign creation and editing
- Voucher redemption management
- Order viewing and reporting
- Performance analytics and report generation
- Inventory management
- Account and profile settings management
- Digital asset management via Bynder integration
- AI-assisted image classification via AIaaS
- Feature flag-gated functionality via GrowthBook
- Session analytics via PostHog and Microsoft Clarity
- Internationalization (i18n) via i18next

### Out of scope

- Backend business logic (owned by UMAPI)
- Pricing and deal approval workflows (owned by Continuum backend services)
- Customer-facing storefront (separate application)
- Merchant payments and invoicing (handled by financial services)

## Domain Context

- **Business domain**: Merchant Experience Platform
- **Platform**: continuum
- **Upstream consumers**: Merchants (human users via web browser)
- **Downstream dependencies**: UMAPI, AIDG, AIaaS, Bynder, Salesforce, Doorman SSO

## Stakeholders

| Role | Description |
|------|-------------|
| Merchant | Primary end-user; creates and manages deals and account via the portal |
| Merchant Success Manager | Uses portal functionality on behalf of merchants; tracked via Salesforce CRM integration |
| Product / Engineering | Owns feature flag configuration via GrowthBook |
| Analytics | Consumes PostHog session data and Google Tag Manager event stream |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.9.3 | package.json |
| Framework | React | 19.0.0 | package.json |
| Runtime | Bun / Node.js | 23.11.0 | package.json |
| Build tool | Vite | 7.1.11 | package.json |
| Package manager | Bun | | package.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| react-router-dom | 7.1.4 | ui-framework | Client-side routing for SPA navigation |
| @tanstack/react-query | 5.90.12 | http-framework | Server-state management, data fetching, caching |
| react-hook-form | 7.62.0 | validation | Form state management and validation |
| zod | 4.1.5 | validation | Schema-based runtime validation |
| @mui/material | 6.4.2 | ui-framework | Material UI component library |
| tailwindcss | 4.1.18 | ui-framework | Utility-first CSS framework |
| i18next | 25.7.2 | serialization | Internationalization and translations |
| @opentelemetry/sdk-trace-web | 1.30.1 | metrics | Browser-side distributed tracing |
| @growthbook/growthbook-react | 1.6.5 | metrics | Feature flags and A/B testing |
| @posthog/react | 1.8.0 | metrics | Product analytics and session recording |
| chart.js | 4.4.8 | ui-framework | Data visualization and analytics charts |
| @storybook/react | 10.2.8 | testing | Component development and visual testing |
| vitest | 3.2.4 | testing | Unit and integration test runner |
| @playwright/test | 1.49.0 | testing | End-to-end browser testing |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
