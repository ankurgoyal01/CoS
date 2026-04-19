---
service: "itier-3pip-docs"
title: "Test Deal Setup"
generated: "2026-03-03"
type: flow
flow_name: "test-deal-setup"
flow_type: synchronous
trigger: "Partner opens the Set Up Test Deals page in the Groupon Simulator"
participants:
  - "frontendBundle"
  - "simulatorApiActions"
  - "dealDataEnricher"
  - "continuumUsersService"
  - "continuumApiLazloService"
architecture_ref: "dynamic-continuumThreePipDocsWeb"
---

# Test Deal Setup

## Summary

When a partner opens the Set Up Test Deals page, the frontend calls `GET /api/get-configure-test-deal-config`. The server authenticates the partner, loads their onboarding configuration from PAPI via GraphQL, fetches enriched deal details from `continuumApiLazloService` for all configured test deals, and returns the combined configuration — including partner vertical, acquisition method ID, deal details, and deal configuration message — to the frontend for the test deal setup UI.

## Trigger

- **Type**: user-action
- **Source**: Partner browser calls `GET /api/get-configure-test-deal-config?countryCode={code}` when loading the `/set-up-test-deals` page
- **Frequency**: On-demand (per page load or country selection change)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `frontendBundle` | Initiates the test deal config API call | `continuumThreePipDocsWeb` |
| `simulatorApiActions` | Handles `getConfigureTestDealConfig` action | `continuumThreePipDocsWeb` |
| `continuumUsersService` | Validates the partner session | `continuumUsersService` |
| `graphqlGateway` | Fetches onboarding configurations from PAPI | `continuumThreePipDocsWeb` |
| `dealDataEnricher` | Fetches enriched deal show data from Lazlo | `continuumThreePipDocsWeb` |
| `continuumApiLazloService` | Returns deal details by UUID and country code | `continuumApiLazloService` |

## Steps

1. **Requests test deal config**: `frontendBundle` SPA sends `GET /api/get-configure-test-deal-config?countryCode={code}` to the server.
   - From: `frontendBundle` (browser)
   - To: `simulatorApiActions`
   - Protocol: HTTP REST

2. **Validates session**: Calls `getUserValidation(deps)` to authenticate the partner. Returns `userId` on success, HTTP 401 on failure.
   - From: `simulatorApiActions`
   - To: `continuumUsersService`
   - Protocol: Cookie / OAuth token

3. **Loads onboarding configuration**: Fetches all onboarding configurations for `userId` from PAPI and filters to the requested `countryCode`.
   - From: `simulatorApiActions`
   - To: `graphqlGateway` → GraphQL PAPI
   - Protocol: GraphQL

4. **Fetches deal details from Lazlo**: Calls `dealDataEnricher` via `getDealsShow(apiLazlo, onboardingConfig.testDeals, onboardingConfig.countryCode)`, which queries `continuumApiLazloService` for each test deal UUID.
   - From: `dealDataEnricher`
   - To: `continuumApiLazloService`
   - Protocol: HTTPS (`@grpn/api-lazlo-client`)

5. **Receives enriched deal data**: `continuumApiLazloService` returns deal show data (`dealsShow`) for each test deal.
   - From: `continuumApiLazloService`
   - To: `dealDataEnricher`
   - Protocol: HTTPS response

6. **Assembles and returns config**: Combines partner vertical, test deals, acquisition method ID, enriched deal show data, and deal config message into a JSON response.
   - From: `simulatorApiActions`
   - To: `frontendBundle` (browser)
   - Protocol: HTTP 200 JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | `getUserValidation` throws | HTTP 401 returned |
| No onboarding configuration | Empty or error response from PAPI | Error propagated to frontend |
| Lazlo unavailable or returns errors | `dealsShowResponse.errors` checked; `dealsShow` set to `null` | Config returned without enriched deal details |
| Exception in Lazlo call | Caught and returned as error | Action returns the raw error object |

## Sequence Diagram

```
frontendBundle -> simulatorApiActions: GET /api/get-configure-test-deal-config?countryCode=US
simulatorApiActions -> continuumUsersService: getPersonalizedUser()
continuumUsersService --> simulatorApiActions: { id: userId }
simulatorApiActions -> graphqlGateway: fetchOnboardingConfigurations({ userId })
graphqlGateway -> PAPI: PAPI_onboardingConfigurations query
PAPI --> simulatorApiActions: onboarding config with testDeals[]
simulatorApiActions -> dealDataEnricher: getDealsShow(apiLazlo, testDeals, countryCode)
dealDataEnricher -> continuumApiLazloService: load deal by UUID/country
continuumApiLazloService --> dealDataEnricher: dealsShow data
dealDataEnricher --> simulatorApiActions: enriched deal details
simulatorApiActions --> frontendBundle: HTTP 200 JSON { partnerVertical, testDeals, dealsShow, ... }
```

## Related

- Architecture dynamic view: `dynamic-continuumThreePipDocsWeb`
- Related flows: [Partner Authentication](partner-authentication.md), [Availability Sync Trigger](availability-sync-trigger.md), [Partner Onboarding Configuration Load](partner-onboarding-config-load.md)
