---
service: "gpapi"
title: "Session Auth 2FA"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "session-auth-2fa"
flow_type: synchronous
trigger: "Vendor submits login credentials with reCAPTCHA token via Vendor Portal login form"
participants:
  - "continuumGpapiService"
  - "continuumGpapiDb"
  - "continuumGoogleRecaptcha"
  - "Users Service"
architecture_ref: "dynamic-vendorOnboardingFlow"
---

# Session Auth 2FA

## Summary

The session authentication flow handles vendor portal login with two-factor verification via Google reCAPTCHA Enterprise. When a vendor submits their credentials, gpapi verifies the reCAPTCHA token with Google's reCAPTCHA Enterprise service before validating credentials against the local user store and the Users Service. On success, a session is established. On logout, the session is destroyed. This flow is the gateway for all authenticated vendor portal operations.

## Trigger

- **Type**: user-action
- **Source**: Vendor submitting login form on Goods Vendor Portal UI
- **Frequency**: Per login attempt

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Vendor Portal UI | Collects credentials and reCAPTCHA token; initiates login | — |
| Goods Product API | Validates reCAPTCHA token; authenticates user; manages session | `continuumGpapiService` |
| Google reCAPTCHA Enterprise | Verifies reCAPTCHA token to detect bot activity | `continuumGoogleRecaptcha` |
| gpapi Database | Validates user credential record and session state | `continuumGpapiDb` |
| Users Service | Provides authoritative user identity and permissions | — |

## Steps

### Login

1. **Receive login request**: Vendor Portal UI submits credentials and reCAPTCHA response token.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v1/sessions`
   - Protocol: REST

2. **Verify reCAPTCHA token**: gpapi calls Google reCAPTCHA Enterprise API to score the submitted token.
   - From: `continuumGpapiService`
   - To: `continuumGoogleRecaptcha` (reCAPTCHA Enterprise API)
   - Protocol: HTTPS SDK (`google-cloud-recaptcha_enterprise` gem)

3. **Evaluate reCAPTCHA score**: gpapi evaluates the returned risk score against the configured threshold.
   - From: `continuumGpapiService`
   - To: `continuumGpapiService` (internal policy evaluation)
   - Protocol: direct

4. **Validate user credentials**: gpapi looks up the user record and validates the submitted password.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

5. **Fetch user permissions from Users Service**: gpapi retrieves the user's vendor associations and permissions.
   - From: `continuumGpapiService`
   - To: Users Service
   - Protocol: REST

6. **Establish session**: gpapi creates a new session record.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

7. **Return session**: gpapi returns the session token and user context to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 201 Created + session cookie or token)

### Logout

8. **Receive logout request**: Vendor Portal UI sends session destroy request.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `DELETE /api/v1/sessions/:id`
   - Protocol: REST

9. **Destroy session**: gpapi invalidates and removes the session record.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

10. **Return logout confirmation**: gpapi returns 204 No Content.
    - From: `continuumGpapiService`
    - To: Goods Vendor Portal UI
    - Protocol: REST (HTTP 204 No Content)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| reCAPTCHA score below threshold (bot detected) | Return 403 Forbidden | Login blocked |
| Google reCAPTCHA Enterprise unavailable | Return 503 Service Unavailable | All logins blocked until service restored |
| Invalid credentials | Return 401 Unauthorized | Login denied; no session created |
| User not found | Return 401 Unauthorized (generic; no user enumeration) | Login denied |
| Users Service unavailable | Return 503 or degraded session | Login may proceed with limited permissions |

## Sequence Diagram

```
VendorPortalUI -> continuumGpapiService: POST /api/v1/sessions (email, password, recaptcha_token)
continuumGpapiService -> continuumGoogleRecaptcha: verify token (site_key, token)
continuumGoogleRecaptcha --> continuumGpapiService: risk score response
continuumGpapiService -> continuumGpapiDb: SELECT user (validate credentials)
continuumGpapiDb --> continuumGpapiService: user record
continuumGpapiService -> UsersService: GET /users/:id (fetch permissions)
UsersService --> continuumGpapiService: user permissions
continuumGpapiService -> continuumGpapiDb: INSERT session record
continuumGpapiService --> VendorPortalUI: 201 Created (session token, user context)
```

## Related

- Architecture dynamic view: `dynamic-vendorOnboardingFlow`
- Related flows: [Vendor Onboarding](vendor-onboarding.md), [User-Vendor Linking](user-vendor-linking.md)
