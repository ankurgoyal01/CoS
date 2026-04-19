---
service: "doorman"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Doorman.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [SAML Authentication Initiation](saml-authentication-initiation.md) | synchronous | Browser GET to `/authentication/initiation/:destination_id` | Internal user initiates SSO; Doorman validates destination and redirects to Okta |
| [Okta SSO Callback and Token Delivery](okta-sso-callback-token-delivery.md) | synchronous | Okta HTTP POST to `/okta/saml/sso` | Doorman receives SAML assertion, calls Users Service, delivers token to destination |
| [Token Verification by Destination Tool](token-verification-by-destination.md) | synchronous | Destination tool POST from browser form | Destination tool receives and verifies the Doorman-issued token |
| [Health Check and Status](health-check-status.md) | synchronous | Load balancer or operator GET | Kubernetes probes and operators verify Doorman liveness and version |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The full end-to-end authentication flow spans three systems: Doorman (`continuumDoormanService`), Okta (`oktaIdentityProvider`), and Users Service (`continuumUsersService`). See:

- [SAML Authentication Initiation](saml-authentication-initiation.md) — Doorman to Okta leg
- [Okta SSO Callback and Token Delivery](okta-sso-callback-token-delivery.md) — Okta to Doorman to Users Service to destination leg
