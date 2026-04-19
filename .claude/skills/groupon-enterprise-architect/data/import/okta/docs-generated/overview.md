---
service: "okta"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Identity & Access Management"
platform: "Continuum"
team: "Okta"
status: active
tech_stack:
  language: "TypeScript"
  language_version: ""
  framework: "NestJS"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: ""
  build_tool: ""
  package_manager: ""
---

# Okta Overview

## Purpose

The Okta service is Groupon's integration layer between the Okta identity provider and the Continuum platform. It enables Single Sign-On (SSO) via OIDC and synchronizes user identities and group memberships through SCIM-based provisioning. The service acts as a broker, translating Okta identity events and tokens into Continuum user model updates.

## Scope

### In scope

- Handling OIDC authorization code and token exchange flows with the Okta identity provider
- Processing SCIM-based user and group provisioning events from Okta
- Mapping identity attributes and group memberships between Okta and the Continuum user model
- Reading and writing tenant mappings, provisioning configuration, and connector metadata to the Okta Configuration Store (PostgreSQL)
- Synchronizing user profile and group assignment data to `continuumUsersService`

### Out of scope

- User authentication credential management (owned by Okta IdP)
- Core user profile storage and management (owned by `continuumUsersService`)
- Customer-facing commerce or order workflows
- Directory services administration within Okta itself

## Domain Context

- **Business domain**: Identity & Access Management
- **Platform**: Continuum
- **Upstream consumers**: Groupon applications and services that rely on SSO sessions and user identities provisioned through Okta
- **Downstream dependencies**: Okta IdP (OIDC/SCIM APIs), `continuumUsersService` (user profile sync), `continuumOktaConfigStore` (PostgreSQL configuration store)

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner | rwetterich — overall service ownership |
| Team Members | twong, rdafonseca, bperkins |
| SRE / On-call | it-sys-engineering@groupon.pagerduty.com (PagerDuty: PQPJUWN) |
| Team Email | syseng@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | TypeScript | Not specified | architecture DSL: `TypeScript/Node.js` |
| Framework | NestJS | Not specified | architecture DSL: `NestJS Component` |
| Runtime | Node.js | Not specified | architecture DSL: `TypeScript/Node.js` |
| Build tool | Not specified | — | No package.json or build file found in repo |
| Package manager | Not specified | — | No package.json found in repo |

### Key Libraries

> No evidence found in codebase. The repo contains only architecture DSL and service metadata; no application source files or dependency manifests are present in the federated snapshot.
