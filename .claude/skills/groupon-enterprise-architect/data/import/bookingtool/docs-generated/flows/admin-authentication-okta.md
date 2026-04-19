---
service: "bookingtool"
title: "Admin Authentication via Okta"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "admin-authentication-okta"
flow_type: synchronous
trigger: "Admin user accesses a protected route in the Booking Tool admin portal"
participants:
  - "Admin User (browser)"
  - "continuumBookingToolApp"
  - "btControllers"
  - "btDomainServices"
  - "Okta"
  - "continuumBookingToolMySql"
architecture_ref: "dynamic-bookingtool"
---

# Admin Authentication via Okta

## Summary

This flow describes how Groupon Operations admin users authenticate to access protected Booking Tool admin functions. When an unauthenticated user attempts to access an admin route, the Booking Tool redirects them to Okta for OAuth 2.0 authentication. Upon successful authentication, Okta returns an authorization code which the Booking Tool exchanges for tokens; a session is created, and the admin is granted access to protected operations.

## Trigger

- **Type**: user-action
- **Source**: Admin user navigates to a protected Booking Tool admin URL
- **Frequency**: Per login session — on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Admin User (browser) | Initiates access to the admin portal; completes Okta login | — |
| Booking Tool Application | Detects unauthenticated request; manages OAuth redirect and callback | `continuumBookingToolApp` |
| HTTP Controllers | Handles auth middleware, Okta callback, and session creation | `btControllers` |
| Domain Services | Validates Okta token; establishes admin session context | `btDomainServices` |
| Okta | External identity provider; authenticates admin user and issues tokens | — |
| Booking Tool MySQL | Stores or validates admin user records if locally cached | `continuumBookingToolMySql` |

## Steps

1. **Admin requests protected route**: Admin user navigates to a protected URL (e.g., merchant management or booking administration page).
   - From: `Admin User (browser)`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS

2. **Auth middleware detects unauthenticated request**: HTTP Controllers check for a valid session; no session found.
   - From: `btControllers`
   - To: `btControllers`
   - Protocol: direct

3. **Redirects to Okta authorization endpoint**: Booking Tool constructs the Okta OAuth 2.0 authorization URL using `OKTA_CLIENT_ID` and `OKTA_ISSUER`, then redirects the browser.
   - From: `continuumBookingToolApp`
   - To: `Admin User (browser)`
   - Protocol: HTTPS (HTTP 302 redirect)

4. **Admin authenticates with Okta**: Admin user completes login at the Okta hosted login page (credentials, MFA if configured).
   - From: `Admin User (browser)`
   - To: `Okta`
   - Protocol: HTTPS

5. **Okta redirects with authorization code**: Okta issues an authorization code and redirects the browser back to the Booking Tool OAuth callback URL.
   - From: `Okta`
   - To: `continuumBookingToolApp`
   - Protocol: HTTPS (HTTP 302 redirect with `?code=`)

6. **Booking Tool exchanges code for tokens**: HTTP Controllers receive the callback; Domain Services call Okta token endpoint with `OKTA_CLIENT_ID`, `OKTA_CLIENT_SECRET`, and the authorization code to obtain an access token and ID token.
   - From: `btIntegrationClients` (via `btDomainServices`)
   - To: `Okta`
   - Protocol: HTTPS/REST

7. **Validates token and extracts claims**: Domain Services validate the JWT using `lcobucci/jwt` and `OKTA_ISSUER`; extract admin user identity and roles from claims.
   - From: `btDomainServices`
   - To: `btDomainServices`
   - Protocol: direct

8. **Creates authenticated session**: Domain Services create a PHP session; session token stored in Redis. Admin user record may be checked or upserted in MySQL.
   - From: `btDomainServices`
   - To: `continuumBookingToolMySql` (and Redis)
   - Protocol: SQL/TCP

9. **Redirects admin to original destination**: Controller redirects the authenticated admin to the originally requested protected route.
   - From: `continuumBookingToolApp`
   - To: `Admin User (browser)`
   - Protocol: HTTPS (HTTP 302)

10. **Admin accesses protected functionality**: Subsequent requests carry the session cookie; HTTP Controllers validate session on each request.
    - From: `Admin User (browser)`
    - To: `continuumBookingToolApp`
    - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Admin not in Okta group | Okta rejects authentication | Admin redirected to error page; access denied |
| Authorization code expired | Token exchange fails; Okta returns error | Admin redirected to login; must re-authenticate |
| Invalid `OKTA_CLIENT_SECRET` | Token exchange returns 401 from Okta | HTTP 500 or auth error page; requires credential rotation |
| JWT validation failure | `lcobucci/jwt` throws exception | Session not created; admin redirected to login |
| MySQL session write failure | Session not persisted; admin denied access | HTTP 500; admin cannot log in until DB recovers |
| Okta service unavailable | HTTPS call to Okta times out | HTTP 503 or auth error page; all admin logins blocked |

## Sequence Diagram

```
AdminUser -> continuumBookingToolApp: GET /admin/<protected-route>
continuumBookingToolApp -> btControllers: Check session — none found
btControllers --> AdminUser: HTTP 302 redirect to Okta auth URL
AdminUser -> Okta: Login (credentials + MFA)
Okta --> AdminUser: HTTP 302 redirect with ?code=<auth_code>
AdminUser -> continuumBookingToolApp: GET /oauth/callback?code=<auth_code>
continuumBookingToolApp -> btControllers: Handle OAuth callback
btControllers -> btDomainServices: Exchange code for tokens
btDomainServices -> Okta: POST /token (client_id, client_secret, code)
Okta --> btDomainServices: access_token + id_token (JWT)
btDomainServices -> btDomainServices: Validate JWT (lcobucci/jwt)
btDomainServices -> continuumBookingToolMySql: Upsert admin user record (SQL/TCP)
btDomainServices -> Redis: Create session (SET session_token)
btDomainServices --> btControllers: Session established
btControllers --> continuumBookingToolApp: HTTP 302 redirect to original route
continuumBookingToolApp --> AdminUser: Admin portal page
```

## Related

- Architecture dynamic view: `dynamic-bookingtool`
- Related flows: [API Request Lifecycle](api-request-lifecycle.md)
