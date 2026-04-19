---
service: "mobile-flutter-merchant"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMobileFlutterMerchantApp]
---

# Architecture Context

## System Context

The Mobile Flutter Merchant app is a container within the `continuumSystem` — Groupon's core commerce platform. It sits at the merchant-facing edge of the Continuum platform, acting as the primary mobile interface through which merchants interact with Groupon's backend services. The app consumes multiple Continuum APIs and third-party services but does not expose any APIs of its own. Merchants authenticate via Google OAuth and access deal, payment, redemption, and location data through the app.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Mobile Flutter Merchant App | `continuumMobileFlutterMerchantApp` | Mobile App | Flutter (Dart), iOS, Android | Flutter 3.27.2 / Dart 3.27.2 | Cross-platform Flutter mobile client used by Groupon merchants for authentication, deal management, redemption, payments, places, and support workflows. |

## Components by Container

### Mobile Flutter Merchant App (`continuumMobileFlutterMerchantApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `mmaPresentationLayer` | Flutter UI routes, widgets, and state connectors for merchant workflows | Flutter UI |
| `mmaAuthenticationModule` | Okta/webview login orchestration, token handling, and session state management | Auth/Session |
| `mmaApiOrchestrator` | Shared HTTP client and endpoint-specific clients for merchant data domains | HTTP Client Layer |
| `mmaMerchantEngagementModule` | Messaging, onboarding, advisor, inbox, and notification-oriented feature flows | Feature Module |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMobileFlutterMerchantApp` | `continuumUniversalMerchantApi` | Calls merchant APIs for dashboard, deals, vouchers, and account workflows | REST/HTTP |
| `continuumMobileFlutterMerchantApp` | `continuumDealManagementApi` | Reads and updates deal draft/change workflows | REST/HTTP |
| `continuumMobileFlutterMerchantApp` | `continuumM3PlacesService` | Reads and updates merchant place/location data | REST/HTTP |
| `continuumMobileFlutterMerchantApp` | `continuumPaymentsService` | Retrieves payment schedules and payment details | REST/HTTP |
| `continuumMobileFlutterMerchantApp` | `merchantAdvisorService` | Retrieves merchant advisor insights and recommendations | REST/HTTP |
| `continuumMobileFlutterMerchantApp` | `notsService` | Fetches onboarding todos and dismiss actions | REST/HTTP |
| `continuumMobileFlutterMerchantApp` | `salesForce` | Uses Salesforce messaging and support integrations | SDK/REST |
| `continuumMobileFlutterMerchantApp` | `googleMaps` | Renders merchant/location maps and geospatial views | SDK |
| `continuumMobileFlutterMerchantApp` | `googleOAuth` | Performs web authentication during merchant sign-in flows | OAuth2/WebView |
| `mmaPresentationLayer` | `mmaAuthenticationModule` | Starts and resumes sign-in/session flows | Direct |
| `mmaPresentationLayer` | `mmaApiOrchestrator` | Requests dashboard, deals, vouchers, payments, and places data | Direct |
| `mmaPresentationLayer` | `mmaMerchantEngagementModule` | Triggers onboarding, messaging, advisor, and notification UX flows | Direct |
| `mmaAuthenticationModule` | `mmaApiOrchestrator` | Provides authenticated context for downstream API calls | Direct |
| `mmaMerchantEngagementModule` | `mmaApiOrchestrator` | Requests engagement and support data through shared API client paths | Direct |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-mobile-flutter-merchant-app`
