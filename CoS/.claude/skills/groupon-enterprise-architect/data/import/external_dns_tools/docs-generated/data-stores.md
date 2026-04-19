---
service: "external_dns_tools"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "ops-ns_public_config"
    type: "git-repository"
    purpose: "Authoritative source of DNS zone files and named.conf configuration"
---

# Data Stores

## Overview

External DNS does not own a traditional database or cache. Its authoritative data store is the `ops-ns_public_config` GitHub repository, which contains flat-text BIND zone files and `named.conf` / `zones.conf` configuration. On each deploy, this repository is cloned, packaged into a versioned tarball, and installed onto the BIND master EC2 instances. Backup of zone data is provided by GitHub's standard backup mechanisms.

## Stores

### ops-ns_public_config Git Repository (`ops-ns_public_config`)

| Property | Value |
|----------|-------|
| Type | git-repository (flat-text BIND zone files) |
| Architecture ref | `externalDnsConfigRepo_unk_3c2e` |
| Purpose | Authoritative source of all DNS zone file content and BIND server configuration |
| Ownership | External (owned by `prod-ops` team; `external_dns_tools` deploy tooling reads it read-only) |
| Migrations path | Not applicable — changes made via PR to `ops-ns_public_config`; serial numbers incremented manually |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `etc/zones/<domain>.zone` | Individual DNS zone files containing A, CNAME, MX, and SOA records for each public domain | SOA serial number, A records, CNAME records |
| `etc/named.conf` | BIND master configuration — lists zones, their file paths, and transfer permissions | zone name, `type master`, `file`, `allow-transfer` |
| `etc/zones.conf` | Supplementary zone include file referenced by `named.conf` | zone declarations |
| `pkg/ns_public_config-<timestamp>.tar.gz` | Versioned package tarball created during deploy; contains `config/` and `etc/` subtrees | timestamp-versioned package |

#### Access Patterns

- **Read**: Deploy tooling clones via `git clone git@github:prod-ops/ops-ns_public_config.git` with `depth=1`; then `git reset --hard origin/master && git pull --rebase` to sync
- **Write**: Operators create PRs to `ops-ns_public_config` with zone file changes and incremented SOA serial numbers; the deploy tool tags commits as `ns_public_config-<timestamp>` and pushes the tag upstream
- **Indexes**: Not applicable — flat-text file storage; zones referenced by filename and zone name in `named.conf`

### BIND Server On-Disk Zone Files (runtime store)

| Property | Value |
|----------|-------|
| Type | local filesystem (BIND zone files) |
| Architecture ref | `externalDnsMasters` |
| Purpose | Runtime copy of zone data served to Akamai ZTAs via zone transfer |
| Ownership | owned (on each BIND master EC2 instance) |
| Migrations path | Managed by Ansible playbook (`dns_deploy.yml`) — deploys via `epkg ns_public_config-<timestamp>` |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `/usr/local/etc/named.conf` | Active BIND master configuration | zone file paths, transfer ACLs |
| `/usr/local/etc/zones.conf` | Active supplementary zones include | zone declarations |
| `/usr/local/etc/zones/` | Directory of active zone files for all served domains | per-domain zone files |

#### Access Patterns

- **Read**: BIND daemon reads zone files at startup and after reload; `named-checkconf -z` validates them during QA steps
- **Write**: Ansible playbook installs new `ns_public_config` package via `epkg`, then triggers `/var/tmp/roll` to reload BIND with updated configuration
- **Indexes**: Not applicable

## Caches

> No evidence found in codebase. No dedicated caching layer is used. BIND's internal zone cache is managed by the daemon itself.

## Data Flows

Zone file changes flow from the `ops-ns_public_config` git repository (authored by operators via PR) through the deploy tooling (packaged as versioned tarballs) onto the BIND master EC2 instances (installed via `epkg` and activated by rolling the hostclass). Once the BIND masters load the updated zones, Akamai ZTAs detect the incremented SOA serial and initiate zone transfers to propagate the changes to Akamai EdgeDNS, which then serves updated records to end users. See [DNS Deploy Flow](flows/dns-deploy.md) for the detailed sequence.
