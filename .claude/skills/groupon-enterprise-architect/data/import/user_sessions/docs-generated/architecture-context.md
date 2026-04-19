---
service: "user_sessions"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumUserSessionsWebApp]
---

# Architecture Context

## System Context

`continuumUserSessionsWebApp` sits at the browser-facing edge of the Continuum platform's identity layer. End users (shoppers) interact with it directly via their web browser to log in, register, or reset their password. The service does not own user data — all credential validation and account persistence flow through GAPI (`gapiSystem_5c8b`). Social login delegates OAuth token exchange to Google (`googleOAuth_1d2e`) and Facebook (`facebookOAuth_9a7c`). Session state is stored in a shared Memcached cluster (`memcachedCluster_6e2f`). The Deal Page Service (`dealPageService_3b4d`) drives users to this service when authentication is required and receives the post-login redirect.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| user_sessions Web App | `continuumUserSessionsWebApp` | WebApp | Node.js / itier-server | 7.14.2 | I-Tier server-rendered frontend handling login, signup, and password reset |

## Components by Container

### user_sessions Web App (`continuumUserSessionsWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `routes` | Defines HTTP route handlers for all login, signup, and password-reset paths | itier-server routing |
| `controllers` | Processes form submissions, coordinates auth flows, and prepares render context | JavaScript / Node.js |
| `authFlows` | Encapsulates login, social OAuth, registration, and password-reset orchestration logic | itier-user-auth, jsonwebtoken |
| `userSessions_gapiClient` | Wraps GAPI GraphQL calls for user lookup, credential validation, account creation, and token ops | @grpn/graphql-gapi |
| `cacheAdapter` | Reads and writes session state to the Memcached cluster | itier-cached |
| `frontendRenderer` | Renders server-side HTML pages and bundles client-side assets | itier-render, preact, webpack |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUserSessionsWebApp` | `gapiSystem_5c8b` | Validates credentials, creates accounts, generates/verifies password-reset tokens | GraphQL / HTTP |
| `continuumUserSessionsWebApp` | `googleOAuth_1d2e` | Initiates OAuth authorization and exchanges authorization codes for tokens | OAuth 2.0 / HTTPS |
| `continuumUserSessionsWebApp` | `facebookOAuth_9a7c` | Initiates OAuth authorization and exchanges authorization codes for tokens | OAuth 2.0 / HTTPS |
| `continuumUserSessionsWebApp` | `memcachedCluster_6e2f` | Stores and retrieves authenticated session objects | Memcached binary/text protocol |
| `dealPageService_3b4d` | `continuumUserSessionsWebApp` | Redirects unauthenticated users to login; receives post-login redirect | HTTP redirect |
| `shopperUser_2f1a` | `continuumUserSessionsWebApp` | Submits login/signup/password-reset forms via browser | HTTPS |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumUserSessionsWebApp`
