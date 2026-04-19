---
service: "user_sessions"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Identity & Authentication"
platform: "continuum"
team: "Identity Platform"
status: active
tech_stack:
  language: "JavaScript"
  language_version: "Node.js ^16"
  framework: "itier-server"
  framework_version: "7.14.2"
  runtime: "Node.js"
  runtime_version: "v16.15.1 (Alpine)"
  build_tool: "npm"
  package_manager: "npm"
---

# user_sessions Overview

## Purpose

user_sessions is the primary I-Tier frontend application responsible for managing user authentication, registration, and password recovery within the Continuum platform. It serves browser-facing login, signup, and password reset pages, delegating all user-record and credential operations to the downstream GAPI (GraphQL API) layer. The service owns the session lifecycle — establishing authenticated sessions via cookie after successful credential validation or OAuth token exchange.

## Scope

### In scope

- Rendering server-side HTML for login (`/login`), signup (`/signup`), and password reset (`/users/password_reset/:token`, `/users/reset_password/:userId/:token`, `/passwordreset/:token`) routes
- Accepting and validating user credential submissions (email/password login, signup form)
- Initiating and completing Google OAuth and Facebook OAuth social login flows
- Creating and caching authenticated user sessions in Memcached
- Setting authenticated session cookies on successful login or registration
- Forwarding credential validation and account creation requests to GAPI

### Out of scope

- Persistent storage of user records or credentials (owned by GAPI / upstream user services)
- Token issuance for machine-to-machine authentication
- Multi-factor authentication
- Profile management and account settings beyond initial registration
- Deal browsing or purchase flows (handled by Deal Page Service and other Continuum services)

## Domain Context

- **Business domain**: Identity & Authentication
- **Platform**: Continuum
- **Upstream consumers**: Web browsers / end users, Deal Page Service (login redirect flows)
- **Downstream dependencies**: GAPI (GraphQL/HTTP — user creation, credential validation, token generation), Google OAuth, Facebook OAuth, Memcached cluster (session caching)

## Stakeholders

| Role | Description |
|------|-------------|
| Identity Platform team | Owns service development, deployment, and on-call |
| End users (shoppers) | Authenticate, register, and reset passwords through this service |
| Deal Page Service | Redirects unauthenticated users to login and receives post-login redirects |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript | Node.js ^16 | package.json engines field |
| Framework | itier-server | 7.14.2 | package.json dependencies |
| Runtime | Node.js (Alpine) | v16.15.1 | Dockerfile base image |
| Build tool | npm | — | package.json / package-lock.json |
| Package manager | npm | — | package-lock.json |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | 7.14.2 | http-framework | Core I-Tier HTTP server and routing framework |
| itier-user-auth | 8.1.0 | auth | User authentication helpers and session utilities |
| @grpn/graphql-gapi | 5.2.9 | http-framework | GAPI GraphQL client for downstream user/session operations |
| itier-cached | 8.1.3 | db-client | Memcached client abstraction for session caching |
| itier-render | 2.0.3 | ui-framework | Server-side rendering engine for I-Tier pages |
| itier-instrumentation | 9.13.4 | metrics | Metrics and instrumentation for I-Tier services |
| preact | 10.6.6 | ui-framework | Lightweight React-compatible UI library for client-side hydration |
| keldor | 7.3.9 | http-framework | I-Tier middleware and request lifecycle utilities |
| jsonwebtoken | 8.5.1 | auth | JWT parsing and validation for token-based flows |
| itier-tracing | 1.6.1 | metrics | Distributed tracing integration |
| webpack | 4.46.0 | http-framework | Client-side asset bundling |
| mocha | 9.2.1 | testing | Unit and integration test runner |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
