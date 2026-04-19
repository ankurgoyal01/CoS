---
service: "sub_center"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 1
internal_count: 8
---

# Integrations

## Overview

sub_center has nine downstream dependencies: eight internal Continuum/Groupon services and one external third-party service (Twilio). All relationships are currently modeled as stubs in the federated architecture — the target containers are not yet represented in the federated model. Integration is implemented through `itier-*` clients encapsulated in the External API Clients component, with Twilio accessed via its SDK through the SMS Helper component.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Twilio SMS | HTTP/SDK | Sends SMS messages for weekly digest unsubscribe flows | no | `twilioSms_ext_3a95` |

### Twilio SMS Detail

- **Protocol**: Twilio SDK (HTTP under the hood)
- **Base URL / SDK**: Twilio Node.js SDK — evidence from `smsHelper` component in `architecture/models/components/subCenterWebApp.dsl`
- **Auth**: Twilio Account SID and Auth Token (secrets)
- **Purpose**: Delivers SMS notifications for the weekly digest SMS unsubscribe flow
- **Failure mode**: SMS delivery failure; page renders but confirmation may not be sent
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Groupon V2 API | HTTP/REST | Reads and updates subscription preferences | `grouponV2Api_ext_7c1d` |
| GSS Service | HTTP/REST | Looks up subscription metadata and user mappings | `gssService_ext_5b3e` |
| Subscriptions Service | HTTP/REST | Fetches subscription data | `subscriptionsService_ext_9a41` |
| GeoDetails Service | HTTP/REST | Resolves location and division data | `geoDetailsService_ext_4d22` |
| Remote Layout Service | HTTP/REST | Loads page layout templates | `remoteLayoutService_ext_1f8c` |
| Feature Flags Service | HTTP/REST | Evaluates feature flags for subscription UX | `featureFlagsService_ext_8e0b` |
| Optimize Service | HTTP/REST | Sends tracking and analytics events | `optimizeService_ext_6c7f` |
| Memcached | Memcached protocol | Caches division and channel metadata | `memcached_ext_0c5e` |

> All internal dependency architecture refs are stub-only: targets are not in the federated model. Upstream consumers are tracked in the central architecture model.

## Consumed By

> Upstream consumers are tracked in the central architecture model. sub_center is consumed directly by end users (browsers) arriving via email unsubscribe links or direct navigation.

## Dependency Health

> No evidence found in codebase for circuit breaker or retry configurations. Health check and retry patterns for I-Tier dependencies are typically managed at the `itier-*` client library level. Operational procedures to be defined by service owner.
