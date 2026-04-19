---
service: "akamai-cdn"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Networking / Edge Delivery"
platform: "Continuum"
team: "cloud-routing@groupon.com"
status: active
tech_stack:
  language: "N/A"
  language_version: "N/A"
  framework: "N/A"
  framework_version: "N/A"
  runtime: "Akamai Edge Platform"
  runtime_version: "N/A"
  build_tool: "N/A"
  package_manager: "N/A"
---

# Akamai CDN Overview

## Purpose

Akamai CDN is Groupon's global content delivery network, operated as a managed SaaS platform. The `akamai-cdn` service represents Groupon's operational ownership of that CDN — defining property rules, caching policies, and routing configurations applied to the Akamai edge network. It exists to ensure that web content, API responses, and static assets are served to consumers and merchants with low latency and high availability from geographically distributed edge nodes.

## Scope

### In scope

- Defining and applying CDN property rules and routing policies via Akamai Control Center (`https://control.akamai.com`)
- Managing caching behavior (TTLs, cache keys, cache invalidation rules) for Groupon properties
- Configuring WAF (Web Application Firewall) rules and security policies at the edge
- Collecting and publishing operational signals — CDN change events and runtime delivery health telemetry
- Owning Groupon's relationship with the Akamai platform, including escalation paths and policy governance

### Out of scope

- Origin server configuration and application-layer logic (owned by upstream services)
- DNS management beyond Akamai Edge DNS entries (owned by network/DNS team)
- TLS certificate provisioning for non-Akamai-managed certificates
- Content creation and static asset generation (owned by consuming applications)

## Domain Context

- **Business domain**: Networking / Edge Delivery
- **Platform**: Continuum
- **Upstream consumers**: All Groupon web properties and API gateways that route traffic through Akamai edge nodes; end users (consumers, merchants) whose requests traverse the CDN
- **Downstream dependencies**: Akamai SaaS platform (`akamai` external system) accessed via HTTPS at `https://control.akamai.com`

## Stakeholders

| Role | Description |
|------|-------------|
| SRE / Cloud Routing Team | Owns CDN configuration, monitors delivery health, and handles incidents — notified via cloud-routing@groupon.com |
| Application Teams | Consumers of CDN delivery; depend on correct caching and routing rules |
| Security Team | Relies on WAF and security policy enforcement at the Akamai edge |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Runtime | Akamai Edge Platform | N/A | `.service.yml` — technology field: `Akamai CDN` |
| Management UI | Akamai Control Center | N/A | `.service.yml` — dashboard URL: `https://control.akamai.com` |
| Protocol | HTTPS | N/A | `models/relations.dsl` — relationship protocol |

### Key Libraries

> Not applicable — this service is a managed SaaS configuration unit, not a compiled application. There are no application-level libraries or dependency manifests.
