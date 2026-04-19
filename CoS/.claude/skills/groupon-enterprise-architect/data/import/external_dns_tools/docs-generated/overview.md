---
service: "external_dns_tools"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Network Infrastructure / External DNS"
platform: "Continuum"
team: "Infrastructure Engineering"
status: active
tech_stack:
  language: "Python"
  language_version: "2.x"
  framework: "Ansible"
  framework_version: "1.x (legacy)"
  runtime: "BIND"
  runtime_version: "9.9.5"
  build_tool: "Ansible playbooks"
  package_manager: "epkg (internal)"
---

# External DNS Overview

## Purpose

External DNS (also known as Public DNS) is the infrastructure layer that provides authoritative DNS name resolution for all of Groupon's externally-facing domains. It runs BIND nameservers on EC2 instances that act as primary data sources; Akamai EdgeDNS pulls zone data from these servers via zone transfers (AXFR/IXFR) and handles all actual serving of public DNS queries. The repository also contains tooling (`dns_deploy.py`) that automates the operator workflow for packaging and deploying updated DNS zone configurations to the BIND servers.

## Scope

### In scope

- Running authoritative BIND 9 nameservers that hold zone files for all public Groupon domains
- Accepting zone transfer requests from Akamai EdgeDNS Zone Transfer Agents
- Providing tooling (`dns_deploy.py` / `dns_deploy.yml`) to package, validate, and deploy updated zone configurations to BIND servers across test and production environments
- Validating zone file syntax using `named-checkconf` before deployment
- Managing SOA serial number monotonicity across zone changes
- Alerting on zone transfer failures and zone expiry via Akamai-configured alerts

### Out of scope

- Actual serving of public DNS queries to end users (handled entirely by Akamai EdgeDNS)
- Storage and authoring of raw zone file content (owned by `ops-ns_public_config` GitHub repo)
- Internal/private DNS resolution (separate infrastructure)
- Domain registration and ownership management (handled by SOC/external domain teams)

## Domain Context

- **Business domain**: Network Infrastructure / External DNS
- **Platform**: Continuum (Infrastructure Engineering)
- **Upstream consumers**: Akamai EdgeDNS Zone Transfer Agents (the only consumer of zone data from the BIND masters)
- **Downstream dependencies**: `ops-ns_public_config` GitHub repo (zone file source), `ops-config` repo (hostclass configuration), internal config service (`http://config/`)

## Stakeholders

| Role | Description |
|------|-------------|
| Infrastructure Engineering (team owner) | Owns and operates the BIND servers and deploy tooling; team owner is `blopulisa`, members include `bsingh` |
| CorpIT / SysEng | Handles deployment of DNS configuration changes per the SOP |
| Service Engineering On-call | Escalation contact when capacity additions are required |
| Akamai (external) | Provides the EdgeDNS CDN layer that serves all external DNS queries; contact `groupon-support@akamai.com` for critical escalations |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 2.x | `tools/dns_deploy.py` — uses `print` statements and `raw_input` (Python 2 syntax) |
| Automation framework | Ansible | 1.x (legacy) | `tools/dns_deploy.yml`, `tools/test_branch.yml` — uses `sudo:` key (deprecated in Ansible 2+) |
| DNS server | BIND (named) | 9.9.5 | `tools/dns_deploy.yml` — installs `bind-9.9.5p1.tar.gz` from internal config service |
| Config templating | Jinja2 | — | `tools/dns_deploy.py` — imported as `jinja2` |
| Config parsing | PyYAML | — | `tools/dns_deploy.py` — imported as `yaml`; used for `dns_deploy_config.yml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `ansible.playbook` | 1.x | scheduling | Runs Ansible playbooks programmatically from Python |
| `ansible.inventory` | 1.x | scheduling | Parses and renders the `dns_public_inventory` host file |
| `ansible.callbacks` | 1.x | logging | Provides stdout/stats callbacks during playbook execution |
| `jinja2` | — | templating | Template rendering for configuration generation |
| `yaml` (PyYAML) | — | serialization | Parses `dns_deploy_config.yml` configuration |
| `subprocess.Popen` | stdlib | — | Runs shell commands for git operations and `whoami` |
| `tempfile.NamedTemporaryFile` | stdlib | — | Creates temporary Ansible inventory files at runtime |
