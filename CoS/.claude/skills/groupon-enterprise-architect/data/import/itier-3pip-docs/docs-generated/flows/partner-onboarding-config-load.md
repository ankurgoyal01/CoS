---
service: "itier-3pip-docs"
title: "Partner Onboarding Configuration Load"
generated: "2026-03-03"
type: flow
flow_name: "partner-onboarding-config-load"
flow_type: synchronous
trigger: "Partner accesses the Groupon Simulator integration setup page"
participants:
  - "frontendBundle"
  - "simulatorApiActions"
  - "graphqlGateway"
  - "continuumUsersService"
architecture_ref: "dynamic-continuumThreePipDocsWeb"
---

# Partner Onboarding Configuration Load

## Summary

When a partner opens the Groupon Simulator integration setup page, the frontend SPA calls `GET /api/get-partner-config`. The server validates the partner session, fetches the partner's onboarding configurations from the Partner API (PAPI) via GraphQL, filters by the requested country code, and returns the full partner setup configuration — including acquisition method IDs, test deals, preproduction status, and partner vertical — to the frontend for rendering.

## Trigger

- **Type**: user-action
- **Source**: Partner browser loads the integration setup page (`/integration`) and the `frontendBundle` SPA calls `GET /api/get-partner-config?countryCode={code}`
- **Frequency**: On-demand (per page load or country selection change)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `frontendBundle` | Initiates the config fetch API call from the browser SPA | `continuumThreePipDocsWeb` |
| `simulatorApiActions` | Handles `getPartnerConfig` action; orchestrates auth + GraphQL fetch | `continuumThreePipDocsWeb` |
| `continuumUsersService` | Validates the partner session and returns `userId` | `continuumUsersService` |
| `graphqlGateway` | Executes `PAPI_onboardingConfigurations` query | `continuumThreePipDocsWeb` |
| GraphQL PAPI | Returns onboarding configuration records for the user | External (PAPI backend) |

## Steps

1. **Requests partner config**: `frontendBundle` SPA sends `GET /api/get-partner-config?countryCode={code}` to the server.
   - From: `frontendBundle` (browser)
   - To: `simulatorApiActions`
   - Protocol: HTTP REST

2. **Validates session**: Calls `getUserValidation(deps)` to authenticate the partner via `continuumUsersService`. Returns `userId` on success, HTTP 401 on failure.
   - From: `simulatorApiActions`
   - To: `continuumUsersService`
   - Protocol: Cookie / OAuth token

3. **Queries PAPI for onboarding configurations**: Calls `graphqlGateway` with the `fetchOnboardingConfigurations` query, passing `userId`.
   - From: `simulatorApiActions`
   - To: `graphqlGateway`
   - Protocol: In-process function call

4. **Executes GraphQL query**: `graphqlGateway` sends the `PAPI_onboardingConfigurations` GraphQL query to the Partner API backend.
   - From: `graphqlGateway`
   - To: GraphQL PAPI
   - Protocol: GraphQL

5. **Receives and parses configurations**: PAPI returns a raw JSON response body. The service parses `rawResponseBody` to extract the `onboardingConfigurations` array.
   - From: GraphQL PAPI
   - To: `simulatorApiActions`
   - Protocol: GraphQL response

6. **Filters by country code**: Finds the onboarding configuration matching the requested `countryCode`.
   - From: `simulatorApiActions` (in-process)

7. **Builds and returns partner setup config**: Calls `getPartnerSetupConfig()` with the matched configuration, enriches it with deal API data as needed, and returns the JSON result to the frontend.
   - From: `simulatorApiActions`
   - To: `frontendBundle` (browser)
   - Protocol: HTTP 200 JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | `getUserValidation` throws | HTTP 401 returned to frontend |
| PAPI returns GraphQL errors | `res.errors` checked; error logged via `traceError` | HTTP response with `{ statusCode, message }` |
| No onboarding configuration found for user | Returns `{ statusCode: 400, message: I18n.t('modules.main.user_not_mapped_msg') }` | Frontend displays "not mapped" error |
| Country code not found in configs | `onboardingConfig` is undefined | Downstream call fails; HTTP 500 returned |

## Sequence Diagram

```
frontendBundle -> simulatorApiActions: GET /api/get-partner-config?countryCode=US
simulatorApiActions -> continuumUsersService: getPersonalizedUser()
continuumUsersService --> simulatorApiActions: { id: userId }
simulatorApiActions -> graphqlGateway: fetchOnboardingConfigurations({ userId })
graphqlGateway -> PAPI: PAPI_onboardingConfigurations query
PAPI --> graphqlGateway: { rawResponseBody: [...configs] }
graphqlGateway --> simulatorApiActions: parsed onboarding configurations
simulatorApiActions --> frontendBundle: HTTP 200 JSON { partnerSetupConfig }
```

## Related

- Architecture dynamic view: `dynamic-continuumThreePipDocsWeb`
- Related flows: [Partner Authentication](partner-authentication.md), [Test Deal Setup](test-deal-setup.md), [Availability Sync Trigger](availability-sync-trigger.md)
