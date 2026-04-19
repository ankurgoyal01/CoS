---
service: "external_dns_tools"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["externalDnsMasters", "externalDnsDeployTool"]
---

# Architecture Context

## System Context

External DNS sits at the boundary between Groupon's internal infrastructure and the public internet. The BIND master servers receive zone file updates from operators (via the deploy tooling) sourced from the `ops-ns_public_config` configuration repository. Akamai EdgeDNS Zone Transfer Agents poll the BIND masters and perform zone transfers (AXFR/IXFR) to synchronize DNS records. Akamai then serves all external DNS queries on behalf of Groupon, meaning the BIND servers are never exposed directly to end-user query traffic. This service lives within the `continuumSystem` software system in the Groupon architecture model.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| External DNS Masters (BIND) | `externalDnsMasters` | Backend service | BIND | 9.9.5 | Authoritative DNS master servers that hold public zone files and provide zone transfer data to Akamai EdgeDNS |
| External DNS Deploy Tooling | `externalDnsDeployTool` | Operator tool | Python / CLI / Ansible | Python 2.x / Ansible 1.x | Scripts and Ansible playbooks used by operators to package, validate, and deploy updated DNS zone configurations to the BIND masters |

## Components by Container

### External DNS Masters (`externalDnsMasters`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| BIND named daemon | Loads zone files from `named.conf` and `zones.conf`; answers zone transfer requests from Akamai ZTAs | BIND 9 (named) |
| Zone configuration files | Flat-text DNS zone files (A, CNAME, SOA records, etc.) sourced from `ops-ns_public_config` | BIND zone file format |
| named.conf / zones.conf | Master configuration controlling which zones are served and from which paths | BIND named.conf |

### External DNS Deploy Tooling (`externalDnsDeployTool`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `dns_deploy.py` | Interactive CLI menu for operators; manages hostclass selection, triggers Ansible playbook runs | Python 2 |
| `dns_deploy.yml` | Ansible playbook that orchestrates the full deploy: clones repos, packages zone configs, validates with `named-checkconf`, uploads to config service, rolls test then production servers | Ansible 1.x |
| `test_branch.yml` | Ansible playbook for testing an in-progress zone config branch on staging servers before official packaging | Ansible 1.x |
| `dns_deploy_config.yml` | Operator-editable configuration file: git remotes, working directory, host groups, QA test records, proxy settings | YAML |
| `dns_public_inventory` | Ansible inventory file declaring `[local]`, `[test]`, and `[production]` host groups | Ansible INI inventory |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `externalDnsDeployTool` | `externalDnsConfigRepo_unk_3c2e` (`ops-ns_public_config`) | Clones and reads zone configuration source files | git (SSH) |
| `externalDnsDeployTool` | ops-config repo | Reads/writes hostclass tags; queues config changes via `ops-config-queue` | git (SSH) / internal OCQ tool |
| `externalDnsDeployTool` | internal config service (`http://config/`) | Uploads packaged `ns_public_config-*.tar.gz` tarballs; polls for hostclass propagation | HTTP |
| `externalDnsDeployTool` | `externalDnsMasters` | Triggers `/var/tmp/roll` to apply new hostclass on BIND servers | SSH (via Ansible) |
| `externalDnsMasters` | `akamaiEdgeDns_unk_0b6c` (Akamai EdgeDNS) | Provides zone transfers (AXFR/IXFR) to Akamai Zone Transfer Agents | DNS zone transfer (TCP 53) |

## Architecture Diagram References

- System context: `contexts-externalDnsTools`
- Container: `containers-externalDnsTools`
- Component: `components-externalDnsTools`
