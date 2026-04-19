---
service: "subscription_flow"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Subscription & Loyalty"
platform: "continuum"
team: "Subscription Platform"
status: active
tech_stack:
  language: "JavaScript (CoffeeScript)"
  language_version: ""
  framework: "itier-server / Express"
  framework_version: ""
  runtime: "Node.js"
  runtime_version: ""
  build_tool: "npm"
  package_manager: "npm"
---

# Subscription Flow Overview

## Purpose

Subscription Flow is a stateless i-tier (integration-tier) web service responsible for rendering subscription modals and related UI assets for Groupon web clients. It receives requests from web browsers or the Groupon V2 API layer, loads configuration and experiment data from GConfig, and runs a renderer pipeline to produce the HTML response. It acts as the server-side rendering layer for the subscription acquisition user experience on groupon.com.

## Scope

### In scope

- Serving subscription modal HTML for integration into Groupon web pages
- Loading dynamic configuration and A/B experiment variants from GConfig
- Routing incoming requests to the appropriate subscription flow controller
- Applying fingerprint and Groupon middleware to normalise request context
- Rendering HTML responses via the itier render pipeline

### Out of scope

- Subscription lifecycle management (activation, billing, cancellation) — handled by upstream subscription services
- User authentication and session management — handled by Groupon V2 API / Users Service
- Subscription data persistence — this service is stateless with no database
- Payment processing for subscription charges

## Domain Context

- **Business domain**: Subscription & Loyalty
- **Platform**: Continuum
- **Upstream consumers**: Groupon web clients (browsers); Groupon V2 API embedding subscription modal content
- **Downstream dependencies**: Lazlo API Service (legacy endpoints), GConfig Service (dynamic config and experiments), Groupon V2 API

## Stakeholders

| Role | Description |
|------|-------------|
| Subscription Platform team | Owns development and operation of the service |
| Web / Front-end team | Integrates subscription modal into Groupon web pages |
| Growth / Experimentation team | Configures A/B experiments via GConfig that affect modal variants |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | JavaScript (CoffeeScript) | — | Inventory |
| Framework | itier-server / Express | — | Inventory |
| Runtime | Node.js | — | Inventory |
| Build tool | npm | — | Inventory |
| Package manager | npm | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| itier-server | — | http-framework | I-tier service framework built on Express; manages bootstrap, routing, and middleware lifecycle |
| Express | — | http-framework | Underlying HTTP server and routing engine |
| CoffeeScript | — | language | Compile-to-JS language used for application source |
| Keldor | — | ui-framework | Groupon component library used in rendering subscription UI assets |
| itier-groupon-v2 | — | http-client | Client library for Groupon V2 API integration |
| itier-render | — | ui-framework | I-tier HTML rendering pipeline for server-side template rendering |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
