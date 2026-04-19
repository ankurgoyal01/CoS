---
service: "sub_center"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumSubCenterWebApp]
---

# Architecture Context

## System Context

sub_center is a container within the `continuumSystem` (Continuum Platform) software system. It is a user-facing I-Tier web application that sits between end users and a set of Continuum backend services. Users reach it through browser requests — typically arriving via email unsubscribe links or direct navigation to the subscription center. The service calls nine downstream systems to read subscription state, resolve geographic data, load layout templates, evaluate feature flags, send tracking events, deliver SMS, and cache metadata. All downstream relationships are currently modeled as stubs in the federated architecture.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Subscription Center Web App | `continuumSubCenterWebApp` | Web Application | Node.js (itier-server) | — | Renders subscription center pages and handles unsubscribe flows |

## Components by Container

### Subscription Center Web App (`continuumSubCenterWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Router | Defines routes and binds controllers | Express / Keldor |
| Controller Layer | Keldor controllers for subscription flows | Keldor |
| Subscription Handlers | Business logic for subscription updates and unsubscribe flows | CoffeeScript |
| Subscription Data Getter | Fetches subscription data for users | CoffeeScript |
| Subscription Presenters | Builds view model data for templates | CoffeeScript |
| Page Renderer | Renders templates and remote layouts | itier-render |
| Cache Access | Caches divisions and channel metadata | Memcached client |
| SMS Helper | Sends SMS messages for weekly digest flows | Twilio SDK |
| External API Clients | Integrations for GSS, Groupon V2, Subscriptions, GeoDetails, Feature Flags, Remote Layout, and Optimize | itier-* clients |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `httpRouter` | `subCenter_controllerLayer` | Routes requests to controller actions | Internal |
| `subCenter_controllerLayer` | `subscriptionHandlers` | Invokes handler logic | Internal |
| `subscriptionHandlers` | `subscriptionDataGetter` | Loads subscription data | Internal |
| `subscriptionHandlers` | `presenters` | Builds view models | Internal |
| `subscriptionHandlers` | `pageRenderer` | Renders HTML responses | Internal |
| `subscriptionHandlers` | `subCenter_externalApiClients` | Calls external services | Internal |
| `subscriptionHandlers` | `subCenter_cacheAccess` | Reads cached divisions and channels | Internal |
| `subscriptionHandlers` | `smsHelper` | Sends SMS notifications | Internal |
| `subscriptionDataGetter` | `subCenter_externalApiClients` | Queries subscription services | Internal |
| `continuumSubCenterWebApp` | `grouponV2Api_ext_7c1d` | Reads and updates subscriptions | HTTP (stub only) |
| `continuumSubCenterWebApp` | `gssService_ext_5b3e` | Looks up subscription metadata and user mappings | HTTP (stub only) |
| `continuumSubCenterWebApp` | `subscriptionsService_ext_9a41` | Fetches subscription data | HTTP (stub only) |
| `continuumSubCenterWebApp` | `geoDetailsService_ext_4d22` | Resolves location and division data | HTTP (stub only) |
| `continuumSubCenterWebApp` | `remoteLayoutService_ext_1f8c` | Loads layout templates | HTTP (stub only) |
| `continuumSubCenterWebApp` | `featureFlagsService_ext_8e0b` | Evaluates feature flags | HTTP (stub only) |
| `continuumSubCenterWebApp` | `optimizeService_ext_6c7f` | Sends tracking events | HTTP (stub only) |
| `continuumSubCenterWebApp` | `twilioSms_ext_3a95` | Sends SMS messages | HTTP/SDK (stub only) |
| `continuumSubCenterWebApp` | `memcached_ext_0c5e` | Caches divisions and channel metadata | Memcached (stub only) |

> All external container relationships are stub-only: targets are not yet in the federated model.

## Architecture Diagram References

- System context: `contexts-continuumSubCenter`
- Container: `containers-continuumSubCenter`
- Component: `components-subCenterWebApp` (view defined in `views/components/subCenterWebApp.dsl`)
