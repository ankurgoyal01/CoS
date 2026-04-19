---
service: "sub_center"
title: "Subscription Preferences"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "subscription-preferences"
flow_type: synchronous
trigger: "User navigates to the subscription center page"
participants:
  - "continuumSubCenterWebApp"
  - "subscriptionsService_ext_9a41"
  - "grouponV2Api_ext_7c1d"
  - "geoDetailsService_ext_4d22"
  - "remoteLayoutService_ext_1f8c"
  - "featureFlagsService_ext_8e0b"
  - "optimizeService_ext_6c7f"
  - "memcached_ext_0c5e"
architecture_ref: "dynamic-subCenter-subscriptionPreferences"
---

# Subscription Preferences

## Summary

The subscription preferences flow handles the full page load for the subscription center. When a user navigates to their subscription preferences page, the service fetches their current subscription state, resolves their geographic division, evaluates relevant feature flags, loads the page layout, builds the view model, and renders a server-side HTML page. Submission of preference changes triggers a write back to the appropriate subscription service.

## Trigger

- **Type**: user-action
- **Source**: User navigating to the subscription center (GET), or submitting preference changes (POST)
- **Frequency**: On-demand, per page load or form submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Subscription Center Web App | Orchestrates data fetching, feature flag evaluation, and page rendering | `continuumSubCenterWebApp` |
| Subscriptions Service | Provides current subscription state | `subscriptionsService_ext_9a41` |
| Groupon V2 API | Reads and writes subscription channel preferences | `grouponV2Api_ext_7c1d` |
| GeoDetails Service | Resolves user location and division data | `geoDetailsService_ext_4d22` |
| Remote Layout Service | Provides page layout template and navigation chrome | `remoteLayoutService_ext_1f8c` |
| Feature Flags Service | Evaluates flags gating subscription UX features | `featureFlagsService_ext_8e0b` |
| Optimize Service | Receives page-view and interaction tracking events | `optimizeService_ext_6c7f` |
| Memcached | Caches division and channel metadata | `memcached_ext_0c5e` |

## Steps

### Page Load (GET)

1. **Receives page request**: Browser sends GET request to the subscription center route.
   - From: End User (browser)
   - To: `httpRouter` in `continuumSubCenterWebApp`
   - Protocol: HTTP GET

2. **Routes to controller**: HTTP Router dispatches to the Controller Layer's subscription center action.
   - From: `httpRouter`
   - To: `subCenter_controllerLayer`
   - Protocol: Internal

3. **Invokes subscription handler**: Controller invokes Subscription Handlers to orchestrate the page data assembly.
   - From: `subCenter_controllerLayer`
   - To: `subscriptionHandlers`
   - Protocol: Internal

4. **Checks metadata cache**: Cache Access reads division and channel metadata from Memcached.
   - From: `subscriptionHandlers` via `subCenter_cacheAccess`
   - To: `memcached_ext_0c5e`
   - Protocol: Memcached

5. **Resolves geographic division**: On cache miss or missing division data, External API Clients call GeoDetails Service.
   - From: `subCenter_externalApiClients`
   - To: `geoDetailsService_ext_4d22`
   - Protocol: HTTP/REST (stub only)

6. **Fetches subscription state**: Subscription Data Getter queries Subscriptions Service for the user's current channel opt-ins.
   - From: `subscriptionDataGetter` via `subCenter_externalApiClients`
   - To: `subscriptionsService_ext_9a41`
   - Protocol: HTTP/REST (stub only)

7. **Evaluates feature flags**: External API Clients call the Feature Flags Service for any flags gating subscription page features.
   - From: `subCenter_externalApiClients`
   - To: `featureFlagsService_ext_8e0b`
   - Protocol: HTTP/REST (stub only)

8. **Loads remote layout**: External API Clients fetch the page layout template from the Remote Layout Service.
   - From: `subCenter_externalApiClients`
   - To: `remoteLayoutService_ext_1f8c`
   - Protocol: HTTP/REST (stub only)

9. **Builds view model**: Subscription Presenters assemble the view model from subscription state, divisions, and feature flag results.
   - From: `subscriptionHandlers`
   - To: `presenters`
   - Protocol: Internal

10. **Renders page**: Page Renderer applies the view model to templates, integrates the remote layout, and produces the HTML page.
    - From: `subscriptionHandlers`
    - To: `pageRenderer` → end user browser
    - Protocol: HTTP response (HTML)

11. **Sends tracking event**: Subscription Handlers dispatch a page-view tracking event to the Optimize Service.
    - From: `subCenter_externalApiClients`
    - To: `optimizeService_ext_6c7f`
    - Protocol: HTTP/REST (stub only)

### Preference Update (POST)

1. **Receives preference form submission**: Browser sends POST with updated channel preferences.
2. **Routes and invokes handler**: Same routing path as page load.
3. **Writes preferences to Groupon V2 API**: External API Clients POST updated channel preferences.
   - From: `subCenter_externalApiClients`
   - To: `grouponV2Api_ext_7c1d`
   - Protocol: HTTP/REST (stub only)
4. **Renders confirmation**: Page Renderer returns an updated preference confirmation page.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Subscriptions Service unavailable | HTTP error from External API Clients | Render error page |
| GeoDetails Service unavailable | Skip division resolution; use default or cached value | Page loads with degraded division data |
| Remote Layout Service unavailable | Render page without layout chrome | Functional but visually degraded page |
| Feature Flags Service unavailable | Treat all flags as off (default state) | Page loads with features in default state |
| Optimize Service unavailable | Log error; skip tracking | No impact on user-facing flow |
| Memcached unavailable | Fetch data directly from upstream services | Degraded performance; flow completes |

## Sequence Diagram

```
User Browser -> continuumSubCenterWebApp (httpRouter): GET /subscription-center
httpRouter -> subCenter_controllerLayer: route to subscription center action
subCenter_controllerLayer -> subscriptionHandlers: orchestrate page data
subscriptionHandlers -> subCenter_cacheAccess: read channel/division metadata
subCenter_cacheAccess -> memcached_ext_0c5e: GET metadata
memcached_ext_0c5e --> subCenter_cacheAccess: cached data (or miss)
subscriptionHandlers -> subCenter_externalApiClients: fetch geo data
subCenter_externalApiClients -> geoDetailsService_ext_4d22: GET /division?user=...
geoDetailsService_ext_4d22 --> subCenter_externalApiClients: division data
subscriptionHandlers -> subscriptionDataGetter: fetch subscription state
subscriptionDataGetter -> subCenter_externalApiClients: GET subscription state
subCenter_externalApiClients -> subscriptionsService_ext_9a41: GET /subscriptions/user
subscriptionsService_ext_9a41 --> subCenter_externalApiClients: subscription data
subscriptionHandlers -> subCenter_externalApiClients: evaluate feature flags
subCenter_externalApiClients -> featureFlagsService_ext_8e0b: GET /flags
featureFlagsService_ext_8e0b --> subCenter_externalApiClients: flag evaluations
subscriptionHandlers -> subCenter_externalApiClients: load remote layout
subCenter_externalApiClients -> remoteLayoutService_ext_1f8c: GET /layout
remoteLayoutService_ext_1f8c --> subCenter_externalApiClients: layout HTML
subscriptionHandlers -> presenters: build view model
subscriptionHandlers -> pageRenderer: render full page
pageRenderer --> User Browser: 200 OK (subscription center HTML)
subscriptionHandlers -> subCenter_externalApiClients: send page-view event
subCenter_externalApiClients -> optimizeService_ext_6c7f: POST /track
```

## Related

- Architecture dynamic view: `dynamic-subCenter-subscriptionPreferences` (not yet defined)
- Related flows: [Email Unsubscribe](email-unsubscribe.md), [Channel Management](channel-management.md), [SMS Unsubscribe](sms-unsubscribe.md)
