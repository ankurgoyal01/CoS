---
service: "corpAD"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Identity and Access Management"
platform: "Continuum"
team: "Syseng"
status: active
tech_stack:
  language: "N/A"
  language_version: "N/A"
  framework: "Active Directory"
  framework_version: "N/A"
  runtime: "Windows Server Active Directory"
  runtime_version: "N/A"
  build_tool: "N/A"
  package_manager: "N/A"
---

# corpAD Overview

## Purpose

corpAD is Groupon's Corporate Active Directory service for the `group.on` domain. It provides centralized employee identity management, authentication, and LDAP directory services for internal systems and infrastructure. The service acts as the authoritative identity source for corporate users, groups, and computer accounts across all Groupon data centers, importing employee records from Workday and exposing them to internal consumers via LDAP VIPs.

## Scope

### In scope

- Managing the `group.on` Active Directory domain and its domain controllers
- Providing LDAP and LDAPS access to internal consumers via per-colo VIPs (`corpldap1.<colo>`)
- Importing and synchronizing employee identity data from Workday (HR system of record)
- Maintaining user accounts, security groups, and organizational unit structure
- Supporting authentication for internal services that rely on corporate identity (e.g., killbill-subscription-programs-plugin using `ldaps://corpldap1:636`)
- Supporting VPN access control via corporate directory integration (e.g., openvpn-config)

### Out of scope

- Consumer-facing authentication (handled by Okta or application-layer auth)
- Application-level authorization logic (handled by consuming services)
- Groupon customer identity (handled by separate commerce identity services)
- Public API exposure (all endpoints are internal-only, behind VIPs)

## Domain Context

- **Business domain**: Identity and Access Management
- **Platform**: Continuum
- **Upstream consumers**: killbill-subscription-programs-plugin (LDAP authentication), openvpn-config (corporate directory integration), ARQWeb (AD group membership management), and other internal services requiring corporate identity lookups
- **Downstream dependencies**: Workday (cloud HR platform — source of employee identity data)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | rwetterich (Syseng team) |
| Team | Syseng — rdafonseca, palvarezbarreir, kbobba, bperkins, rwetterich, jpriko |
| SRE Contact | it-sys-engineering@groupon.pagerduty.com |
| Team Email | syseng@groupon.com |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Directory Service | Active Directory / LDAP | N/A | `.service.yml` — `title: corpad - Active Directory/LDAP` |
| Protocol | LDAP / LDAPS | Port 636 (LDAPS) | `killbill-staging.properties` — `ldaps://corpldap1:636` |
| VIP / Load Balancing | Internal VIPs | N/A | `.service.yml` — `base_urls.internal: https://corpldap1.<colo>` |

### Key Libraries

> Not applicable — corpAD is an infrastructure service (Active Directory domain controllers). It does not expose a software codebase with library dependencies. Configuration and management are performed via Windows Server tooling and GPO.
