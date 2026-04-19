---
service: "sub_center"
title: "Email Unsubscribe"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "email-unsubscribe"
flow_type: synchronous
trigger: "User clicks an email unsubscribe link or submits the unsubscribe form"
participants:
  - "continuumSubCenterWebApp"
  - "grouponV2Api_ext_7c1d"
  - "gssService_ext_5b3e"
  - "memcached_ext_0c5e"
architecture_ref: "dynamic-subCenter-emailUnsubscribe"
---

# Email Unsubscribe

## Summary

The email unsubscribe flow handles a user's request to opt out of one or all Groupon email channels. It is typically triggered by a one-click unsubscribe link embedded in a marketing email. The service validates the request token, fetches the user's current subscription state, applies the unsubscribe action against the Groupon V2 API, and renders a confirmation page.

## Trigger

- **Type**: user-action
- **Source**: User clicking an unsubscribe link in a Groupon marketing email, or submitting the unsubscribe form on the subscription center page
- **Frequency**: On-demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Subscription Center Web App | Orchestrates the full unsubscribe request/response cycle | `continuumSubCenterWebApp` |
| Groupon V2 API | Reads and writes subscription opt-out state | `grouponV2Api_ext_7c1d` |
| GSS Service | Looks up subscription metadata and user identity mappings | `gssService_ext_5b3e` |
| Memcached | Provides cached channel metadata | `memcached_ext_0c5e` |

## Steps

1. **Receives unsubscribe request**: Browser sends GET request with unsubscribe token to the subscription center unsubscribe route.
   - From: End User (browser)
   - To: `httpRouter` in `continuumSubCenterWebApp`
   - Protocol: HTTP GET

2. **Routes to controller**: HTTP Router dispatches the request to the Controller Layer's unsubscribe action.
   - From: `httpRouter`
   - To: `subCenter_controllerLayer`
   - Protocol: Internal

3. **Invokes unsubscribe handler**: Controller invokes the Subscription Handlers with the decoded token and channel parameters.
   - From: `subCenter_controllerLayer`
   - To: `subscriptionHandlers`
   - Protocol: Internal

4. **Loads subscription data**: Subscription Handlers ask the Subscription Data Getter to fetch the user's current subscription state.
   - From: `subscriptionHandlers`
   - To: `subscriptionDataGetter`
   - Protocol: Internal

5. **Queries GSS Service**: Subscription Data Getter uses External API Clients to look up user identity and subscription metadata from GSS.
   - From: `subscriptionDataGetter` via `subCenter_externalApiClients`
   - To: `gssService_ext_5b3e`
   - Protocol: HTTP/REST (stub only)

6. **Checks channel metadata cache**: Cache Access checks Memcached for division and channel metadata before making upstream calls.
   - From: `subscriptionHandlers` via `subCenter_cacheAccess`
   - To: `memcached_ext_0c5e`
   - Protocol: Memcached

7. **Posts unsubscribe to Groupon V2 API**: External API Clients send the unsubscribe action to the Groupon V2 API.
   - From: `subscriptionHandlers` via `subCenter_externalApiClients`
   - To: `grouponV2Api_ext_7c1d`
   - Protocol: HTTP/REST (stub only)

8. **Builds confirmation view model**: Subscription Presenters assemble the confirmation page view model.
   - From: `subscriptionHandlers`
   - To: `presenters`
   - Protocol: Internal

9. **Renders confirmation page**: Page Renderer produces the HTML confirmation page and returns it to the browser.
   - From: `subscriptionHandlers`
   - To: `pageRenderer` → end user browser
   - Protocol: HTTP response (HTML)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired unsubscribe token | Validate token on receipt; reject if invalid | Render error page informing user the link has expired |
| GSS Service unavailable | HTTP error from External API Clients | Render error page; unsubscribe not processed |
| Groupon V2 API returns error | HTTP error from External API Clients | Render error page; user is not unsubscribed; no silent failure |
| Memcached unavailable | Cache bypass; fetch from upstream service directly | Degraded performance; flow completes normally |

## Sequence Diagram

```
User Browser -> continuumSubCenterWebApp (httpRouter): GET /subscription-center/unsubscribe?token=...
httpRouter -> subCenter_controllerLayer: route to unsubscribe action
subCenter_controllerLayer -> subscriptionHandlers: invoke unsubscribe handler
subscriptionHandlers -> subscriptionDataGetter: load subscription data
subscriptionDataGetter -> subCenter_externalApiClients: fetch user identity
subCenter_externalApiClients -> gssService_ext_5b3e: GET user/subscription metadata
gssService_ext_5b3e --> subCenter_externalApiClients: subscription metadata
subscriptionHandlers -> subCenter_cacheAccess: read channel metadata
subCenter_cacheAccess -> memcached_ext_0c5e: GET channel metadata
memcached_ext_0c5e --> subCenter_cacheAccess: cached metadata (or miss)
subscriptionHandlers -> subCenter_externalApiClients: POST unsubscribe
subCenter_externalApiClients -> grouponV2Api_ext_7c1d: POST /subscriptions/unsubscribe
grouponV2Api_ext_7c1d --> subCenter_externalApiClients: 200 OK
subscriptionHandlers -> presenters: build confirmation view model
subscriptionHandlers -> pageRenderer: render confirmation HTML
pageRenderer --> User Browser: 200 OK (confirmation page)
```

## Related

- Architecture dynamic view: `dynamic-subCenter-emailUnsubscribe` (not yet defined)
- Related flows: [SMS Unsubscribe](sms-unsubscribe.md), [Subscription Preferences](subscription-preferences.md), [Channel Management](channel-management.md)
