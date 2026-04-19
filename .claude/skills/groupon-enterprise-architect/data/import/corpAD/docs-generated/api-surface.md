---
service: "corpAD"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [ldap, ldaps]
auth_mechanisms: [ldap-bind, kerberos]
---

# API Surface

## Overview

corpAD does not expose an HTTP/REST API. Its primary interface is LDAP and LDAPS, accessed by internal services via per-colo VIP hostnames. Consumers bind to the directory using service account credentials (LDAP bind DN and password) and perform standard LDAP operations: search, compare, add, modify, and delete. All endpoints are internal-only and not reachable from the public internet.

## Endpoints

### LDAP / LDAPS Access Points

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| LDAP | `ldap://corpldap1.<colo>:389` | Standard LDAP directory access (internal only) | LDAP bind (DN + password) |
| LDAPS | `ldaps://corpldap1.<colo>:636` | TLS-encrypted LDAP directory access | LDAP bind (DN + password) |
| HTTPS | `https://corpldap1.snc1` | Internal HTTPS VIP (snc1 production) | Service account / Kerberos |
| HTTPS | `https://corpldap1.dub1` | Internal HTTPS VIP (dub1 production) | Service account / Kerberos |
| HTTPS | `https://corpldap1.sac1` | Internal HTTPS VIP (sac1 production) | Service account / Kerberos |

### LDAP Operations

| Operation | Purpose |
|-----------|---------|
| Search (LDAP `searchRequest`) | Query users, groups, and organizational units by filter |
| Bind (`bindRequest`) | Authenticate a user or service account against the directory |
| Modify (`modifyRequest`) | Add or remove members from security groups (used by access provisioning) |
| Compare (`compareRequest`) | Verify attribute value (e.g., group membership check) |

## Request/Response Patterns

### Common headers

> Not applicable — LDAP is a binary protocol, not HTTP. Authentication is performed via the LDAP bind operation using a distinguished name (DN) and password.

### Error format

> Not applicable — LDAP responses use result codes defined in RFC 4511 (e.g., `0` = success, `49` = invalid credentials, `32` = no such object). Consuming applications translate these into application-level errors.

### Pagination

LDAP supports the Simple Paged Results control (RFC 2696) for returning large result sets in pages. Use of this control depends on the consuming application's LDAP client configuration.

## Rate Limits

> No rate limiting configured. corpAD operates as an internal infrastructure service. Throughput limits are governed by Active Directory domain controller capacity, not application-level rate limiting.

## Versioning

> Not applicable. LDAP protocol version 3 (LDAPv3, RFC 4511) is used. There is no application-level versioning scheme.

## OpenAPI / Schema References

> Not applicable. corpAD exposes LDAP, not an HTTP API. The directory schema is defined by the Active Directory schema (Microsoft AD DS schema). No OpenAPI spec or proto files exist in the repository.
