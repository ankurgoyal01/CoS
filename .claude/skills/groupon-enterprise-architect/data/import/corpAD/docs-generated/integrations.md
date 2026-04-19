---
service: "corpAD"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

corpAD has one explicit downstream dependency: Workday, the cloud HR platform that serves as the authoritative source of employee identity data. The service imports employee records from Workday on a scheduled basis. corpAD does not call any other internal Continuum services. Conversely, multiple internal services consume corpAD as an identity provider via LDAP/LDAPS. Known consumers are tracked in the central architecture model.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Workday | N/A (pull/sync) | Imports authoritative employee identity data into Active Directory | yes | `workday` |

### Workday Detail

- **Protocol**: Pull-based synchronization (exact protocol — API, SFTP, or SDK — not documented in repository; managed by Syseng team operations)
- **Base URL / SDK**: Workday cloud HR platform (external SaaS)
- **Auth**: Service account credentials (managed by Syseng operations team; details in Owners Manual on Confluence)
- **Purpose**: Workday is the HR system of record for Groupon employee data. corpAD imports employee records — including identity attributes, org hierarchy, and employment status — from Workday to keep the `group.on` Active Directory domain synchronized with the current employee roster. New hires receive AD accounts; terminations result in account deprovisioning.
- **Failure mode**: If the Workday sync fails, the Active Directory domain retains stale data. New hires may not receive accounts on schedule; terminated employees may retain access longer than intended. The Syseng team monitors sync jobs for failure.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

> No evidence found in codebase. corpAD does not depend on any other internal Continuum service.

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| killbill-subscription-programs-plugin | LDAPS (port 636) | Authenticates users against the corporate directory for subscription program operations |
| openvpn-config (OpenVPN Cloud Connexa) | LDAP / corporate directory integration | Consumes corporate directory for VPN user and group management |
| ARQWeb (access governance) | LDAP / LDAPS | Queries and updates AD group memberships for employee access request provisioning |

> Upstream consumers are tracked in the central architecture model. Additional consumers may exist that are not enumerated in the federated model.

## Dependency Health

corpAD operates as an infrastructure service. The Workday synchronization process is the only active outbound integration. Health of the sync is monitored via the Syseng SolarWinds dashboard (`https://uschi1vpwsw02.group.on/Orion/...`). There is no evidence of programmatic circuit breaker or retry logic in the architecture model; operational procedures are defined in the Owners Manual on Confluence and the Gears Document.
