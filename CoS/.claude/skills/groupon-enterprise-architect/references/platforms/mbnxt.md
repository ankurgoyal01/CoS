# MBNXT Platform

> Tier 3 reference — factual, concise, architect-focused

## Current State

- **Structurizr ID:** 8265
- **Containers:** 8
- **Role:** Next-gen consumer experience — web (PWA) and native mobile apps
- **Tech Stack:** Next.js PWA, React Native, GraphQL
- **Modeling:** MBNXT is modeled as part of the Continuum platform in Structurizr — it has its own platform ID but integrates directly with Continuum services. The domain view `containers-continuum-platform-mbnxt` shows 7 elements within Continuum's scope.
- **Status:** Active production with international expansion underway. Replacing legacy consumer apps (Legacy Web id:303, Legacy Android id:301, Legacy iOS id:302 — all marked ToDecommission).

## Surfaces

| Surface | Technology | Description |
|---------|-----------|-------------|
| Web | Next.js PWA (touch/responsive) | Progressive web app for desktop and mobile browsers |
| iOS | React Native | Native iOS app replacing legacy Objective-C/Swift app |
| Android | React Native | Native Android app replacing legacy app |
| GraphQL API | GraphQL | API layer aggregating Continuum backend services for consumer clients |

## International Expansion

Active in 13 countries as of February 2026:

**North America:** US, CA, CA-QC (Quebec — separate locale)

**EMEA:** GB, DE, FR, IT, ES, NL, BE, PL, IE, AE

**APAC:** AU

EMEA rollout is planned as all-at-once deployment with feature-flag split against legacy iOS app. This allows gradual traffic migration per country while maintaining fallback to legacy apps.

## Release & Testing

- **Release cadence:** Daily releases
- **CI/CD:** Jenkins CI pipeline
- **E2E testing:** Playwright end-to-end test suite
- **Feature flags:** Feature-flag driven rollout per country and per surface

## Team Ownership

**MBNXT Team (id:10)** owns:
- MBNXT Web (Next.js PWA)
- MBNXT GraphQL API
- MBNXT Android (React Native)
- Legacy iOS app (maintained during transition)

## Relationship to Continuum

- **Integration:** MBNXT integrates with Continuum via API calls. The GraphQL API layer serves as the aggregation point, calling Continuum backend services for deals, orders, inventory, user data, and other commerce functionality.
- **Domain View:** `containers-continuum-platform-mbnxt` — 7 elements within the Continuum domain view, reflecting how MBNXT surfaces are modeled as consumer-facing containers within the broader Continuum ecosystem.
- **System-level Relationship:** MBNXT Platform (id:8265) integrates with Continuum Platform (id:297) via API calls for legacy services.

## Actors

| Actor | ID | Relationship |
|-------|----|-------------|
| Consumer | 1 | Purchases and redeems deals; touches MBNXT web + Android + iOS |
| Affiliate Partner | 5 | Drives traffic via MBNXT web and legacy apps |

## Source Links

| Document | Link |
|----------|------|
| MBNXT Documentation | [MD](https://groupondev.atlassian.net/wiki/spaces/MD/) |
| MBNXT Containers | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82253447276/Mobile-Next+Containers) |
| MBNXT Components | [ARCH](https://groupondev.atlassian.net/wiki/spaces/ARCH/pages/82253512786) |
| B2C Tribe Architecture | [CONSUMERXP](https://groupondev.atlassian.net/wiki/spaces/CONSUMERXP/pages/82227920968/Architecture) |
| MBNXT International Readiness | [Confluence](https://groupondev.atlassian.net/wiki/spaces/~712020c11fe51675d74604805a948251ecad9d/pages/82526044660) |
| Structurizr Repository | [GitHub](https://github.com/groupon/architecture) |
