---
service: "doorman"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumPlatform"
  containers: ["continuumDoormanService"]
---

# Architecture Context

## System Context

Doorman sits within the Continuum platform as the authentication gateway for all internal Groupon tooling that uses the GAPI/GEARS authentication pattern. Internal tool users (Groupon employees) are redirected to Doorman to initiate SAML-based login with Okta. Doorman is the SAML Service Provider: it builds authentication requests, receives Okta's callback, delegates token issuance to the Users Service, and delivers signed tokens to registered destination tools. It has no external customer-facing presence.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Doorman | `continuumDoormanService` | Service | Sinatra (Ruby) | 3.1.3 | Okta-based authentication gateway for internal tools built on GAPI |

## Components by Container

### Doorman (`continuumDoormanService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `authenticationController` | Handles SAML auth initiation (`GET /authentication/initiation/:destination_id`) and processes Okta SSO callback (`POST /okta/saml/sso`) | Sinatra controller |
| `statusController` | Serves health check (`GET /grpn/healthcheck`), ping (`GET /ping`), and status (`GET /status`) endpoints | Sinatra controller |
| `testDestinationController` | Provides test destination endpoint for validating local auth flows (`GET /test_destination`, `POST /test_destination`) | Sinatra controller |
| `usersServiceInternalAuth` | Makes HTTP POST to Users Service `/users/v1/accounts/internal_authentication` to validate SAML assertions and retrieve tokens | HTTP client |
| `samlAuthRequestBuilder` | Builds SAML 2.0 AuthnRequest payloads using `ruby-saml`; configures issuer, ACS URL, and IdP SSO target URL | Ruby class |
| `token` | Parses, decodes (Base64url), and cryptographically verifies signed authentication tokens (RSA and DSA support, versions 0 and 1) | Ruby class |
| `runtimeInfo` | Reads build SHA and version from `REVISION` file; tracks service boot time | Ruby class |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDoormanService` | `oktaIdentityProvider` | Redirects browser to Okta SAML SSO endpoint; receives SAML callback | HTTPS redirect / SAML 2.0 |
| `continuumDoormanService` | `continuumUsersService` | Sends SAML assertion for validation and token issuance via internal authentication API | HTTPS / REST |
| Internal tool user (browser) | `continuumDoormanService` | Initiates authentication; receives token via HTTP POST form | HTTPS |
| `continuumDoormanService` | Registered destination tool | Posts signed token via browser-side auto-submitting HTML form | HTTPS form POST |

## Architecture Diagram References

- Component: `components-doorman_components`
