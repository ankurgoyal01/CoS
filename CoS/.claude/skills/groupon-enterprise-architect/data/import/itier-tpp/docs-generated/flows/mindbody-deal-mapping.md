---
service: "itier-tpp"
title: "Mindbody Deal Mapping"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "mindbody-deal-mapping"
flow_type: synchronous
trigger: "Operations staff maps or updates a Groupon deal to a Mindbody service via the TTD UI"
participants:
  - "merchant"
  - "continuumTppWebApp"
  - "httpRoutes"
  - "featureControllers"
  - "serviceAdapters"
  - "requestModuleRegistry"
  - "continuumPartnerService"
  - "continuumApiLazloService"
  - "mindbodyApi"
architecture_ref: "dynamic-itier-tpp-onboarding-flow"
---

# Mindbody Deal Mapping

## Summary

The Mindbody deal mapping flow allows Groupon operations staff to associate a Groupon deal with a Mindbody service offering via the TTD (The Ticket Doctor) section of the portal. The portal fetches deal data from API Lazlo, loads existing mappings from Partner Service, and pushes updated mappings to both Partner Service and the Mindbody API. Mindbody credentials (`MINDBODY_USERNAME`, `MINDBODY_PASSWORD`) are injected from a Kubernetes secret at startup.

## Trigger

- **Type**: user-action
- **Source**: Operations staff navigates to `/ttd/{partnerAcmid}` and submits a deal update via `PUT /ttd/api/partner/{partnerName}/merchant/{merchantId}/deals/{dealId}` with an `actionType` query parameter
- **Frequency**: On demand (per deal mapping or deal activation/deactivation session)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operations Staff | Initiates the deal mapping or deal status action through the TTD UI | `merchant` (person) |
| I-Tier TPP Web App | Hosts the TTD UI and orchestrates cross-service calls | `continuumTppWebApp` |
| HTTP Route Map | Routes `/ttd` requests to the TTD feature controller | `httpRoutes` |
| Feature Controllers | Implements TTD controller logic | `featureControllers` |
| Service Adapters | Wraps Partner Service, API Lazlo, and Mindbody API clients | `serviceAdapters` |
| Request Module Registry | Builds authenticated, request-scoped service clients | `requestModuleRegistry` |
| Partner Service (PAPI) | Stores partner/merchant configurations and records mapping state | `continuumPartnerService` |
| API Lazlo (Groupon V2) | Provides Groupon deal data for the mapping UI | `continuumApiLazloService` |
| Mindbody API | Receives and applies deal/service mapping updates | `mindbodyApi` |

## Steps

1. **Authenticates user**: Staff navigates to `/ttd/{partnerAcmid}` with a valid `macaroon` cookie
   - From: Operations staff (browser)
   - To: `continuumTppWebApp`
   - Protocol: HTTPS

2. **Dispatches route**: `httpRoutes` matches the `/ttd` path and forwards to the TTD feature controller
   - From: `httpRoutes`
   - To: `featureControllers`
   - Protocol: direct (in-process)

3. **Resolves service clients**: Controller requests authenticated clients for Partner Service, API Lazlo, and Mindbody API from `requestModuleRegistry`
   - From: `featureControllers`
   - To: `requestModuleRegistry`
   - Protocol: direct (in-process)

4. **Fetches Groupon deal data**: `serviceAdapters` calls API Lazlo / Groupon V2 to retrieve deal details; also fetches deal mapping schema via `GET /ttd/api/partner/{partnerId}/mapping/deal/{dealId}`
   - From: `serviceAdapters`
   - To: `continuumApiLazloService`
   - Protocol: REST (HTTPS)

5. **Fetches merchant and partner data**: `serviceAdapters` calls Partner Service to load merchant and partner configuration context
   - From: `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

6. **Renders TTD mapping UI**: Controller composes and returns the deal mapping or deal configuration page

7. **Staff submits deal update**: User applies the mapping or updates deal status; browser sends `PUT /ttd/api/partner/{partnerName}/merchant/{merchantId}/deals/{dealId}?actionType=<action>`

8. **Writes to Partner Service**: `serviceAdapters` persists the updated deal/mapping state to Partner Service
   - From: `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

9. **Writes to Mindbody API**: `serviceAdapters` calls `@grpn/mindbody-client` with `MINDBODY_USERNAME`/`MINDBODY_PASSWORD` credentials to push the deal update to Mindbody
   - From: `serviceAdapters`
   - To: `mindbodyApi`
   - Protocol: REST (HTTPS)

10. **Returns confirmation**: Controller renders confirmation response or redirects

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| API Lazlo unavailable | Service adapter surfaces error | Deal data unavailable; mapping UI cannot render |
| Partner Service write failure | Service adapter surfaces error | Mapping not persisted; error shown to user |
| Mindbody API authentication failure | `MINDBODY_USERNAME`/`MINDBODY_PASSWORD` invalid or expired | Mindbody not updated; error surfaced to user |
| Mindbody API write failure | Service adapter surfaces error | Mindbody not updated; Partner Service may have been written (partial update risk) |
| Missing or invalid `actionType` | Controller rejects the request | 400 error returned to UI |
| CSRF token invalid | `csurf` middleware rejects request | 403 Forbidden |

## Sequence Diagram

```
OpsStaff -> continuumTppWebApp: GET /ttd/{partnerAcmid} (macaroon cookie)
httpRoutes -> featureControllers: dispatch to TTD controller
featureControllers -> requestModuleRegistry: resolve service clients
serviceAdapters -> continuumApiLazloService: GET deal data and mapping schema
continuumApiLazloService --> serviceAdapters: deal data
serviceAdapters -> continuumPartnerService: GET merchant/partner config
continuumPartnerService --> serviceAdapters: config data
featureControllers --> OpsStaff: rendered TTD mapping UI HTML

OpsStaff -> continuumTppWebApp: PUT /ttd/api/partner/{partnerName}/merchant/{merchantId}/deals/{dealId}?actionType=activate
httpRoutes -> featureControllers: dispatch deal update handler
featureControllers -> serviceAdapters: persist deal state
serviceAdapters -> continuumPartnerService: PUT deal state
continuumPartnerService --> serviceAdapters: success
serviceAdapters -> mindbodyApi: PUT deal/service mapping (MINDBODY_USERNAME + MINDBODY_PASSWORD)
mindbodyApi --> serviceAdapters: success
featureControllers --> OpsStaff: confirmation or redirect
```

## Related

- Architecture dynamic view: `dynamic-itier-tpp-onboarding-flow`
- Related flows: [Booker Deal Mapping](booker-deal-mapping.md), [Merchant Onboarding](merchant-onboarding.md)
