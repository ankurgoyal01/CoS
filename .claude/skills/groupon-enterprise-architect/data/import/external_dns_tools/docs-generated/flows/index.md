---
service: "external_dns_tools"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for External DNS.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [DNS Zone Deploy](dns-deploy.md) | batch | Manual operator action via `dns_deploy.py` | Full end-to-end deployment of updated DNS zone configurations from `ops-ns_public_config` to BIND master servers and propagation to Akamai EdgeDNS |
| [Zone Transfer to Akamai](zone-transfer.md) | event-driven | SOA serial increment detected by Akamai ZTA | Akamai EdgeDNS Zone Transfer Agents detect an updated SOA serial and pull zone data from BIND masters |
| [DNS Change PR and Serial Management](dns-change-pr.md) | synchronous | Operator initiates a zone file change request | Operator workflow for submitting, reviewing, and preparing a DNS change PR in `ops-ns_public_config` with correct SOA serial numbers |
| [Branch Testing (Test Branch Flow)](branch-test.md) | batch | Manual operator action via `dns_deploy.py` option `t` | Tests a draft zone config branch on staging BIND servers before official packaging and deployment |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The [DNS Zone Deploy](dns-deploy.md) flow spans `externalDnsDeployTool`, the internal config service, the `ops-config` repo, and the `externalDnsMasters` containers. The [Zone Transfer to Akamai](zone-transfer.md) flow spans `externalDnsMasters` and `akamaiEdgeDns_unk_0b6c` (external). Both flows are captured in the `dynamics.dsl` architecture view for `external_dns_tools`.
