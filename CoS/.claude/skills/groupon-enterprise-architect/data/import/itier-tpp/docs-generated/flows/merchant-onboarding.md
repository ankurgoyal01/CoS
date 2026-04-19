---
service: "itier-tpp"
title: "Merchant Onboarding"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-onboarding"
flow_type: synchronous
trigger: "User submits the onboarding configuration form in the portal"
participants:
  - "merchant"
  - "continuumTppWebApp"
  - "httpRoutes"
  - "featureControllers"
  - "serviceAdapters"
  - "requestModuleRegistry"
  - "continuumPartnerService"
  - "continuumGeoDetailsService"
architecture_ref: "dynamic-itier-tpp-onboarding-flow"
---

# Merchant Onboarding

## Summary

The merchant onboarding flow covers the end-to-end process of a Groupon operations staff member or authorized merchant user creating an onboarding configuration through the TPP portal. The portal collects partner and geo context via calls to Partner Service and Geo Details Service to populate form options, then persists the submitted configuration back to Partner Service. This flow corresponds directly to the `dynamic-itier-tpp-onboarding-flow` architecture dynamic view.

## Trigger

- **Type**: user-action
- **Source**: Authenticated user submits the onboarding configuration form at `POST /onboarding_configuration` or `PUT /onboarding_configuration/{configId}`
- **Frequency**: On demand (per onboarding session)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant / Ops User | Initiates onboarding by navigating to the portal and submitting the form | `merchant` (person) |
| I-Tier TPP Web App | Receives and orchestrates the request through its components | `continuumTppWebApp` |
| HTTP Route Map | Matches the inbound route to the appropriate controller | `httpRoutes` |
| Feature Controllers | Handles the onboarding form request; calls downstream services | `featureControllers` |
| Service Adapters | Wraps Partner Service and Geo Details clients for use by the controller | `serviceAdapters` |
| Request Module Registry | Builds authenticated, request-scoped service clients | `requestModuleRegistry` |
| Partner Service (PAPI) | Stores the resulting onboarding configuration | `continuumPartnerService` |
| Geo Details Service (V2) | Provides division and location metadata for form population | `continuumGeoDetailsService` |

## Steps

1. **Authenticates request**: User's browser sends a request to the portal with a `macaroon` cookie; `itier-user-auth` middleware validates authentication via Doorman
   - From: `merchant` (browser)
   - To: `continuumTppWebApp`
   - Protocol: HTTPS

2. **Dispatches route**: `httpRoutes` matches the request path (e.g., `GET /onboarding_configuration`) and forwards to the onboarding feature controller
   - From: `httpRoutes`
   - To: `featureControllers`
   - Protocol: direct (in-process)

3. **Resolves service clients**: The onboarding controller requests authenticated service clients from `requestModuleRegistry` (Partner Service client, Geo Details client)
   - From: `featureControllers`
   - To: `requestModuleRegistry`
   - Protocol: direct (in-process)

4. **Fetches geo metadata**: `serviceAdapters` calls Geo Details Service to retrieve available divisions and location metadata for the form
   - From: `serviceAdapters`
   - To: `continuumGeoDetailsService`
   - Protocol: REST (HTTPS)

5. **Fetches existing onboarding configuration** (if editing): `serviceAdapters` calls Partner Service to load an existing configuration by `configId`
   - From: `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

6. **Renders onboarding form**: The controller composes the page with fetched data and returns server-rendered HTML to the user's browser

7. **User submits form**: User fills in the onboarding configuration and submits; browser sends `POST /onboarding_configuration` with CSRF token and `onboardingConfiguration` payload

8. **Persists configuration**: `serviceAdapters` calls Partner Service to create or update the onboarding configuration
   - From: `serviceAdapters`
   - To: `continuumPartnerService`
   - Protocol: REST (HTTPS)

9. **Returns confirmation**: The controller renders a confirmation page or redirects; response returned to the browser

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Doorman auth failure | `itier-user-auth` middleware rejects request | 401 redirect to Doorman login |
| Geo Details Service unavailable | Controller surfaces error state | Geo/division fields unavailable; form partially rendered |
| Partner Service write failure | Service adapter surfaces error to controller | Error page rendered; no partial write |
| CSRF token mismatch | `csurf` middleware rejects POST | 403 Forbidden |
| Invalid `configId` on update | Partner Service returns 404 | Error rendered in portal page |

## Sequence Diagram

```
Merchant -> continuumTppWebApp: GET /onboarding_configuration (macaroon cookie)
continuumTppWebApp -> httpRoutes: match route
httpRoutes -> featureControllers: dispatch to onboarding controller
featureControllers -> requestModuleRegistry: resolve authenticated clients
requestModuleRegistry --> featureControllers: service clients
featureControllers -> serviceAdapters: fetch geo and partner data
serviceAdapters -> continuumGeoDetailsService: GET divisions/locations
continuumGeoDetailsService --> serviceAdapters: geo metadata
serviceAdapters -> continuumPartnerService: GET onboarding config (optional)
continuumPartnerService --> serviceAdapters: config data
serviceAdapters --> featureControllers: composed page data
featureControllers --> Merchant: rendered onboarding form HTML

Merchant -> continuumTppWebApp: POST /onboarding_configuration (CSRF + payload)
httpRoutes -> featureControllers: dispatch submit handler
featureControllers -> serviceAdapters: persist onboarding configuration
serviceAdapters -> continuumPartnerService: POST/PUT onboarding config
continuumPartnerService --> serviceAdapters: success
serviceAdapters --> featureControllers: success
featureControllers --> Merchant: confirmation page or redirect
```

## Related

- Architecture dynamic view: `dynamic-itier-tpp-onboarding-flow`
- Related flows: [Partner Configuration Review](partner-config-review.md), [Portal Page Load](portal-page-load.md)
