---
service: "corpAD"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["corpAdDirectoryService"]
---

# Architecture Context

## System Context

corpAD sits within the Continuum platform as a shared infrastructure service providing corporate identity and LDAP directory access for the `group.on` domain. It is consumed by internal Groupon services that require employee authentication or directory lookups. Its single upstream dependency is Workday (an external SaaS HR system), from which it imports authoritative employee identity data. Internal consumers — including VPN configuration automation, subscription billing plugins, and access governance tooling — connect to corpAD via LDAP/LDAPS using per-colo VIP hostnames (`corpldap1.<colo>`).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Corp AD / LDAP | `corpAdDirectoryService` | Directory Service | Active Directory / LDAP | N/A | Corporate Active Directory domain controllers and LDAP service (group.on) behind VIPs |

## Components by Container

### Corp AD / LDAP (`corpAdDirectoryService`)

> No evidence found in codebase. The architecture model declares no sub-components for this container. corpAD operates as a unified Active Directory domain with domain controllers per colo; internal component decomposition is not modeled.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `corpAdDirectoryService` | `workday` | Imports employee identity data | N/A (pull/sync from Workday HR API) |
| `openvpnConfigAutomation` | `corpAdDirectoryService` | Depends on corporate directory integration for VPN user/group management | LDAP / HTTPS |
| `killbill-subscription-programs-plugin` | `corpAdDirectoryService` | Authenticates users against corporate LDAP | LDAPS (port 636) |
| `continuumArqWebApp` / `continuumArqWorker` | `corpAdDirectoryService` | Queries and updates AD group memberships for access provisioning | LDAP / LDAPS |

## Architecture Diagram References

- System context: `contexts-corpAD`
- Container: `containers-corpAD`
- Component: `components-corpAD`
