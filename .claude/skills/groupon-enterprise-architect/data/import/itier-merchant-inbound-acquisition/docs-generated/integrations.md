---
service: "itier-merchant-inbound-acquisition"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 3
---

# Integrations

## Overview

The service has six meaningful integration points: three external (Salesforce CRM, Google Analytics, Google Tag Manager) and three internal Groupon platform services (Metro platform via `metro-client`, Groupon V2 address API via `itier-groupon-v2-client`, and Birdcage A/B testing). All integrations are synchronous HTTP or SDK-based calls — no message bus is used.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce CRM | REST (jsforce SDK) | Creates CRM Lead objects for merchant signups in non-account-creation countries | Yes | `salesForce` |
| Google Analytics (Universal Analytics) | HTTP (universal-analytics SDK) | Fires server-side lead submission and dedupe outcome tracking events | No | — |
| Google Tag Manager | Browser script injection | Country-specific GTM container injection for client-side analytics | No | — |

### Salesforce CRM Detail

- **Protocol**: REST via `jsforce` SDK
- **Base URL**: Staging — `https://test.salesforce.com`; Production — `https://groupon-dev.my.salesforce.com` (`config/stage/*.cson`)
- **Auth**: Username + password login via `jsforce.Connection.login()`. Credentials are stored in `config/stage/*.cson` (staging) and production config; the production password is a config secret.
- **Purpose**: When `enableLeadCreation` feature flag is active for the merchant's country, the lead handler opens a Salesforce connection, constructs a `Lead` sObject with business name, contact details, UTM fields, and opt-in flags, then calls `connection.sobject('Lead').create(leadData)`.
- **Failure mode**: On connection or creation failure, the error is logged via `itier-tracing`, a GA failure event is fired, and a JSON error response is returned to the browser. No retry or circuit breaker is implemented.
- **Circuit breaker**: No

### Google Analytics (Universal Analytics) Detail

- **Protocol**: HTTPS via `universal-analytics` npm SDK
- **Base URL / SDK**: `universal-analytics` ^0.4.17
- **Auth**: Country-specific GA tracking codes resolved via `ga-helper.js`
- **Purpose**: Fires `event()` calls for `web2lead-submit-draft`, `web2lead-submit-salesforce`, and `web2dedupe-submit-draft` outcomes (success / error) from server-side handlers
- **Failure mode**: Fire-and-forget (`.send()` with no await); failures do not affect lead creation responses
- **Circuit breaker**: No

### Google Tag Manager Detail

- **Protocol**: Browser-side script tag injection
- **Auth**: Country-specific GTM container IDs (`GTM-NCS3WT` for US, `GTM-WGFV57` for GB, etc.) resolved via `gtm-helper.js`
- **Purpose**: Client-side analytics and tag orchestration injected into page HTML at render time
- **Failure mode**: Client-side only — does not affect server functionality

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Metro Platform (draft merchant + PDS) | REST via `@grpn/metro-client` | Creates draft merchant records (`createDraftMerchant` / `createDraftMerchantV2`), validates fields (`validateField`), loads merchant config (`getConfig`), fetches PDS category taxonomy (`getPDS`) | `continuumMetroPlatform` (stub in DSL) |
| Groupon V2 Address Autocomplete API | REST via `itier-groupon-v2-client` | Proxies address autocomplete suggestions and place details lookups to the browser form | `continuumApiLazloService` |
| Birdcage A/B Testing | REST via `serviceClient.birdcage` | Provides A/B experiment treatment assignments for form variants | — |

### Metro Platform Detail

- **Protocol**: REST via `@grpn/metro-client` ^1.2.0
- **Base URL**: Config key `serviceClient.globalDefaults.baseUrl` — `{staging}` or `{production}` resolved by keldor-config
- **Auth**: `client_id` (`72254ab2992e4c0455d05b81f76606fd`) and `apiKey` (`a616b4c8-b077-4dcb-9c3f-3cf57ac8a7da-wl2`) from `config/base.cson`
- **Purpose**: Primary lead-creation path for all account-creation-enabled countries; also used for field validation (dedupe), PDS taxonomy, and merchant configuration
- **Failure mode**: Errors propagate to the browser as JSON error responses; logged via `itier-tracing`. No circuit breaker.
- **Circuit breaker**: No

### Groupon V2 Address API (`continuumApiLazloService`) Detail

- **Protocol**: REST via `itier-groupon-v2-client` ^4.1.7
- **Purpose**: Powers the address type-ahead in the signup form via `addressAutocomplete.results()` (geo endpoint) and `addressAutocomplete.details()` (place endpoint)
- **Failure mode**: Errors are caught, logged, and returned as `{ message }` JSON — form degrades gracefully without suggestions

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service is accessed directly by browsers (prospective merchants) at `https://www.groupon.com/merchant/signup` and its regional equivalents.

## Dependency Health

No circuit breakers or health-check retry loops are implemented. Error handling is uniform across all integrations: exceptions are caught, logged with `itier-tracing`, and returned as JSON error responses to the caller. The service is designed so that a downstream failure (Metro or Salesforce) produces a user-visible error rather than a silent failure.
