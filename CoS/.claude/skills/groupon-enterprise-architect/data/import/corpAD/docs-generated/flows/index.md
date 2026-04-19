---
service: "corpAD"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for corpAD (Corporate Active Directory / LDAP).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Workday Employee Identity Sync](workday-employee-sync.md) | scheduled | Scheduled import job (Syseng-managed) | Imports authoritative employee records from Workday into the group.on Active Directory domain |
| [LDAP Authentication and Directory Query](ldap-authentication-query.md) | synchronous | Internal service issues LDAP bind + search request | A consuming service authenticates a user or queries directory attributes against the corporate LDAP VIP |
| [AD Group Membership Update](ad-group-membership-update.md) | synchronous | Access governance tool (ARQWeb) approves an access request | Updates Active Directory security group membership to grant or revoke employee access |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The Workday Employee Identity Sync flow spans `corpAdDirectoryService` and the external `workday` system. See [Workday Employee Identity Sync](workday-employee-sync.md).
- The AD Group Membership Update flow is typically triggered by ARQWeb (`continuumArqWebApp` / `continuumArqWorker`). See the ARQWeb access provisioning flow documentation for the full cross-service view.
