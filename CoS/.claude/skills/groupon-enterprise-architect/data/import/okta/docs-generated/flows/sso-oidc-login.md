---
service: "okta"
title: "SSO Login via OIDC"
generated: "2026-03-03"
type: flow
flow_name: "sso-oidc-login"
flow_type: synchronous
trigger: "User initiates login through a Groupon application"
participants:
  - "continuumOktaService"
  - "ssoBroker"
  - "directoryAdapter"
  - "oktaIdp"
  - "continuumUsersService"
  - "continuumOktaConfigStore"
architecture_ref: "dynamic-okta-sso-provisioning-flow"
---

# SSO Login via OIDC

## Summary

This flow describes how a user authenticates into a Groupon application using Okta as the identity provider via the OIDC authorization code flow. The `continuumOktaService` acts as the OIDC relying party: it redirects the user to Okta for authentication, receives the authorization code, exchanges it for ID and access tokens, and resolves the resulting identity into the Continuum user model.

## Trigger

- **Type**: user-action
- **Source**: User navigates to a Groupon application login page and selects Okta SSO login
- **Frequency**: On demand, per login request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Continuum Okta Service | OIDC relying party; orchestrates the SSO flow | `continuumOktaService` |
| SSO Broker | Handles OIDC redirect, code exchange, and token validation | `ssoBroker` |
| Directory Adapter | Resolves user identity attributes and group mappings from token claims | `directoryAdapter` |
| Okta IdP | External identity provider; authenticates user and issues tokens | `oktaIdp` |
| Continuum Users Service | Receives resolved user identity for session establishment | `continuumUsersService` |
| Okta Configuration Store | Provides tenant mappings and connector configuration | `continuumOktaConfigStore` |

## Steps

1. **Receives login request**: A Groupon application or API gateway receives a user login request and delegates to the Continuum Okta Service.
   - From: `Groupon application`
   - To: `continuumOktaService`
   - Protocol: HTTPS

2. **Reads tenant configuration**: The SSO Broker reads the relevant tenant mapping and OIDC client configuration from the Okta Configuration Store.
   - From: `ssoBroker`
   - To: `continuumOktaConfigStore`
   - Protocol: PostgreSQL

3. **Redirects user to Okta for authentication**: The SSO Broker constructs the OIDC authorization request and redirects the user's browser to the Okta IdP authorization endpoint.
   - From: `ssoBroker`
   - To: `oktaIdp`
   - Protocol: OIDC / HTTPS (browser redirect)

4. **User authenticates at Okta**: The Okta IdP authenticates the user (username/password, MFA, etc.) and issues an authorization code.
   - From: `oktaIdp`
   - To: `ssoBroker` (via browser callback/redirect)
   - Protocol: OIDC / HTTPS

5. **Exchanges authorization code for tokens**: The SSO Broker calls the Okta token endpoint with the authorization code to receive ID and access tokens.
   - From: `ssoBroker`
   - To: `oktaIdp`
   - Protocol: OIDC / HTTPS (back-channel)

6. **Requests identity attribute mapping**: The SSO Broker passes token claims to the Directory Adapter for user/group resolution and attribute translation.
   - From: `ssoBroker`
   - To: `directoryAdapter`
   - Protocol: Direct (internal NestJS component call)

7. **Resolves attributes to Continuum user model**: The Directory Adapter maps Okta identity attributes and group memberships to the Continuum user model format.
   - From: `directoryAdapter`
   - To: `ssoBroker` (resolved user object)
   - Protocol: Direct (internal)

8. **Syncs user profile to Continuum Users Service**: The Continuum Okta Service synchronizes the resolved user identity and profile attributes to `continuumUsersService`.
   - From: `continuumOktaService`
   - To: `continuumUsersService`
   - Protocol: REST (internal)

9. **Establishes authenticated session**: The authenticated user session is returned to the originating Groupon application.
   - From: `continuumOktaService`
   - To: `Groupon application`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Okta IdP unreachable | SSO Broker receives connection error | Login fails; user presented with error |
| Invalid or expired authorization code | Okta token endpoint returns error | Login fails; SSO Broker rejects the session |
| Tenant configuration not found in config store | SSO Broker cannot resolve OIDC client config | Login fails; configuration error returned |
| `continuumUsersService` unavailable | User sync fails after successful token exchange | Session may be partially established; behavior depends on implementation |

## Sequence Diagram

```
User -> continuumOktaService: Initiates SSO login
continuumOktaService (ssoBroker) -> continuumOktaConfigStore: Reads tenant OIDC config
continuumOktaService (ssoBroker) -> oktaIdp: Redirects with OIDC authorization request
oktaIdp -> User: Prompts authentication (browser)
User -> oktaIdp: Submits credentials / MFA
oktaIdp -> continuumOktaService (ssoBroker): Returns authorization code (redirect)
continuumOktaService (ssoBroker) -> oktaIdp: Exchanges code for ID/access tokens
oktaIdp --> continuumOktaService (ssoBroker): Returns ID token + access token
continuumOktaService (ssoBroker) -> directoryAdapter: Requests attribute/group mapping
directoryAdapter --> continuumOktaService (ssoBroker): Returns Continuum user object
continuumOktaService -> continuumUsersService: Syncs user profile and group assignments
continuumUsersService --> continuumOktaService: Acknowledges sync
continuumOktaService --> User: Establishes authenticated session
```

## Related

- Architecture dynamic view: `dynamic-okta-sso-provisioning-flow`
- Related flows: [SCIM User Provisioning](scim-user-provisioning.md), [Identity Attribute Mapping](identity-attribute-mapping.md)
