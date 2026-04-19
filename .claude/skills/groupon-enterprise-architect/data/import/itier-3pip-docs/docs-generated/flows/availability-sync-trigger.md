---
service: "itier-3pip-docs"
title: "Availability Sync Trigger"
generated: "2026-03-03"
type: flow
flow_name: "availability-sync-trigger"
flow_type: synchronous
trigger: "Partner clicks Trigger Availability in the Groupon Simulator test deals UI"
participants:
  - "frontendBundle"
  - "simulatorApiActions"
  - "graphqlGateway"
  - "dealDataEnricher"
  - "continuumUsersService"
  - "continuumApiLazloService"
architecture_ref: "dynamic-continuumThreePipDocsWeb"
---

# Availability Sync Trigger

## Summary

When a partner triggers an availability sync from the test deals UI, the frontend calls `PUT /api/onboarding-configurations/{configurationId}/trigger-availability`. The server authenticates the session, loads the onboarding configuration for the partner and country, identifies the target inventory product from the test deal list, and sends a `triggerAvailability` GraphQL mutation to PAPI. This flow validates that the partner's integration can correctly respond to Groupon's availability check requests.

## Trigger

- **Type**: user-action
- **Source**: Partner clicks "Trigger Availability" button in the Set Up Test Deals page; browser sends `PUT /api/onboarding-configurations/{configurationId}/trigger-availability?countryCode={code}&dealUuid={uuid}`
- **Frequency**: On-demand (per partner trigger action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `frontendBundle` | Initiates the trigger availability API call | `continuumThreePipDocsWeb` |
| `simulatorApiActions` | Handles `triggerSyncAvailability` action | `continuumThreePipDocsWeb` |
| `continuumUsersService` | Validates the partner session | `continuumUsersService` |
| `graphqlGateway` | Executes onboarding config query and triggerAvailability mutation | `continuumThreePipDocsWeb` |
| `dealDataEnricher` | Implicitly used — onboarding config contains test deals with inventory product IDs | `continuumThreePipDocsWeb` |
| `continuumApiLazloService` | Provides deal details via onboarding config (loaded in prior step) | `continuumApiLazloService` |
| GraphQL PAPI | Receives and processes the triggerAvailability mutation | External (PAPI backend) |

## Steps

1. **Requests availability trigger**: `frontendBundle` sends `PUT /api/onboarding-configurations/{configurationId}/trigger-availability` with `countryCode` and optional `dealUuid` query parameters.
   - From: `frontendBundle` (browser)
   - To: `simulatorApiActions`
   - Protocol: HTTP REST (PUT)

2. **Validates session**: Calls `getUserValidation(deps)`. Returns `userId` on success, HTTP 401 on failure.
   - From: `simulatorApiActions`
   - To: `continuumUsersService`
   - Protocol: Cookie / OAuth token

3. **Loads onboarding configuration**: Fetches all onboarding configurations for `userId` from PAPI, filters by `countryCode`, and extracts `testDeals`.
   - From: `simulatorApiActions`
   - To: `graphqlGateway` → GraphQL PAPI
   - Protocol: GraphQL

4. **Identifies target test deal**: If `dealUuid` is provided, finds the matching deal from `testDeals`; otherwise uses the first test deal.
   - From: `simulatorApiActions` (in-process)

5. **Extracts inventory product ID**: Reads `deal.product[0].inventoryProductId` from the selected test deal.
   - From: `simulatorApiActions` (in-process)

6. **Sends triggerAvailability mutation**: Calls `graphqlGateway` with the `triggerAvailability` mutation, passing `configurationId` and `{ inventoryProductId }` as the body.
   - From: `simulatorApiActions`
   - To: `graphqlGateway`
   - Protocol: In-process

7. **Executes mutation against PAPI**: `graphqlGateway` sends the `PAPI_triggerAvailability` GraphQL mutation.
   - From: `graphqlGateway`
   - To: GraphQL PAPI
   - Protocol: GraphQL

8. **Returns trigger result**: PAPI processes the availability trigger and returns the raw response. The server extracts `rawResponseBody` and returns `{ rawResponse }` to the frontend.
   - From: `simulatorApiActions`
   - To: `frontendBundle` (browser)
   - Protocol: HTTP 200 JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | `getUserValidation` throws | HTTP 401 returned |
| Failed to load onboarding config | Caught exception | HTTP 500 with message "Failed to load onboarding configuration when triggering availability" |
| Test deal not found for given `dealUuid` | `find()` returns `undefined`; `deal.product[0]` access throws | HTTP 500 returned |
| PAPI mutation returns errors | `res.errors` checked | HTTP 500 with message "Failed to trigger availability. {error}" |
| PAPI mutation throws | Caught exception | HTTP 500 returned |

## Sequence Diagram

```
frontendBundle -> simulatorApiActions: PUT /api/onboarding-configurations/{configId}/trigger-availability?countryCode=US&dealUuid={uuid}
simulatorApiActions -> continuumUsersService: getPersonalizedUser()
continuumUsersService --> simulatorApiActions: { id: userId }
simulatorApiActions -> graphqlGateway: fetchOnboardingConfigurations({ userId })
graphqlGateway -> PAPI: PAPI_onboardingConfigurations query
PAPI --> simulatorApiActions: onboarding config with testDeals[{ product[{ inventoryProductId }] }]
simulatorApiActions -> graphqlGateway: triggerAvailability({ configurationId, body: { inventoryProductId } })
graphqlGateway -> PAPI: PAPI_triggerAvailability mutation
PAPI --> graphqlGateway: { rawResponseBody }
graphqlGateway --> simulatorApiActions: mutation result
simulatorApiActions --> frontendBundle: HTTP 200 JSON { rawResponse }
```

## Related

- Architecture dynamic view: `dynamic-continuumThreePipDocsWeb`
- Related flows: [Test Deal Setup](test-deal-setup.md), [Partner Authentication](partner-authentication.md), [Partner Onboarding Configuration Load](partner-onboarding-config-load.md)
