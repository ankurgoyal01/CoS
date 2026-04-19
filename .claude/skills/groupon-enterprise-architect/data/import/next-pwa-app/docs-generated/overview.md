---
service: "next-pwa-app"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Consumer Commerce"
platform: "MBNXT"
team: "MBNXT / Mobile-Next"
status: active
tech_stack:
  language: "TypeScript"
  language_version: "5.6.2"
  framework: "Next.js"
  framework_version: "15.3.3"
  runtime: "Node.js"
  runtime_version: "22.14.0"
  build_tool: "Nx 20.8.1"
  package_manager: "bun"
---

# next-pwa-app (MBNXT) Overview

## Purpose

next-pwa-app is Groupon's next-generation consumer-facing platform, replacing the legacy web and mobile experiences with a unified codebase. It serves the primary Groupon PWA web experience via a Next.js application while also powering React Native mobile applications for iOS and Android via a shared Nx monorepo. The platform provides deal browsing, search, checkout, account management, gifting, coupons, and the full consumer commerce lifecycle through a unified GraphQL API layer.

## Scope

### In scope
- Consumer web experience (deal browse, search, deal pages, checkout, cart, account, gifting, coupons, wishlists, receipts, my groupons)
- Server-side rendered and statically generated pages via Next.js (hybrid App Router and Pages Router)
- Unified GraphQL API (`/api/graphql`) serving both web and mobile clients
- React Native mobile applications for iOS (Expo) and Android (Expo)
- Internationalization and locale management across all supported Groupon markets
- Middleware chain for routing, authorization, locale detection, A/B testing, and security
- SEO: sitemaps, structured data, localized URLs, and redirects
- LLM-embeddable deal content (gpt-embed app)
- Storybook component library and design system integration

### Out of scope
- Backend deal management and merchant tools (handled by Continuum services)
- Payment processing infrastructure (delegated to downstream payment services via API proxy)
- Search ranking and relevance algorithms (handled by Continuum Relevance API / Booster)
- User-generated content storage (handled by Continuum UGC Service)
- Order fulfillment and shipment tracking backends (handled by Continuum Orders/Shipments services)

## Domain Context

- **Business domain**: Consumer Commerce
- **Platform**: MBNXT
- **Upstream consumers**: End consumers (web browsers, mobile apps), affiliate partners, search engine crawlers
- **Downstream dependencies**: Continuum API Proxy (Lazlo), Continuum Relevance API, Continuum Deal Management API, Continuum Users Service, Continuum Orders Service, Continuum Geo Service, Continuum UGC Service, Booster, VoucherCloud API, Encore Deal Reviews, Encore Go Gorapi Autocomplete, GrowthBook (experimentation), MapTiler, Sentry, Elastic APM

## Stakeholders

| Role | Description |
|------|-------------|
| MBNXT Team (i-tier-devs@groupon.com) | Owns and operates the platform |
| Mobile-Next org | GitHub organization and codeowners |
| Consumer product teams | Define features across deal, checkout, gifting, coupons domains |
| SEO / Growth teams | Depend on SSR, sitemaps, and localized URL structures |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | 5.6.2 | `package.json` |
| Framework | Next.js | 15.3.3 | `package.json` (via `@next-pwa-app/platform/next`) |
| Runtime | Node.js | 22.14.0 | `.nvmrc`, `volta` config in `package.json` |
| Build tool | Nx | 20.8.1 | `package.json`, `nx.json` |
| Package manager | bun | (per `.bun-version`) | `package.json` scripts |
| Monorepo bundler | Turbopack (default) / Webpack (fallback) | -- | `next-config/base.ts` |
| Process manager | wattpm (Platformatic) | 3.30.0 | `watt.json` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Apollo Client | * | state-management | GraphQL data fetching on web and mobile clients |
| Apollo Server | * | http-framework | GraphQL API layer serving resolvers and data sources |
| React | 19.x | ui-framework | Component rendering across web and mobile |
| React Native | 0.79.6 | ui-framework | Mobile application framework (via Expo 53) |
| Expo | 53.0.23 | ui-framework | React Native build/deploy toolchain |
| TailwindCSS | 3.3.2 | ui-framework | Utility-first CSS for web styling |
| NativeWind | * | ui-framework | Tailwind CSS for React Native |
| Zustand | * | state-management | Client-side local state management |
| Radix UI | * | ui-framework | Headless accessible UI primitives |
| Sentry (NextJS) | * | logging | Error tracking and performance monitoring |
| OpenTelemetry | * | metrics | Distributed tracing and instrumentation |
| GrowthBook | * | auth | Feature flags and A/B experimentation |
| Partytown | * | ui-framework | Offloads third-party scripts to web workers |
| Jest | * | testing | Unit and integration testing |
| Playwright | * | testing | End-to-end web testing |
| Detox | * | testing | End-to-end mobile testing |
| Biome | * | validation | Code formatting (replaces Prettier) |
| ESLint | * | validation | Code quality linting |
| GraphQL Code Generator | * | serialization | Type-safe GraphQL operation generation |
| keldor-config | * | http-framework | Runtime configuration management (ITier) |
| itier-client-platform | * | http-framework | ITier service mesh integration |
| MaxMind GeoIP2 | * | auth | IP-based geolocation for locale detection |

> Only the most important libraries are listed here -- the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
