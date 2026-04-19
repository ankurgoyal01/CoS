---
service: "openvpn-config"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Information Security / Network Access"
platform: "Continuum"
team: "infosec@groupon.com"
status: active
tech_stack:
  language: "Python"
  language_version: "3"
  framework: "N/A"
  framework_version: ""
  runtime: "Python"
  runtime_version: "3"
  build_tool: "N/A"
  package_manager: "pip"
---

# OpenVPN Config (Cloud Connexa) Overview

## Purpose

OpenVPN Config is a Python automation toolset for managing Groupon's Zero Trust Network Access (ZTNA) solution — OpenVPN Cloud Connexa. It provides CLI scripts for user lifecycle management (deletion), and full backup and restore of all Cloud Connexa configuration entities (networks, IP services, applications, user groups, and access groups) via the Cloud Connexa REST API. It replaces Akamai Enterprise Application Access (EAA) as Groupon's remote access solution for internal employees.

## Scope

### In scope

- Authenticating with OpenVPN Cloud Connexa using OAuth 2.0 client credentials
- Exporting all Cloud Connexa entities (networks, routes, connectors, applications, IP services, user groups, access groups) to local JSON backup files
- Restoring entities from JSON backup files to a Cloud Connexa account
- Deleting individual user accounts from Cloud Connexa by email address
- Querying utility scripts: finding applications by domain, identifying IP services by subnet, listing access groups for users and applications
- Rate-limit-aware pagination when reading large entity sets from the Cloud Connexa API

### Out of scope

- Provisioning of VPN client software on employee devices
- End-user authentication flows (handled by Okta OIDC/SAML integration configured in Cloud Connexa)
- Corporate directory synchronisation (handled by the `corpad` dependency)
- DNS configuration of connector endpoints (handled by `aws_dns`)
- Network connector host provisioning (connectors are created as part of network restore, but host infrastructure is managed externally)

## Domain Context

- **Business domain**: Information Security / Network Access
- **Platform**: Continuum
- **Upstream consumers**: InfoSec engineers and NetOps operators running scripts manually or as scheduled jobs
- **Downstream dependencies**: OpenVPN Cloud Connexa API (`/api/beta/*`), Okta (identity provider), corpad (corporate directory), AWS DNS

## Stakeholders

| Role | Description |
|------|-------------|
| Owner | c_jdiaz — primary maintainer, infosec@groupon.com |
| InfoSec Team | infosec@groupon.com — operational users of backup/restore and user-lifecycle scripts |
| NetOps Team | Responsible for network connector infrastructure referenced in backup data |
| Security GChat | AAAAsHzYN9c — incident notification channel |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3 | `#!/bin/env python3` shebang in all scripts |
| HTTP client | requests | unversioned | `import requests` in `openvpn_api.py`, `restore_backup.py`, `delete_user.py` |
| Build tool | N/A | — | No build manifest present |
| Package manager | pip | — | Standard Python convention; `requirements.txt` not present in repo |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `requests` | unversioned | http-client | All HTTP calls to the OpenVPN Cloud Connexa REST API |
| `ipaddress` | stdlib | networking | Subnet containment checks in restore and query scripts |
| `json` | stdlib | serialization | Serialising/deserialising all backup JSON files |
| `os` | stdlib | config | Reading environment variables (`OPENVPN_API`, `OPENVPN_CLIENT_ID`, `OPENVPN_CLIENT_SECRET`) |
| `re` | stdlib | validation | Email address validation regex in `delete_user.py` |
| `time` | stdlib | scheduling | Rate-limit backoff sleep in `openvpn_api.py` |
| `sys` | stdlib | cli | Argument parsing and stderr logging across all CLI scripts |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
