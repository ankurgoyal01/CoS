---
service: "ORR"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumOrrAuditToolkit"]
---

# Architecture Context

## System Context

The ORR Audit Toolkit sits within the **Continuum Platform** (`continuumSystem`) as an internal operator-facing toolset. It has no inbound callers — it is exclusively invoked by SOC engineers or ORR reviewers from a Linux host (e.g., `dev1.snc1`). Outbound, it reads production host and monitor configuration from the `opsConfigRepository`, validates service identities against `servicePortal`, retrieves NetOps load balancer configs and script version metadata from `rawGithubContent`, and looks up VIP SNMP OID metadata from `lbmsApi`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| ORR Audit Toolkit | `continuumOrrAuditToolkit` | CLI Toolkit | Bash and Python scripts | N/A | Repository of operational readiness audit scripts for host/VIP monitoring and config hygiene checks |

## Components by Container

### ORR Audit Toolkit (`continuumOrrAuditToolkit`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `hostsWithoutServiceAudit` | Finds host YAML files in `ops-config/hosts` missing `subservices` mappings | Python 3.7 + PyYAML |
| `hostNotifyAuditByService` | Audits host-level monitor notify recipients (`notify`, `notify_under_monitors`, `notify_host`) for a specific service | Bash |
| `vipNotifyAuditByService` | Audits VIP-level monitor notify recipients for a specific service, traversing host-to-service-group-to-VIP relationships | Bash |
| `monitorRecipientsAuditAllServices` | Builds fleet-wide reports of non-pageable monitor recipients across all production hosts and VIPs | Bash |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOrrAuditToolkit` | `opsConfigRepository` | Reads production host and monitor configuration data; pulls latest config state via `git pull` | git / filesystem |
| `continuumOrrAuditToolkit` | `servicePortal` | Validates service identities and confirms service is registered before auditing | HTTP REST (`http://service-portal-vip.snc1`) |
| `continuumOrrAuditToolkit` | `rawGithubContent` | Fetches script version metadata and NetOps load balancer configs for VIP resolution | HTTPS (`https://raw.github.groupondev.com`) |
| `continuumOrrAuditToolkit` | `lbmsApi` | Retrieves VIP SNMP OID metadata used to correlate VIPs against `lbmon` config files | HTTP REST (`http://lbmsv2-vip.snc1`) |
| `hostNotifyAuditByService` | `vipNotifyAuditByService` | Shares host-level ORR monitoring context | internal |
| `monitorRecipientsAuditAllServices` | `hostNotifyAuditByService` | Implements related host notify checks in bulk mode | internal |
| `monitorRecipientsAuditAllServices` | `vipNotifyAuditByService` | Implements related VIP notify checks in bulk mode | internal |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumOrrAuditToolkit`
- Dynamic flow: `dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow`
