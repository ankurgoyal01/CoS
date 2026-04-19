---
service: "goods-vendor-portal"
title: "Merchant Login"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-login"
flow_type: synchronous
trigger: "Merchant submits credentials on the portal login page"
participants:
  - "emberApp"
  - "goodsVendorPortal_apiClient"
  - "continuumGoodsVendorPortalWeb"
  - "gpapiApi_unk_1d2b"
architecture_ref: "dynamic-merchant-login"
---

# Merchant Login

## Summary

The Merchant Login flow authenticates a goods vendor and establishes a browser session that gates access to all protected portal routes. The portal delegates credential validation entirely to GPAPI through the Nginx proxy; upon successful authentication, `ember-simple-auth` stores the session locally and Ember's route guards allow navigation to the authenticated application. On failure, the portal surfaces GPAPI error messages to the user.

## Trigger

- **Type**: user-action
- **Source**: Merchant enters email and password on the portal login page and submits the form
- **Frequency**: On-demand; each time a merchant opens a new session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates login by submitting credentials | — |
| Ember UI | Renders the login form, captures credentials, initiates authentication via `ember-simple-auth` | `emberApp` |
| API Client | Constructs and dispatches the authentication request to the proxy | `goodsVendorPortal_apiClient` |
| Nginx (portal) | Receives the request and proxies it to GPAPI | `continuumGoodsVendorPortalWeb` |
| GPAPI | Validates credentials and returns a session token or error | `gpapiApi_unk_1d2b` |

## Steps

1. **Renders login form**: Ember routes the unauthenticated user to the login route; `emberApp` renders the login form component.
   - From: `emberApp` (router)
   - To: Merchant browser
   - Protocol: In-browser rendering

2. **Submits credentials**: Merchant enters email and password and submits the form; `ember-simple-auth` intercepts the submission.
   - From: Merchant browser
   - To: `emberApp`
   - Protocol: DOM event

3. **Issues authentication request**: `goodsVendorPortal_apiClient` dispatches `POST /goods-gateway/auth/login` with the credential payload.
   - From: `goodsVendorPortal_apiClient`
   - To: `continuumGoodsVendorPortalWeb` (Nginx)
   - Protocol: REST/HTTPS

4. **Proxies to GPAPI**: Nginx forwards the login request to the GPAPI authentication endpoint.
   - From: `continuumGoodsVendorPortalWeb`
   - To: `gpapiApi_unk_1d2b`
   - Protocol: REST/HTTPS

5. **Validates credentials**: GPAPI authenticates the merchant credentials against its identity store and returns a session token on success or an error payload on failure.
   - From: `gpapiApi_unk_1d2b`
   - To: `continuumGoodsVendorPortalWeb` (Nginx) → `goodsVendorPortal_apiClient`
   - Protocol: REST/HTTPS

6. **Stores session**: On success, `ember-simple-auth` stores the returned session token in the browser session store; the authenticated route guard is satisfied.
   - From: `emberApp` (ember-simple-auth)
   - To: Browser session store
   - Protocol: In-browser

7. **Redirects to dashboard**: Ember's router transitions the merchant to the authenticated landing route (dashboard or previously requested route).
   - From: `emberApp`
   - To: Merchant browser
   - Protocol: In-browser routing

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid credentials | GPAPI returns 401; portal displays "Invalid email or password" message inline on the login form | Merchant remains on the login page and may retry |
| GPAPI unreachable | Nginx proxy returns 502/503; `ember-simple-auth` surfaces a generic network error | Merchant sees a connection error message; no session is created |
| Session already active | `ember-simple-auth` detects an existing valid session on route load and redirects immediately to the dashboard | Login form is bypassed |
| Account locked | GPAPI returns 403 with a descriptive error; portal surfaces the message | Merchant is informed and directed to support |

## Sequence Diagram

```
Merchant -> emberApp: Submits login form (email, password)
emberApp -> goodsVendorPortal_apiClient: Initiate authentication
goodsVendorPortal_apiClient -> continuumGoodsVendorPortalWeb: POST /goods-gateway/auth/login
continuumGoodsVendorPortalWeb -> gpapiApi_unk_1d2b: POST /auth/login (proxied)
gpapiApi_unk_1d2b --> continuumGoodsVendorPortalWeb: 200 OK { session_token } | 401 Unauthorized
continuumGoodsVendorPortalWeb --> goodsVendorPortal_apiClient: Proxy response
goodsVendorPortal_apiClient --> emberApp: Session token or error
emberApp --> Merchant: Redirect to dashboard | Show error message
```

## Related

- Architecture dynamic view: `dynamic-merchant-login`
- Related flows: [Product Catalog Management](product-catalog-management.md), [Vendor Profile Self-Service](vendor-profile-self-service.md)
