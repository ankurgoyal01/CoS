---
service: "external_dns_tools"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

External DNS integrates with two external systems (Akamai EdgeDNS as the zone transfer consumer, and GitHub as the zone config data store) and three internal Groupon systems (the `ops-ns_public_config` config repo, the `ops-config` hostclass management repo, and the internal config service). All integrations are infrastructure-level rather than application API calls.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Akamai EdgeDNS | DNS zone transfer (AXFR/IXFR, TCP 53) | Zone transfer consumer — pulls zone data from BIND masters to serve public DNS | yes | `akamaiEdgeDns_unk_0b6c` |
| GitHub Enterprise (`github.groupondev.com`) | git over SSH | Source of `ops-ns_public_config` zone file repository and `ops-config` hostclass repo | yes | `externalDnsConfigRepo_unk_3c2e` |

### Akamai EdgeDNS Detail

- **Protocol**: DNS zone transfer (AXFR/IXFR over TCP port 53)
- **Base URL / SDK**: Akamai Luna control portal: `https://control.akamai.com`; EdgeDNS product (formerly FastDNS)
- **Auth**: Network firewall ACL — Akamai Zone Transfer Agent IPs must be permitted through the firewall in front of the BIND master EC2 instances
- **Purpose**: Akamai receives zone transfers from the BIND masters and uses them to serve all external DNS queries on behalf of Groupon. The five public ELB IPs (`54.215.1.179`, `54.219.119.246`, `44.238.130.191`, `44.226.70.201`, `34.210.48.108`) are configured in Akamai EdgeDNS for each public domain
- **Failure mode**: If zone transfers fail, Akamai continues serving the previously cached DNS records indefinitely. This means end-user DNS resolution is not immediately impacted, but Groupon loses the ability to make DNS changes propagate to users. A `Failed Zone Transfer` alert fires after ~6-9 minutes of consecutive failure
- **Circuit breaker**: Not applicable — BIND serves zone transfers passively; no application-level circuit breaker exists

### GitHub Enterprise Detail

- **Protocol**: git over SSH (`git@github.groupondev.com`)
- **Base URL / SDK**: `git@github:prod-ops/ops-ns_public_config.git`, `git@git:ops-config`
- **Auth**: SSH key-based git authentication
- **Purpose**: `ops-ns_public_config` stores the authoritative zone files; `ops-config` manages hostclass definitions and server assignments. The deploy tool clones and syncs both repos during each deployment
- **Failure mode**: Deploy is blocked if either repo is unreachable; operators must resolve git connectivity before proceeding
- **Circuit breaker**: Not applicable — git operations fail fast with error output

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Internal config service (`http://config/`) | HTTP (curl) | Receives uploaded `ns_public_config-<timestamp>.tar.gz` package tarballs; provides package download for servers; serves hostclass propagation status | internal |
| ops-config repo | git + `ops-config-queue` (OCQ) tool | Hostclass management — stores which `ns_public-<timestamp>` tag each BIND server should run; changes queued via `./bin/ops-config-queue -v -ocq` | internal |
| `ops-ns_public_config` repo | git (SSH) | Zone file source — all DNS zone content is authored and version-controlled here | `externalDnsConfigRepo_unk_3c2e` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Akamai EdgeDNS Zone Transfer Agents | DNS AXFR/IXFR (TCP 53) | Pulls zone data from BIND masters to populate Akamai's authoritative DNS serving infrastructure |

> Upstream consumers are tracked in the central architecture model. Akamai EdgeDNS is the sole consumer of data produced by this service.

## Dependency Health

- **Akamai EdgeDNS**: Health monitored via Akamai Luna alert dashboard (`Configure -> Alerts -> FastDNS`). Three alerts configured: `syseng_fastdns_expired_zone` (zone expiry), `syseng_fastdns_failed_zonetransfer` (critical — all ZTAs failing), `syseng_fastdns_soa_ahead` (serial regression). Alert delay is 6-9 minutes from condition onset.
- **Internal config service**: Deploy playbook polls `http://config.<dc>/host/<hostname>` in a retry loop (up to 500 retries, 2-second delay) to confirm hostclass propagation before rolling each server group.
- **ops-config repo**: The `ops-config-queue` (`./bin/ops-config-queue -v -ocq`) push step retries up to 10 times with a 5-second delay on failure; manual recovery involves pulling the latest repo state and re-running `ops-config-queue` before re-selecting the hostclass in `dns_deploy.py`.
