---
service: "my_appointments_client"
title: "Mobile Webview Page Load"
generated: "2026-03-03"
type: flow
flow_name: "mobile-webview-load"
flow_type: synchronous
trigger: "Mobile app opens /mobile-reservation/main webview URL"
participants:
  - "myAppts_mobileController"
  - "myAppts_requestModules"
  - "continuumApiLazloService"
  - "continuumAppointmentsEngine"
  - "continuumLayoutService"
architecture_ref: "dynamic-dynamics-continuum-my-appointments-client-reservation"
---

# Mobile Webview Page Load

## Summary

The Mobile Webview Page Load flow handles the server-side rendering of the main reservation management page (`/mobile-reservation/main`) embedded in the Groupon mobile app as a webview. The Mobile Web Controller orchestrates parallel fetches of deal, groupon, and availability data from downstream APIs, assembles a page object, wraps it with mobile layout chrome from the Layout Service, and streams the final HTML to the mobile client.

## Trigger

- **Type**: user-action
- **Source**: Groupon mobile app opens `/mobile-reservation/main` (or `/mobile-reservation` loader) webview with query parameters (`deal_id`, `order_id`/`order_uuid`, `voucher_id`, etc.)
- **Frequency**: On-demand, each time a user navigates to the My Reservations webview

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Mobile Web Controller | Receives and validates inbound request; orchestrates async data fetches; assembles page state; calls layout service | `myAppts_mobileController` |
| Request Module Registry | Provides initialized service clients (grouponV2, onlineBooking, remoteLayout, featureFlags, I18n) | `myAppts_requestModules` |
| Groupon V2 API (Lazlo) | Supplies deal data, groupon/voucher details, user data, and order status | `continuumApiLazloService` |
| Appointments Engine | Supplies reservation list and option settings | `continuumAppointmentsEngine` |
| Layout Service | Provides mobile layout chrome (lite header, hidden footer) | `continuumLayoutService` |

## Steps

1. **Mobile app opens webview**: Groupon mobile app loads `/mobile-reservation` (loader) or `/mobile-reservation/main` with query parameters including `deal_id`, `order_id`/`order_uuid`, and optionally `voucher_id`.
   - From: Groupon mobile app
   - To: `myAppts_mobileController`
   - Protocol: HTTPS (webview GET request)

2. **Middleware chain processes request**: `keldor-config`, `cookieParser`, `localeMiddleware`, `divisionMiddleware`, and `itier-user-auth` middleware run, populating request context with config, locale, division, and auth token.
   - From: Express middleware stack
   - To: `myAppts_mobileController`
   - Protocol: Direct (Node.js middleware)

3. **Controller validates parameters**: Mobile Web Controller checks for required query parameters (`deal_id`, required booking params). If a scheduler mobile direct-link pattern is detected, it redirects to the scheduler URL.
   - From: `myAppts_mobileController`
   - To: `myAppts_mobileController` (internal validation)
   - Protocol: Direct

4. **EMEA redirect check**: If `emeaRedirectEnabled` feature flag is active and the request is a post-purchase booking from EMEA (and not a test deal), the controller redirects to the EMEA booking tool.
   - From: `myAppts_mobileController`
   - To: EMEA booking tool redirect
   - Protocol: HTTP redirect

5. **Parallel data fetches**: `async.auto` orchestrates concurrent requests to retrieve: deal details, groupon/voucher data, reservation list, option settings, and order status from downstream services.
   - From: `myAppts_mobileController` (via `myAppts_requestModules`)
   - To: `continuumApiLazloService` and `continuumAppointmentsEngine`
   - Protocol: HTTPS/JSON

6. **Page object assembly**: `pageBuilder` constructs the page state object from the aggregated API results, attaching app name (`mobile-my-reservations`), page type, localization, and feature flag data.
   - From: `myAppts_mobileController`
   - To: Page object (in-process)
   - Protocol: Direct

7. **Layout Service wraps page**: `remoteLayout.mobile(...)` fetches the mobile layout chrome from `continuumLayoutService` (lite header shown, mobile footer hidden) and merges it with the assembled page content.
   - From: `myAppts_mobileController` (via `myAppts_requestModules`)
   - To: `continuumLayoutService`
   - Protocol: HTTPS/JSON

8. **HTML rendered and returned**: `render.pageHtml(pageResult, responders.html)` sends the final server-rendered HTML to the mobile webview.
   - From: `myAppts_mobileController`
   - To: Groupon mobile app (webview)
   - Protocol: HTTPS (HTML response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required query parameters | Controller returns HTTP 400 immediately | Mobile app receives error response |
| Downstream API error (deal/groupon/reservation data) | `async.auto` error callback triggers; error logged with `itier-tracing` | HTTP 400 error page rendered |
| `SchedulerDeal` error from Appointments Engine | Caught specifically; controller issues redirect to scheduler URL | Mobile app follows redirect to scheduler |
| Layout Service unavailable | Page render fails; error propagated | Mobile app receives error page |
| EMEA redirect (feature-gated) | 301 redirect to EMEA booking tool | Mobile app follows redirect |

## Sequence Diagram

```
MobileApp -> MobileController: GET /mobile-reservation/main?deal_id=...&order_id=...
MobileController -> FeatureFlags: Check emeaRedirectEnabled
MobileController -> ApiLazlo: Fetch deal, groupon, user data (parallel via async.auto)
MobileController -> AppointmentsEngine: Fetch reservations, option settings (parallel)
ApiLazlo --> MobileController: Deal + groupon data
AppointmentsEngine --> MobileController: Reservation list + settings
MobileController -> LayoutService: GET mobile layout chrome
LayoutService --> MobileController: Layout HTML fragment
MobileController -> MobileApp: 200 OK (rendered HTML page)
```

## Related

- Architecture dynamic view: `dynamic-dynamics-continuum-my-appointments-client-reservation`
- Related flows: [Widget Bootstrap](widget-bootstrap.md), [Reservation Creation](reservation-creation.md)
