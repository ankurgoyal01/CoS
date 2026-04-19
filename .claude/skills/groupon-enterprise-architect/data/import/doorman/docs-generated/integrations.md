---
service: "doorman"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 1
---

# Integrations

## Overview

Doorman has two runtime dependencies: one external (Okta, the SAML Identity Provider) and one internal (Users Service, which validates SAML assertions and issues tokens). Both are critical to the authentication flow — if either is unavailable, authentication cannot complete. Additionally, Doorman integrates with a set of registered destination tools at the end of the SSO flow, though these are consumers of Doorman rather than dependencies.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Okta | SAML 2.0 / HTTPS redirect | Identity Provider; authenticates Groupon employees and returns SAML assertions | yes | `oktaIdentityProvider` |

### Okta Detail

- **Protocol**: SAML 2.0 — Doorman redirects browsers to the Okta SSO URL and receives the SAML assertion callback at `POST /okta/saml/sso`
- **Base URL (development)**: `https://groupon.okta.com/app/template_saml_2_0/kzkz1mvjNHBGNHSEYQPS/sso/saml`
- **Base URL (production NA)**: `https://groupon.okta.com/app/template_saml_2_0/kzkzb11nSREUXXNRYBAF/sso/saml`
- **Auth**: None — browser redirect flow; Okta authenticates the user and posts the SAML response back
- **Purpose**: Doorman is the SAML Service Provider; Okta is the Identity Provider. Doorman builds `AuthnRequest` payloads using the `ruby-saml` library and sends them via HTTP redirect binding.
- **Failure mode**: If Okta is unavailable, the browser redirect does not reach the IdP and authentication cannot initiate. No fallback exists.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Users Service | HTTPS / REST | Validates the SAML assertion and issues a signed authentication token | `continuumUsersService` |

### Users Service Detail

- **Protocol**: HTTPS REST POST
- **Endpoint**: `POST /users/v1/accounts/internal_authentication`
- **Auth**: `X-Api-Key` header (value configured per environment in `config/<env>/users_service.yml`)
- **Timeout**: 2000 ms (production), 10000 ms (development)
- **User-Agent**: `Doorman`
- **Request payload**: `{ "saml": "<Base64-encoded SAML response>" }`
- **Response (success)**: `{ "account": { "id": "..." }, "token": "<signed token>" }`
- **Purpose**: Doorman delegates SAML cryptographic validation and token signing to the Users Service. Doorman itself does not validate SAML signatures.
- **Failure mode**: If Users Service returns a non-200 response or times out, Doorman renders the SSO postback form with an error message instead of a token. The destination tool receives an `error` field rather than a `token`.
- **Circuit breaker**: No evidence found in codebase. SSL verification is disabled (`verify_mode: OpenSSL::SSL::VERIFY_NONE`) for the Users Service connection.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Command Center (`command-center`) | HTTPS form POST | Internal operational tooling authentication |
| Command Center Cloud (`command-center-cloud`) | HTTPS form POST | Cloud-based command center authentication |
| Cyclops (`cyclops`) | HTTPS form POST | Customer support tool authentication |
| Cyclops as a Platform (`cyclops-as-a-platform`) | HTTPS form POST | CAAP authentication |
| Dynamic Pricing Control Center (`dynamic-pricing-control-center`) | HTTPS form POST | DPCC service authentication |
| Getaways Extranet Admin (`getaways`) | HTTPS form POST | Getaways extranet admin authentication |
| Goods Gateway (`goods-gateway`) | HTTPS form POST | Goods Gateway session authentication |
| Merchant Center (`merchant-center`) | HTTPS form POST | Merchant Center internal login |
| NOTS UI (`nots-ui`) | HTTPS form POST | Merchant NOTS service UI authentication |
| Pizza NG (`pizza-ng`) | HTTPS form POST | Pizza internal tool authentication |
| Stores Merchant Portal (`stores-merchant-portal`) | HTTPS form POST | Stores management portal authentication |
| Third-Party Partner Portal (`third-party-partner-portal`) | HTTPS form POST | TPP authentication |
| Users Team Dashboard (`users-team-dashboard`) | HTTPS form POST | Users Team dashboard authentication |
| MAS RBAC (`mas-rbac`) | HTTPS form POST | RBAC UI authentication |

> The above consumers are derived from the registered destinations in `config/production-us-central1/destinations.yml`. Each receives a signed token or error via an auto-submitting browser form POST to their configured `destination_path`.

## Dependency Health

Doorman does not implement explicit health checks against Okta or Users Service. The `GET /grpn/healthcheck` endpoint reflects Doorman's own readiness (presence of `heartbeat.txt`) only. Dependency health for Okta is verified implicitly during authentication flows. Users Service connectivity is validated at authentication time — a timeout or error response surfaces as an authentication failure to the end user.
