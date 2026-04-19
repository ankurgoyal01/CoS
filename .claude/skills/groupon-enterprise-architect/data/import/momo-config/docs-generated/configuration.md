---
service: "momo-config"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, lua-config-module]
---

# Configuration

## Overview

All MTA cluster configuration is file-based. Each cluster role has its own directory under `eu/clusters/<role>/momentum/conf/default/`. The primary configuration entry point is `ecelerity.conf`, which includes modular sub-configuration files. Lua policy scripts load runtime parameters from the shared `policy/groupon_config.lua` module. No external config stores (Consul, Vault, Helm values) are evidenced in the repository. Environment differentiation (lab vs. stable) is controlled by the `groupon_config.environment` value set in each cluster's `groupon_config.lua`.

## Environment Variables

> No evidence found in codebase. The Ecelerity MTA runtime does not use environment variables for configuration; all parameters are supplied via `ecelerity.conf` file directives and Lua policy modules.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `groupon_config.environment` | Controls environment-specific behavior: `"lab"` suppresses debug output; `"stable"` enables debug logging, message routing module, and sink routing for non-production domains | `"lab"` (eu/email cluster) | per-cluster |
| `adaptive_enabled` | Enables adaptive delivery throttle and suspension on outbound clusters | `true` (email, trans, smtp); `false` (inbound) | per-cluster |
| `groupon_config.log_samples` | When true, enables expensive per-type message sampling to `/var/log/ecelerity/inbound_samples/` | not set (disabled) | inbound cluster |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `eu/clusters/email/momentum/conf/default/ecelerity.conf` | Ecelerity conf | Main configuration for MTA Email Cluster: TLS, threading, adaptive, bounce/relay domains, logging, scripts |
| `eu/clusters/trans/momentum/conf/default/ecelerity.conf` | Ecelerity conf | Main configuration for MTA Trans Cluster: TLS, threading, adaptive, bounce/relay domains, logging, scripts |
| `eu/clusters/inbound/momentum/conf/default/ecelerity.conf` | Ecelerity conf | Main configuration for MTA Inbound Cluster: threading, bounce/relay domains, inbound logging, scripts |
| `eu/clusters/smtp/momentum/conf/default/ecelerity.conf` | Ecelerity conf | Main configuration for MTA SMTP Cluster: adaptive, SMTP AUTH, logging, scripts |
| `eu/clusters/*/momentum/conf/default/policy/groupon_config.lua` | Lua module | Shared runtime configuration: environment flag, sink host, discard domains, reject codes, binding group map, binding group distribution, admin addresses, redirects |
| `eu/clusters/email/momentum/conf/default/policy/outbound_policy.lua` | Lua module | Outbound policy for email cluster: recipient validation, binding assignment, header extraction, VERP construction, Gmail TLS enforcement |
| `eu/clusters/trans/momentum/conf/default/policy/outbound_policy.lua` | Lua module | Outbound policy for trans cluster: same as email cluster policy with trans-specific binding logic |
| `eu/clusters/inbound/momentum/conf/default/policy/inbound_policy.lua` | Lua module | Inbound classification policy: bounce/FBL/unsubscribe parsing, classification, CSV/jlog writing, message discard |
| `eu/clusters/smtp/momentum/conf/default/policy/smtp_policy.lua` | Lua module | SMTP cluster ingress policy: sender/recipient guards, routing controls |
| `eu/clusters/email/momentum/conf/default/includes/dkim.conf` | Ecelerity conf | DKIM signing configuration: `opendkim` module, RSA-SHA256, selector `s2048d20190430`, relaxed canonicalization |
| `eu/clusters/email/momentum/conf/default/includes/domains.conf` | Ecelerity conf | Per-domain delivery profiles: static MX routes (walla.com), throttle overrides (qq.com, gmx.de, gmx.net, web.de) |
| `eu/clusters/email/momentum/conf/default/includes/adaptive_sweep.conf` | Ecelerity conf | Adaptive sweep configuration for email cluster |
| `eu/clusters/email/momentum/conf/default/includes/custom_loggers.conf` | Ecelerity conf | Four custom logger definitions (`custom_logger1`–`custom_logger4`): delivery, in-band bounce, transient failure, custom bounce log formats |
| `eu/clusters/email/momentum/conf/default/includes/dkim_certificates/domains.txt` | Text | List of domains with DKIM key material |
| `eu/clusters/*/momentum/conf/default/tls/` | PEM/CRT/KEY | TLS certificates and keys for inbound SMTP: DigiCert CA bundle, `grouponmail.com` key, `inbound-smtp-snc1_r_grouponmail_com` cert chain |
| `eu/clusters/email/momentum/conf/default/ecdb.conf` | Ecelerity conf | Ecelerity cluster database configuration (read-only include) |
| `eu/clusters/email/momentum/conf/global/msgc_server.conf` | Ecelerity conf | Message cluster server configuration for email cluster |
| `eu/clusters/inbound/momentum/conf/default/liveupdate.conf` | Ecelerity conf | Live update configuration for inbound cluster |
| `eu/clusters/inbound/momentum/conf/default/includes/bounce_domains.conf` | Ecelerity conf | Bounce domain declarations for inbound cluster |
| `eu/clusters/inbound/momentum/conf/default/includes/relay_domains.conf` | Ecelerity conf | Relay domain allowlist for inbound cluster |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `eu/clusters/email/momentum/conf/default/includes/smtp_passwd` | SMTP credential file for authenticated relay | File-based (Ecelerity credential store) |
| `eu/clusters/email/momentum/conf/default/tls/grouponmail.com.key` | TLS private key for grouponmail.com | File-based (repository) |
| `eu/clusters/email/momentum/conf/default/tls/inbound-smtp-snc1_r_grouponmail_com.*.key` | TLS private keys for inbound SMTP listener | File-based (repository) |
| `eu/clusters/email/momentum/conf/default/includes/dkim_certificates/s2048d20190430.key` | DKIM RSA private signing key | File-based (repository) |
| `eu/clusters/trans/momentum/conf/default/includes/giftcloud_passwd` | GiftCloud SMTP relay credential | File-based (repository) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Environment differentiation is achieved via the `groupon_config.environment` Lua variable set in each cluster's `groupon_config.lua`:

- **`"lab"`** (default in eu clusters): debug logging suppressed; `msys.extended.message_routing` not loaded; sink routing not applied; messages delivered normally
- **`"stable"`**: extended debug logging enabled (`print("DEBUG: ...")`); `msys.extended.message_routing` loaded for custom routing domain override; sink routing applied — non-`groupon.com`/`grouponfraud.com` recipient domains are redirected to `groupon_config.sink` (e.g., `mta-sink-stable.grpn-mta-stable.us-west-1.aws.groupondev.com`)

Key per-cluster configuration differences:

| Parameter | Email Cluster | Trans Cluster | Inbound Cluster | SMTP Cluster |
|-----------|--------------|---------------|-----------------|--------------|
| `adaptive_enabled` | `true` | `true` | `false` | `true` |
| `adaptive_rejection_rate_suspension_percentage` | `50` | `50` | N/A | `25` |
| `Message_Expiration` | `79201` s | `259200` s | `259200` s | `259200` s |
| `Generate_Bounces` | `false` | `false` | `false` | `true` |
| `Bounce_Domains` | `bounce.r.grouponmail.co.uk` | `bounce.r.grouponmail.co.uk` | per `bounce_domains.conf` | not configured |
| DKIM signing | enabled (`opendkim`) | enabled (`opendkim`) | not configured | not configured |
| Adaptive sweep | enabled | enabled | disabled | disabled |
