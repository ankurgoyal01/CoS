---
service: "akamai"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Cyber Security / Product Security"
platform: "Continuum"
team: "Cyber Security"
status: active
tech_stack:
  language: "YAML"
  language_version: "N/A"
  framework: "Akamai Platform"
  framework_version: "N/A"
  runtime: "SaaS"
  runtime_version: "N/A"
  build_tool: "N/A"
  package_manager: "N/A"
---

# Akamai Product Security Overview

## Purpose

Akamai is Groupon's global product security platform that provides site performance and security controls across consumer and merchant platforms. It delivers Web Application Firewall (WAF) protection and bot management capabilities at the edge, enforcing security policies before requests reach Groupon's origin infrastructure. The service is managed as a third-party SaaS, with Groupon's Cyber Security team owning the configuration, operational contacts, and dashboard integration described in this repository.

## Scope

### In scope

- Web Application Firewall (WAF) rule management and enforcement for Groupon consumer and merchant traffic
- Bot management controls to detect and block malicious automated traffic
- Security analytics and visibility via Akamai Security Center dashboards
- Ownership and contact management for the Akamai account (team, mailing list, SRE notifications)
- Environment URL mapping for staging and production Akamai control-plane endpoints
- Dashboard integration linking Akamai Security Center views for incident investigation

### Out of scope

- CDN delivery configuration and property rules (owned by the `akamai-cdn` service)
- Origin-side application security (handled by individual application teams)
- Network-layer DDoS mitigation policies beyond WAF scope
- Akamai billing and procurement

## Domain Context

- **Business domain**: Cyber Security / Product Security
- **Platform**: Continuum
- **Upstream consumers**: Groupon consumer web traffic and merchant platform traffic routed through Akamai edge nodes; Cyber Security team SRE for incident response
- **Downstream dependencies**: Akamai SaaS control plane (`https://control.akamai.com`) for WAF configuration and security analytics

## Stakeholders

| Role | Description |
|------|-------------|
| Team Owner (c_anemeth) | Cyber Security team lead; primary escalation contact for Akamai security incidents |
| Team Members (c_jdiaz, c_wkura, c_pnowicki, sbhatt) | Cyber Security engineers responsible for WAF and bot management configuration |
| Mailing List (akamai@groupon.com) | Announcement list for interested parties |
| SRE Notify (infosec@groupon.com) | Emergency notification address for production security incidents |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Configuration format | YAML | N/A | `.service.yml` |
| Platform | Akamai (SaaS) | N/A | `.service.yml` |
| Runtime | Externally managed (Akamai cloud) | N/A | `.service.yml` |
| Build tool | N/A | N/A | No build system present |
| Package manager | N/A | N/A | No dependency manifest present |

### Key Libraries

> Not applicable — this repository contains only YAML service metadata and Structurizr architecture DSL. There are no application libraries or runtime dependencies.
