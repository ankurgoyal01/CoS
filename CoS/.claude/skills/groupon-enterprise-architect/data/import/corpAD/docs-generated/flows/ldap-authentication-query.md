---
service: "corpAD"
title: "LDAP Authentication and Directory Query"
generated: "2026-03-03"
type: flow
flow_name: "ldap-authentication-query"
flow_type: synchronous
trigger: "Internal service issues LDAP bind and search request against the corporate LDAP VIP"
participants:
  - "corpAdDirectoryService"
architecture_ref: "dynamic-corpAD"
---

# LDAP Authentication and Directory Query

## Summary

This flow describes how internal Groupon services authenticate users and query directory attributes against the corpAD LDAP service. Consumers connect to the per-colo LDAP VIP (`corpldap1.<colo>`) using LDAPS on port 636, bind with a service account, and perform searches against the `group.on` directory. This pattern is used by services such as killbill-subscription-programs-plugin for user authentication, ARQWeb for group membership queries, and openvpn-config for VPN user/group lookups.

## Trigger

- **Type**: api-call
- **Source**: Internal Groupon service (e.g., killbill-subscription-programs-plugin, ARQWeb, openvpn-config)
- **Frequency**: On-demand — triggered by a user authentication event or directory query need in the consuming service

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consuming Service | Initiates LDAP bind and search; interprets response | e.g., `killbill-subscription-programs-plugin`, `continuumArqWebApp` |
| Corp AD / LDAP VIP | Routes LDAP traffic to an available domain controller in the colo | `corpAdDirectoryService` |
| Active Directory Domain Controller | Processes the LDAP bind and search request; returns results | `corpAdDirectoryService` |

## Steps

1. **Establishes LDAPS connection**: The consuming service opens a TLS connection to the colo-local LDAP VIP on port 636.
   - From: Consuming service
   - To: `corpAdDirectoryService` (VIP: `corpldap1.<colo>:636`)
   - Protocol: LDAPS (TLS)

2. **Binds with service account**: The consuming service performs an LDAP `bindRequest` using the service account distinguished name (DN) and password to authenticate to the directory.
   - From: Consuming service
   - To: `corpAdDirectoryService`
   - Protocol: LDAP `bindRequest`

3. **Receives bind confirmation**: The domain controller validates the credentials and returns a `bindResponse` with result code `0` (success) or an error code (e.g., `49` for invalid credentials).
   - From: `corpAdDirectoryService`
   - To: Consuming service
   - Protocol: LDAP `bindResponse`

4. **Issues search request**: The consuming service sends an LDAP `searchRequest` with the appropriate base DN, scope, and filter (e.g., `(sAMAccountName=<username>)` or `(memberOf=<group-dn>)`).
   - From: Consuming service
   - To: `corpAdDirectoryService`
   - Protocol: LDAP `searchRequest`

5. **Returns matching entries**: The domain controller evaluates the search filter against its directory database and returns matching user or group objects with the requested attributes.
   - From: `corpAdDirectoryService`
   - To: Consuming service
   - Protocol: LDAP `searchResultEntry` + `searchResultDone`

6. **Consuming service processes result**: The consuming service uses the returned attributes (e.g., `memberOf`, `mail`, `displayName`) to make an authorization or identity decision.
   - From: Consuming service (internal processing)
   - To: N/A

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LDAP bind fails (`resultCode: 49`) | Consuming service treats as authentication failure | User access denied; consuming service logs the failure |
| LDAP VIP unreachable / connection timeout | Consuming service handles connection exception | Authentication or directory query fails; consuming service returns error to its caller |
| Search returns no results | Consuming service treats as not-found | User or group not provisioned in AD; consuming service may return 404 or access-denied |
| TLS certificate error (LDAPS) | LDAPS handshake fails; connection refused | All LDAP operations blocked until certificate is renewed on the domain controller |

## Sequence Diagram

```
ConsumingService -> corpAdDirectoryService: TCP/TLS connect (ldaps://corpldap1.<colo>:636)
corpAdDirectoryService --> ConsumingService: TLS handshake complete
ConsumingService -> corpAdDirectoryService: bindRequest (DN=service-account, password=***)
corpAdDirectoryService --> ConsumingService: bindResponse (resultCode: 0 — success)
ConsumingService -> corpAdDirectoryService: searchRequest (base=DC=group,DC=on, filter=(sAMAccountName=user))
corpAdDirectoryService --> ConsumingService: searchResultEntry (attributes: mail, memberOf, displayName, ...)
corpAdDirectoryService --> ConsumingService: searchResultDone (resultCode: 0)
ConsumingService -> ConsumingService: Process attributes; make authorization decision
```

## Related

- Architecture dynamic view: `dynamic-corpAD`
- Related flows: [Workday Employee Identity Sync](workday-employee-sync.md), [AD Group Membership Update](ad-group-membership-update.md)
