---
service: "momo-config"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Email Delivery / Mail Transfer"
platform: "Continuum"
team: "MTA"
status: active
tech_stack:
  language: "Lua"
  language_version: "5.1"
  framework: "Momentum (Ecelerity) MTA"
  framework_version: ""
  runtime: "Momentum (Ecelerity) MTA"
  runtime_version: ""
  build_tool: "pre-commit"
  package_manager: ""
---

# momo-config Overview

## Purpose

`momo-config` is the version-controlled configuration repository for Groupon's Momentum (Ecelerity) Mail Transfer Agent clusters deployed in AWS. It owns the complete Ecelerity configuration — `ecelerity.conf` files, Lua policy scripts, DKIM signing material, adaptive delivery rules, domain profiles, bounce classification overrides, and DNS zone definitions — for all MTA cluster roles. It exists to provide a single source of truth for MTA runtime behavior across outbound campaign mail, transactional mail, authenticated SMTP ingress, inbound response processing (bounces, FBLs, unsubscribes), suppression sink routing, and authoritative DNS.

## Scope

### In scope

- Ecelerity (`ecelerity.conf`) configuration for all cluster roles: email (outbound campaign), trans (transmission), inbound, inbound-internal, smtp, sink
- Lua policy scripts: outbound binding assignment, domain routing, header extraction/sanitization, inbound bounce/FBL/unsubscribe classification and logging
- DKIM signing configuration and key material (`opendkim`, selector `s2048d20190430`, RSA-SHA256)
- Adaptive delivery rules and sweep configuration (`adaptive_backstore_leveldb`, suspension thresholds)
- Per-domain throttle and connection profiles (`domains.conf`, per-ISP limits for qq.com, walla.com, gmx.de, etc.)
- Bounce domain and relay domain declarations (`Bounce_Domains`, `Relay_Domains`)
- Custom structured log definitions for delivery, bounce, FBL, and unsubscribe events
- Binding group mapping tables per locale/region (ae, au, be, ca, de, es, fr, gb, ie, it, nl, pl, uk, vc)
- Discard domain list (test/invalid domains)
- Authoritative DNS zone definitions for MTA response domains (`continuumMtaDnsService`)
- SMTP credential store for authenticated senders
- TLS configuration (GnuTLS, TLS 1.2+, DigiCert CA)
- Pre-commit hooks for Lua quality gates (LuaFormatter, Luacheck)

### Out of scope

- Email rendering, personalization, or templating (owned by upstream sending services)
- Subscriber list management and suppression database (owned by upstream email platform)
- Campaign scheduling and job orchestration
- Email analytics and reporting pipelines beyond log emission
- DNS infrastructure provisioning (only zone configuration is stored here)

## Domain Context

- **Business domain**: Email Delivery / Mail Transfer
- **Platform**: Continuum
- **Upstream consumers**: Groupon email platform (campaign/transactional senders), internal applications submitting via authenticated SMTP, external ISPs sending bounce/FBL responses to response domains
- **Downstream dependencies**: Remote recipient MX servers (public internet delivery), `loggingStack` (delivery/bounce/FBL log pipeline), `metricsStack` (throughput and delivery metrics), `tracingStack`

## Stakeholders

| Role | Description |
|------|-------------|
| MTA Operations | Owns cluster configuration, policy deployment, and deliverability tuning |
| Email Deliverability | Monitors sender reputation, adaptive delivery thresholds, and domain-specific rules |
| Email Platform Engineering | Upstream senders that inject mail via SMTP into the MTA clusters |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Policy language | Lua | 5.1 | `eu/clusters/*/momentum/conf/default/policy/*.lua` |
| MTA runtime | Momentum (Ecelerity) | — | `ecelerity.conf`, `.service.yml` title "Mail Transfer Agent" |
| Adaptive backstore | LevelDB | — | `adaptive_backstore_leveldb { path = "/opt/msys/leveldb/adaptive.leveldb" }` |
| DKIM signing | OpenDKIM module | — | `eu/clusters/email/momentum/conf/default/includes/dkim.conf` |
| TLS | GnuTLS | TLS 1.2+ | `TLS_Engine = "gnutls"; TLS_Protocols = "NORMAL:-VERS-TLS1.1:-VERS-TLS1.0"` |
| DNS | BIND | — | `continuumMtaDnsService` DSL container |
| Pre-commit tooling | LuaFormatter / Luacheck | — | `.pre-commit-config.yaml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `msys.base64` | Momentum built-in | serialization | Base64 encode/decode for policy scripts |
| `msys.pcre` | Momentum built-in | validation | PCRE regex matching/splitting in Lua policy |
| `msys.core` | Momentum built-in | message-client | Core message and context manipulation APIs |
| `msys.extended.message` | Momentum built-in | message-client | Extended message header/body manipulation |
| `msys.extended.vctx` | Momentum built-in | message-client | Validation context access |
| `msys.audit_series` | Momentum built-in | metrics | Rate-limiting audit series (IP/recipient auto-reply) |
| `msys.bounce` | Momentum built-in | message-client | Bounce classification engine |
| `msys.datasource` | Momentum built-in | db-client | Data source abstraction for Lua policy |
| `msys.rfc3464` | Momentum built-in | serialization | DSN (RFC 3464) parsing |
| `msys.extended.message_routing` | Momentum built-in | message-client | Custom routing domain override (stable env only) |
| `thread` | Momentum built-in | scheduling | Thread pool execution for log I/O |
| `msys.dumper` | Momentum built-in | logging | Debug message dumping |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
