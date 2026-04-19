---
service: "itier-tpp"
title: "Portal Page Load"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "portal-page-load"
flow_type: synchronous
trigger: "Authenticated user navigates to any portal page"
participants:
  - "merchant"
  - "continuumTppWebApp"
  - "httpRoutes"
  - "featureControllers"
  - "requestModuleRegistry"
  - "serviceAdapters"
  - "continuumPartnerService"
architecture_ref: "dynamic-itier-tpp-onboarding-flow"
---

# Portal Page Load

## Summary

The portal page load flow describes the common request-handling pipeline that all page routes follow in the I-Tier TPP application. An authenticated user request enters through the Express route map, is dispatched to the appropriate feature controller, which uses the request module registry to resolve authenticated service clients, then calls service adapters to fetch page data from downstream services, and finally returns a server-rendered HTML page. This pipeline is the foundation of all read-oriented portal interactions and is the same pattern captured in the `dynamic-itier-tpp-onboarding-flow` architecture view.

## Trigger

- **Type**: user-action
- **Source**: Authenticated user's browser sends a GET request to any portal page (e.g., `/merchants/{partnerId}`, `/partnerbooking/deal/{dealId}`, `/metrics/merchants`)
- **Frequency**: Per-request (on demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant / Ops User | Initiates page navigation | `merchant` (person) |
| I-Tier TPP Web App | Receives request and coordinates rendering pipeline | `continuumTppWebApp` |
| HTTP Route Map | Matches inbound URL to the appropriate controller | `httpRoutes` |
| Feature Controllers | Implements page-specific data fetching and template rendering | `featureControllers` |
| Request Module Registry | Registers and provides request-scoped auth, rendering, and client modules | `requestModuleRegistry` |
| Service Adapters | Wraps downstream API clients; makes authenticated REST calls | `serviceAdapters` |
| Partner Service (PAPI) | Provides partner, merchant, and configuration data for most pages | `continuumPartnerService` |

## Steps

1. **Receives inbound request**: The `itier-server` process (Node.js cluster) receives the HTTP request on port `8000`; Express middleware stack runs (cookie-parser, body-parser, CSRF, `itier-user-auth`)
   - From: `merchant` (browser)
   - To: `continuumTppWebApp`
   - Protocol: HTTPS

2. **Validates authentication**: `itier-user-auth` middleware validates the `macaroon` cookie against Doorman. Unauthenticated requests are redirected to the Doorman initiation URL (`https://doorman-na.groupondev.com/authentication/initiation/third-party-partner-portal`)
   - From: `httpRoutes` (middleware)
   - To: Doorman (external auth service)
   - Protocol: HTTPS

3. **Matches route**: `httpRoutes` matches the request path against defined Express routes; dispatches to the responsible feature controller action
   - From: `httpRoutes`
   - To: `featureControllers`
   - Protocol: direct (in-process)

4. **Initializes request modules**: The feature controller calls `requestModuleRegistry` to register and resolve request-scoped modules (auth context, Gofer clients, rendering helpers)
   - From: `featureControllers`
   - To: `requestModuleRegistry`
   - Protocol: direct (in-process)

5. **Acquires service clients**: `serviceAdapters` uses modules from `requestModuleRegistry` to build authenticated Gofer/ApiProxy HTTP clients for the page's required downstream services
   - From: `serviceAdapters`
   - To: `requestModuleRegistry`
   - Protocol: direct (in-process)

6. **Fetches page data**: `featureControllers` calls `serviceAdapters` to fetch all data needed for the page (e.g., partner data from Partner Service, deal data from API Lazlo, geo data from Geo Details)
   - From: `featureControllers`
   - To: `serviceAdapters` to downstream services
   - Protocol: REST (HTTPS)

7. **Renders page**: The controller composes the page template (Hogan.js + Preact components) with fetched data and calls `itier-render` / `remote-layout` to produce the final HTML

8. **Returns response**: The server sends the rendered HTML response back to the browser; `itier-instrumentation` records request metrics (status code, latency)
   - From: `continuumTppWebApp`
   - To: `merchant` (browser)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unauthenticated request | Doorman redirect | 302 redirect to Doorman login |
| Downstream service timeout | Gofer timeout (default 10 s; Partner Service 30 s) | `itier-error-page` rendered with error details |
| Downstream service 5xx | Error propagated by service adapter | Error page rendered |
| Route not found | Express 404 handler | 404 error page rendered |
| Uncaught exception in controller | `keldor-crash-handler` catches and logs; cluster worker restarts | Error page; Nagios alert `tpp_errors_and_boots increase` |

## Sequence Diagram

```
Merchant -> continuumTppWebApp: GET /merchants/{partnerId} (macaroon cookie)
continuumTppWebApp -> httpRoutes: match route
httpRoutes -> featureControllers: dispatch to merchants controller
featureControllers -> requestModuleRegistry: initialize request modules
requestModuleRegistry --> featureControllers: auth context + service clients
featureControllers -> serviceAdapters: fetch partner/merchant data
serviceAdapters -> continuumPartnerService: GET /merchants/{partnerId}
continuumPartnerService --> serviceAdapters: merchant data
serviceAdapters --> featureControllers: page data
featureControllers --> continuumTppWebApp: rendered HTML
continuumTppWebApp --> Merchant: 200 HTML response
```

## Related

- Architecture dynamic view: `dynamic-itier-tpp-onboarding-flow`
- Related flows: [Merchant Onboarding](merchant-onboarding.md), [Partner Configuration Review](partner-config-review.md), [Booker Deal Mapping](booker-deal-mapping.md), [Mindbody Deal Mapping](mindbody-deal-mapping.md)
