---
service: "sub_center"
title: "Channel Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "channel-management"
flow_type: synchronous
trigger: "User toggles an individual subscription channel on the subscription center page"
participants:
  - "continuumSubCenterWebApp"
  - "grouponV2Api_ext_7c1d"
  - "subscriptionsService_ext_9a41"
  - "memcached_ext_0c5e"
architecture_ref: "dynamic-subCenter-channelManagement"
---

# Channel Management

## Summary

The channel management flow handles granular enable/disable actions for individual email or SMS subscription channels. When a user toggles a specific channel (for example, disabling promotional emails for a particular category), the service records the change to the appropriate downstream service and re-renders or confirms the updated preference state. This flow is typically triggered inline on the subscription center page, either via a form post or an AJAX-style interaction.

## Trigger

- **Type**: user-action
- **Source**: User toggling a specific subscription channel on the subscription center page
- **Frequency**: On-demand, per channel toggle action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Subscription Center Web App | Receives the channel toggle, writes the update, returns confirmation | `continuumSubCenterWebApp` |
| Groupon V2 API | Persists channel-level subscription preference changes | `grouponV2Api_ext_7c1d` |
| Subscriptions Service | Alternative target for channel updates depending on channel type | `subscriptionsService_ext_9a41` |
| Memcached | Provides cached channel metadata for validation and display | `memcached_ext_0c5e` |

## Steps

1. **Receives channel toggle request**: Browser sends a POST request specifying the channel identifier and the desired state (enabled/disabled).
   - From: End User (browser)
   - To: `httpRouter` in `continuumSubCenterWebApp`
   - Protocol: HTTP POST

2. **Routes to controller**: HTTP Router dispatches the request to the Controller Layer.
   - From: `httpRouter`
   - To: `subCenter_controllerLayer`
   - Protocol: Internal

3. **Invokes channel management handler**: Controller invokes Subscription Handlers with channel ID and target state.
   - From: `subCenter_controllerLayer`
   - To: `subscriptionHandlers`
   - Protocol: Internal

4. **Reads channel metadata from cache**: Cache Access checks Memcached for channel metadata to validate the channel ID and resolve display names.
   - From: `subscriptionHandlers` via `subCenter_cacheAccess`
   - To: `memcached_ext_0c5e`
   - Protocol: Memcached

5. **Writes channel preference**: Based on the channel type, External API Clients send the updated preference to either the Groupon V2 API or the Subscriptions Service.
   - From: `subscriptionHandlers` via `subCenter_externalApiClients`
   - To: `grouponV2Api_ext_7c1d` or `subscriptionsService_ext_9a41`
   - Protocol: HTTP/REST (stub only)

6. **Builds updated view model**: Subscription Presenters assemble the updated state for the response.
   - From: `subscriptionHandlers`
   - To: `presenters`
   - Protocol: Internal

7. **Renders confirmation response**: Page Renderer returns the updated channel state (as HTML or a partial view) to the browser.
   - From: `subscriptionHandlers`
   - To: `pageRenderer` → end user browser
   - Protocol: HTTP response (HTML)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid channel ID | Validate against cached channel metadata | Return 400 error page; no downstream call |
| Groupon V2 API unavailable | HTTP error from External API Clients | Render error; channel state not changed |
| Subscriptions Service unavailable | HTTP error from External API Clients | Render error; channel state not changed |
| Memcached unavailable | Fetch channel metadata directly from upstream | Degraded performance; flow completes normally |

## Sequence Diagram

```
User Browser -> continuumSubCenterWebApp (httpRouter): POST /subscription-center/preferences (channelId, state)
httpRouter -> subCenter_controllerLayer: route to channel management action
subCenter_controllerLayer -> subscriptionHandlers: invoke channel handler (channelId, enabled=true/false)
subscriptionHandlers -> subCenter_cacheAccess: read channel metadata
subCenter_cacheAccess -> memcached_ext_0c5e: GET channel:channelId
memcached_ext_0c5e --> subCenter_cacheAccess: channel metadata (or miss)
subscriptionHandlers -> subCenter_externalApiClients: POST channel preference update
subCenter_externalApiClients -> grouponV2Api_ext_7c1d: PUT /subscriptions/channels/channelId
grouponV2Api_ext_7c1d --> subCenter_externalApiClients: 200 OK (updated state)
subscriptionHandlers -> presenters: build updated view model
subscriptionHandlers -> pageRenderer: render confirmation
pageRenderer --> User Browser: 200 OK (updated channel state HTML)
```

## Related

- Architecture dynamic view: `dynamic-subCenter-channelManagement` (not yet defined)
- Related flows: [Subscription Preferences](subscription-preferences.md), [Email Unsubscribe](email-unsubscribe.md)
