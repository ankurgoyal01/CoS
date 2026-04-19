---
service: "next-pwa-app"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "mbnxtSystem"
  containers: ["mbnxtWebsite", "mbnxtGraphQL", "mbnxtAndroidApp", "mbnxtIosApp"]
---

# Architecture Context

## System Context

The MBNXT Platform (`mbnxtSystem`) is Groupon's next-generation consumer-facing system. It sits at the edge of the Groupon architecture, directly serving end consumers via web browsers and mobile apps. It depends heavily on Continuum backend services for deal data, user accounts, orders, checkout, and search relevance. The system is modeled as a single Structurizr software system containing four containers that share a common Nx monorepo codebase.

Consumers interact with the web application or mobile apps, which communicate with the MBNXT GraphQL API. The GraphQL layer fans out to numerous Continuum and Encore backend services via REST/HTTP, aggregating data and orchestrating business logic before returning responses.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| MBNXT Web | `mbnxtWebsite` | WebApp | React / Next.js | New consumer website -- the primary Groupon PWA experience |
| MBNXT GraphQL | `mbnxtGraphQL` | Gateway | Node.js / GraphQL / ITier | GraphQL API serving web and mobile clients |
| MBNXT Android App | `mbnxtAndroidApp` | MobileApp | React Native (Android) | Consumer mobile app for Android |
| MBNXT iOS App | `mbnxtIosApp` | MobileApp | React Native (iOS) | Consumer mobile app for iOS |

## Components by Container

### MBNXT Web (`mbnxtWebsite`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web Routing & Pages (`web_routing`) | Implements routing, SSR and page composition for the web app | Next.js pages, app router, React Server Components |
| Web UI Components (`web_ui`) | Reusable UI components and layout primitives | React, Tailwind, internal UI libs |
| Web GraphQL Client (`web_graphql_client`) | Configures and uses Apollo Client; manages GraphQL queries and mutations | Apollo Client |
| Web Feature Modules (`web_feature_modules`) | Feature modules for deals, checkout, account, homepage, etc. | React, internal feature libs |

### MBNXT GraphQL (`mbnxtGraphQL`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| GraphQL Schema & Resolvers (`graphql_schema`) | Defines the GraphQL schema, queries, mutations, and resolvers | Apollo Server, GraphQL |
| API Models (`api_models`) | Shared API models and type definitions for GraphQL | TypeScript, shared model libs |
| API Data Sources (`api_data_sources`) | Integrations with Groupon backend services, deal feeds, and feature flag services | Custom HTTP/GraphQL clients |
| Observability & Instrumentation (`api_observability`) | Cross-cutting concerns such as logging, metrics, and tracing | OpenTelemetry, internal logging libs |

### MBNXT Android App (`mbnxtAndroidApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Mobile App Shell & Navigation (`mobile_shell_android`) | Entry point, navigation stack, and deep linking setup | React Navigation, Expo |
| Mobile Screens & Features (`mobile_screens_android`) | Screens and feature flows for deals, checkout, wishlist, gifts, etc. | React Native, internal feature libs |
| Mobile Data Access (`mobile_data_access_android`) | Abstraction layer around GraphQL/REST for mobile | Custom data access layer |
| Mobile Platform Integrations (`mobile_platform_integrations_android`) | Native integrations: push notifications, device APIs, location, calendar, in-app browser | React Native modules, Expo SDK |

### MBNXT iOS App (`mbnxtIosApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Mobile App Shell & Navigation (`mobile_shell_ios`) | Entry point, navigation stack, and deep linking setup | React Navigation, Expo |
| Mobile Screens & Features (`mobile_screens_ios`) | Screens and feature flows for deals, checkout, wishlist, gifts, etc. | React Native, internal feature libs |
| Mobile Data Access (`mobile_data_access_ios`) | Abstraction layer around GraphQL/REST for mobile | Custom data access layer |
| Mobile Platform Integrations (`mobile_platform_integrations_ios`) | Native integrations: push notifications, device APIs, location, calendar, in-app browser | React Native modules, Expo SDK |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `consumer` | `mbnxtWebsite` | Uses | HTTPS |
| `affiliate` | `mbnxtWebsite` | Sends users via affiliate links | HTTPS |
| `mbnxtTeam` | `mbnxtWebsite` | Owns and operates | Ownership |
| `consumer` | `mbnxtAndroidApp` | Uses | HTTPS |
| `consumer` | `mbnxtIosApp` | Uses | HTTPS |
| `consumer` | `web_routing` | Navigates and interacts via browser | HTTPS |
| `web_routing` | `web_ui` | Renders UI using | Direct |
| `web_routing` | `web_feature_modules` | Delegates feature-specific behavior to | Direct |
| `web_feature_modules` | `web_ui` | Composes UI from | Direct |
| `web_feature_modules` | `web_graphql_client` | Loads data using | Direct |
| `web_graphql_client` | `mbnxtGraphQL` | Sends GraphQL queries and mutations to | HTTPS |
| `mbnxtGraphQL` | `apiProxy` | REST calls to aggregation APIs | JSON/HTTPS |
| `mbnxtGraphQL` | `continuumApiLazloService` | Reads deal and checkout data | HTTPS/JSON |
| `mbnxtGraphQL` | `continuumRelevanceApi` | Fetches search and feed ranking data | HTTPS/JSON |
| `mbnxtGraphQL` | `continuumDealManagementApi` | Retrieves merchandising and deal metadata | HTTPS/JSON |
| `mbnxtGraphQL` | `continuumUsersService` | Reads and updates account data | HTTPS/JSON |
| `mbnxtGraphQL` | `continuumOrdersService` | Creates and reads orders | HTTPS/JSON |
| `mbnxtGraphQL` | `continuumGeoService` | Resolves division and location data | HTTPS/JSON |
| `mbnxtGraphQL` | `continuumUgcService` | Retrieves ratings and reviews | HTTPS/JSON |
| `mbnxtGraphQL` | `booster` | Fetches ranked feed payloads | HTTPS/JSON |
| `mbnxtGraphQL` | `voucherCloudApi` | Retrieves voucher/coupon content | HTTPS/JSON |
| `mbnxtGraphQL` | `encoreDealReviews` | Fetches deal review data | HTTPS/JSON |
| `mbnxtGraphQL` | `encoreGoGorapiAutocomplete` | Fetches autocomplete suggestions | HTTPS/JSON |

## Architecture Diagram References

- System context: `contexts-mbnxt`
- Container: `containers-mbnxt`
- Component (Web): `components-continuum-mbnxt-web`
- Component (GraphQL): `components-continuum-mbnxt-graphql`
- Component (Android): `components-continuum-mbnxt-mobile_shell_android`
- Component (iOS): `components-continuum-mbnxt-mobile_shell_ios`
- Dynamic (Browse & Checkout): `dynamic-consumer-browse-and-checkout`
