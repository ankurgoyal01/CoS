---
service: "corpAD"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "corpAdDirectoryService"
    type: "active-directory"
    purpose: "Corporate identity directory — users, groups, organizational units, and computer accounts for the group.on domain"
---

# Data Stores

## Overview

corpAD's primary data store is the Active Directory database (NTDS.dit) replicated across domain controllers in each colo. This is not a separately deployed application database but rather the directory information tree (DIT) maintained natively by Active Directory Domain Services. There are no external relational databases, caches, or object stores owned by this service.

## Stores

### Active Directory Domain (NTDS.dit) (`corpAdDirectoryService`)

| Property | Value |
|----------|-------|
| Type | active-directory (LDAP-accessible directory database) |
| Architecture ref | `corpAdDirectoryService` |
| Purpose | Stores corporate user accounts, security groups, organizational units, computer accounts, and group policies for the `group.on` domain |
| Ownership | owned |
| Migrations path | N/A — directory schema managed via Active Directory Schema MMC snap-in and Group Policy Objects |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| User objects (`user` objectClass) | Represent individual employee accounts | `sAMAccountName`, `userPrincipalName`, `displayName`, `mail`, `memberOf`, `employeeID` |
| Group objects (`group` objectClass) | Security and distribution groups used for access control and email distribution | `cn`, `member`, `groupType`, `managedBy` |
| Organizational units (`organizationalUnit`) | Structural containers for users, groups, and computers | `ou`, `distinguishedName` |
| Computer objects (`computer` objectClass) | Corporate-managed computer accounts | `cn`, `dNSHostName`, `operatingSystem` |

#### Access Patterns

- **Read**: LDAP `searchRequest` operations against the directory using filters such as `(sAMAccountName=<username>)` or `(memberOf=<group-dn>)`. Used by consuming services for authentication and group membership queries.
- **Write**: LDAP `modifyRequest` operations to update group membership (e.g., adding/removing users from security groups). Typically performed by access governance tooling (ARQWeb).
- **Indexes**: Active Directory maintains its own indexes on key attributes (`sAMAccountName`, `objectGUID`, `objectSid`, `mail`) for efficient lookup. Index configuration is managed by AD Domain Services internally.

## Caches

> No evidence found in codebase. corpAD does not own a separate caching layer. Active Directory domain controllers use an in-memory database cache natively but this is infrastructure-level and not application-configurable.

## Data Flows

Employee identity data flows into the directory from Workday via a scheduled import process. corpAD pulls authoritative HR data (employee records, org hierarchy) from Workday and creates or updates corresponding user objects in the Active Directory domain. Changes in the directory are then replicated across domain controllers in all three production colos (snc1, dub1, sac1) via Active Directory replication.
