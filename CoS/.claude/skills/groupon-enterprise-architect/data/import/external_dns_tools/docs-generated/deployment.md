---
service: "external_dns_tools"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "vm"
environments: ["dev", "staging", "production"]
---

# Deployment

## Overview

External DNS runs on EC2 instances (not containerized) managed via a custom internal hostclass system (`ops-config`). Zone configuration is packaged as versioned tarballs and installed with an internal package manager (`epkg`). BIND is restarted on each host by running `/var/tmp/roll`. The deploy tooling (`dns_deploy.py`) is an interactive Python CLI that orchestrates the full end-to-end deployment process from an operator utility server.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | EC2 instances running BIND directly on the OS |
| Orchestration | Internal hostclass system (ops-config) | Hostclass tags (`ns_public-<timestamp>`) assign package versions to hosts; changes queued via `ops-config-queue` |
| Package management | epkg (internal) | Installs versioned `ns_public_config-<timestamp>.tar.gz` tarballs; also installs `bind-9.9.5p1` |
| Config distribution | Internal config service (`http://config/`) | Stores and distributes `ns_public_config` package tarballs to BIND servers |
| Load balancer | AWS ELB | Production `us-west-1`: ELB with IPs `54.215.1.179`, `54.219.119.246`; Production `us-west-2`: ELB with IPs `44.238.130.191`, `44.226.70.201`, `34.210.48.108` |
| CDN / DNS serving | Akamai EdgeDNS | Receives zone transfers from BIND masters; all public DNS queries served by Akamai |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Dev/Staging | Testing zone config changes before production deployment | `netops-dev us-west-2` | `external-dns-master1.netops-dev.us-west-2.aws.groupondev.com` |
| Production us-west-1 | Primary production BIND masters | `netops-prod us-west-1` | `external-dns-master1.netops.us-west-1.aws.groupondev.com`, `external-dns-master2.netops.us-west-1.aws.groupondev.com` |
| Production us-west-2 | Secondary production BIND masters | `netops-prod us-west-2` | `external-dns-master1.netops.us-west-2.aws.groupondev.com`, `external-dns-master2.netops.us-west-2.aws.groupondev.com` |

### Ansible inventory host groups

| Group | Hosts |
|-------|-------|
| `[local]` | `localhost` (deploy tool runs here) |
| `[test]` | `ns-public1-staging.snc1`, `ns-public2-staging.snc1` |
| `[production]` | `ns-public1.dub1`, `ns-public2.dub1`, `ns-public1.snc1`, `ns-public3.snc1`, `ns-public1.sac1`, `ns-public2.sac1` |

## CI/CD Pipeline

- **Tool**: Manual operator-driven deployment (no automated CI/CD pipeline for zone deployment)
- **Config**: `tools/dns_deploy.py` + `tools/dns_deploy.yml` (Ansible playbook)
- **Trigger**: Manual — operator runs `python dns_deploy.py` from a designated utility server

### Pipeline Stages

1. **Repo sync**: Clones or syncs `ops-ns_public_config` and `ops-config` repos to the operator's working directory (`/var/groupon/$USER/`)
2. **Package creation**: Creates a versioned tarball `ns_public_config-<timestamp>.tar.gz` from `config/` and `etc/` directories using GNU tar
3. **Local validation**: Installs `bind-9.9.5p1` and `ns_public_config-<timestamp>` packages locally; runs `named-checkconf -z` to validate all zone file syntax; collects domain/serial list
4. **Package upload**: Uploads the validated tarball to the internal config service via `curl -s --upload-file ... http://config/package/`
5. **Hostclass tagging**: Adds the new `ns_public_config-<timestamp>` package to the `ns_public` hostclass in `ops-config`; creates `ns_public-<timestamp>` git tag; assigns the new tag to test servers
6. **Config queue push (test)**: Pushes `ops-config` changes via `ops-config-queue`; polls the config service until the `ns_public-<timestamp>` hostclass is reported for all test hosts
7. **Test server roll**: SSHes to `[test]` hosts and runs `/var/tmp/roll` to apply the new hostclass; runs `named-checkconf` and QA `dig` assertions on each test host
8. **Serial verification**: Compares SOA serials between production (`@ns-public1.snc1`) and staging (`@ns-public1-staging.snc1`) to confirm staging serials are not behind
9. **Config queue push (production)**: Assigns the hostclass to production servers; pushes to ops-config; polls config service for all production hosts
10. **Production server roll**: SSHes to `[production]` hosts and runs `/var/tmp/roll`; runs `named-checkconf` and QA assertions on each production host

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual capacity addition only (must be performed by Systems Engineering) | Contact SRE on-call to add capacity |
| Memory | Not configured via this repo | N/A |
| CPU | Not configured via this repo | N/A |

## Resource Requirements

> Deployment configuration managed externally. EC2 instance sizing for BIND masters is not specified in this repository. Since Akamai is the sole consumer and zone transfers are infrequent, load on the BIND servers is minimal by design.
