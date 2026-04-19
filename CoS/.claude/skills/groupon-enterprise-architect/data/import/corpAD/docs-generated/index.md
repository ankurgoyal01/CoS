---
service: "corpAD"
title: "corpAD Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["corpAdDirectoryService"]
tech_stack:
  language: "N/A (infrastructure service)"
  framework: "Active Directory / LDAP"
  runtime: "Windows Server Active Directory"
---

# corpAD Documentation

corpAD is Groupon's Corporate Active Directory service, providing identity directory and LDAP access for the `group.on` domain. It serves as the central employee identity store, importing workforce data from Workday and exposing LDAP endpoints to internal consumers across all Groupon data centers.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | N/A (infrastructure service) |
| Framework | Active Directory / LDAP |
| Runtime | Windows Server Active Directory |
| Build tool | N/A |
| Platform | Continuum |
| Domain | Identity and Access Management |
| Team | Syseng (syseng@groupon.com) |
