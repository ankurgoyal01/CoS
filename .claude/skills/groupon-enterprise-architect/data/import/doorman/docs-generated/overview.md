---
service: "doorman"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Identity and Access Management"
platform: "Continuum (internal tooling)"
team: "Users Team"
status: active
tech_stack:
  language: "Ruby"
  language_version: "3.1.3"
  framework: "Sinatra"
  framework_version: ""
  runtime: "Puma"
  runtime_version: ""
  build_tool: "Rake"
  package_manager: "Bundler"
---

# Doorman Overview

## Purpose

Doorman is Groupon's internal authentication gateway that implements Okta-based SAML 2.0 Single Sign-On for internal tool users. It acts as the SAML Service Provider between Okta (the Identity Provider) and internal tools built on the GAPI/GEARS platform. After validating a SAML assertion with the Users Service, Doorman issues a signed authentication token and delivers it to the registered destination tool via HTTP POST form submission.

## Scope

### In scope

- Initiating SAML 2.0 authentication requests directed to Okta
- Receiving and processing Okta SAML SSO callbacks (`/okta/saml/sso`)
- Delegating SAML assertion validation to the Users Service internal authentication endpoint
- Issuing signed authentication tokens (Base64url-encoded JSON) to registered destination tools
- Maintaining a registry of allowed destination applications to prevent open-redirect attacks
- Serving standard health check and status endpoints

### Out of scope

- User account management (handled by Users Service)
- SAML assertion cryptographic validation (delegated to Users Service)
- Session persistence (Doorman is stateless; tokens are issued once and consumed by the destination)
- Authorization and role management (handled by downstream tools)
- External customer authentication (internal-only service)

## Domain Context

- **Business domain**: Identity and Access Management
- **Platform**: Continuum — internal tooling authentication layer
- **Upstream consumers**: Internal tools registered as Doorman destinations (Command Center, Cyclops, Merchant Center, Goods Gateway, Third-Party Partner Portal, Stores Merchant Portal, Pizza NG, Dynamic Pricing Control Center, Getaways Extranet Admin, NOTS UI, Users Team Dashboard, MAS RBAC)
- **Downstream dependencies**: Okta (SAML Identity Provider), Users Service (token issuance and SAML validation)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | Users Team — owns and operates Doorman (users-team@groupon.com) |
| Oncall / Alerts | users-service-alerts@groupon.com, PagerDuty service PH9DWQC |
| Internal Tool Teams | Teams whose applications are registered as Doorman destinations |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 3.1.3 | `.ruby-version` |
| Framework | Sinatra | — | `Gemfile` |
| Web server | Puma | — | `Gemfile`, `.ci/Dockerfile` |
| Build tool | Rake | — | `Gemfile`, `Rakefile` |
| Package manager | Bundler | — | `Gemfile.lock` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `sinatra` | — | http-framework | HTTP routing and request handling |
| `sinatra-contrib` | — | http-framework | Sinatra extensions (JSON helper, Reloader) |
| `puma` | — | http-framework | Multi-threaded Rack web server |
| `ruby-saml` | — | auth | Builds SAML 2.0 AuthnRequests and parses SAML responses |
| `http` | — | http-client | Makes outbound HTTP calls to Users Service |
| `nokogiri` | — | serialization | XML parsing (SAML response dependency) |
| `activesupport` | 8.0.2.1 | utility | Core Ruby extensions (blank?, present?, HashWithIndifferentAccess) |
| `opentelemetry-exporter-otlp` | — | metrics | OpenTelemetry OTLP trace export |
| `opentelemetry-instrumentation-sinatra` | — | metrics | Automatic Sinatra request instrumentation |
| `sonoma-metrics` | — | metrics | Groupon-internal Rack metrics middleware |
| `steno_logger` | — | logging | Structured JSON logging |
| `uuidtools` | — | utility | UUID generation |
| `multi_json` | — | serialization | JSON encoding/decoding |
| `dottable_hash` | — | utility | Dot-notation config access |
