---
service: "itier-tpp"
title: "Booker Deal Mapping"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "booker-deal-mapping"
flow_type: synchronous
trigger: "Operations staff maps or updates a Groupon deal to a Booker class via the partner booking UI"
participants:
  - "merchant"
  - "continuumTppWebApp"
  - "httpRoutes"
  - "featureControllers"
  - "serviceAdapters"
  - "requestModuleRegistry"
  - "continuumPartnerService"
  - "continuumApiLazloService"
  - "bookerApi"
architecture_ref: "dynamic-itier-tpp-onboarding-flow"
---

# Booker Deal Mapping

## Summary

The Booker deal mapping flow allows Groupon operations staff to associate a Groupon deal with a corresponding Booker class or service. The portal loads deal data from the Groupon V2 API (via API Lazlo), loads existing mappings from Partner Service, and writes updated mappings to both Partner Service and the Booker API. This is a cross-service write flow spanning three downstream systems.

## Trigger

- **Type**: user-action
- **Source**: Operations staff navigates to `/partnerbooking` and submits a deal mapping update via `PUT /partnerbooking/api/partner/{partnerId}/mappings` or activates/deactivates a deal via `PUT /partnerbooking/api/partner/{partnerName}/merchant/{merchantId}/deals/{dealId}`
- **Frequency**: On demand (per deal mapping or deal status change session)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operations Staff | Initiates deal mapping or deal status action through the Booker UI | `merchant` (person) |
| I-Tier TPP Web App | Hosts the partner booking UI and orchestrates cross-service calls | `continuumTppWebApp` |
| HTTP Route Map | Routes `/partnerbooking` requests to the Booker feature controller | `httpRoutes` |
| Feature Controllers | Implements partner booking controller logic | `featureControllers` |
| Service Adapters | Wraps Partner Service, API Lazlo, and Booker API clients | `serviceAdapters` |
| Request Module Registry | Builds authenticated, request-scoped service clients | `requestModuleRegistry` |
| Partner Service (PAPI) | Stores partner and merchant configurations; records mapping results | `continuumPartnerService` |
| API Lazlo (Groupon V2) | Provides Groupon deal data for the mapping UI | `continuumApiLazloService` |
| Booker API | Receives and applies deal/class mapping updates | `bookerApi` |

## Steps

1. **Authenticates user**: Staff navigates to `/partnerbooking` with a valid `macaroon` cookie
   - From: Operations staff (browser)
   - To: `continuumTppWebApp`
   - Protocol: HTTPS

2. **Dispatches route**: `httpRoutes` matches the `/partnerbooking` path and forwards to the partner booking feature controller
   - From: `httpRoutes`
   - To: `featureControllers`
   - Protocol: direct (in-process)

3. **Resolves clients**: Controller requests authenticated clients for Partner Service, API Lazlo, and Booker API from `requestModuleRegistry`
   - From: `featureControllers`
   - To: `requestModuleRegistry`
   - Protocol: direct (in-process)

4. **Fetches Groupon deal data**: `serviceAdapters` calls API Lazlo / Groupon V2 API to retrieve deal details for display in the mapping UI
   - From: `serviceAdapters`
   - To: `continuumApiLazloService`
   - Protocol: REST (HTTPS)

5. **Fetches existing mapping**: `serviceAdapters` calls `GET /partnerbooking/api/partner/{partnerId}/mapping/deal/{dealId}` logic against Partner Service to load the current deal-to-Booker mapping
   - From: `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

6. **Renders mapping form**: Controller composes and returns the deal mapping UI with current mapping data and available Booker classes

7. **Staff submits mapping**: User updates the mapping and submits; browser sends `PUT /partnerbooking/api/partner/{partnerId}/mappings` with CSRF token and `mappings` payload

8. **Writes mapping to Partner Service**: `serviceAdapters` persists the mapping in Partner Service
   - From: `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

9. **Writes mapping to Booker API**: `serviceAdapters` calls `@grpn/booker-client` to push the mapping to the Booker platform
   - From: `serviceAdapters`
   - To: `bookerApi`
   - Protocol: REST (HTTPS)

10. **Returns confirmation**: Controller renders confirmation or redirect after successful write to both systems

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| API Lazlo unavailable | Service adapter surfaces error | Deal data unavailable; mapping form cannot render |
| Partner Service write failure | Service adapter surfaces error | Mapping not persisted; error shown to user |
| Booker API write failure | Service adapter surfaces error | Booker not updated; error shown; Partner Service write may have succeeded (partial update risk) |
| CSRF token invalid | `csurf` middleware rejects request | 403 Forbidden; no writes performed |
| Invalid `actionType` query param | Controller rejects request | Error returned to UI |

## Sequence Diagram

```
OpsStaff -> continuumTppWebApp: GET /partnerbooking (macaroon cookie)
httpRoutes -> featureControllers: dispatch to partner booking controller
featureControllers -> requestModuleRegistry: resolve service clients
serviceAdapters -> continuumApiLazloService: GET deal details
continuumApiLazloService --> serviceAdapters: deal data
serviceAdapters -> continuumPartnerService: GET partner/mapping data
continuumPartnerService --> serviceAdapters: mapping data
featureControllers --> OpsStaff: rendered deal mapping form HTML

OpsStaff -> continuumTppWebApp: PUT /partnerbooking/api/partner/{partnerId}/mappings (CSRF + mappings)
httpRoutes -> featureControllers: dispatch mapping update handler
featureControllers -> serviceAdapters: persist mappings
serviceAdapters -> continuumPartnerService: PUT partner mappings
continuumPartnerService --> serviceAdapters: success
serviceAdapters -> bookerApi: PUT class/deal mapping
bookerApi --> serviceAdapters: success
featureControllers --> OpsStaff: confirmation or redirect
```

## Related

- Architecture dynamic view: `dynamic-itier-tpp-onboarding-flow`
- Related flows: [Mindbody Deal Mapping](mindbody-deal-mapping.md), [Merchant Onboarding](merchant-onboarding.md)
