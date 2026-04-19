---
service: "corpAD"
title: "Workday Employee Identity Sync"
generated: "2026-03-03"
type: flow
flow_name: "workday-employee-sync"
flow_type: scheduled
trigger: "Scheduled import job (Syseng-managed)"
participants:
  - "corpAdDirectoryService"
  - "workday"
architecture_ref: "dynamic-corpAD"
---

# Workday Employee Identity Sync

## Summary

This flow describes how corpAD imports authoritative employee identity data from Workday, the Groupon HR system of record, into the `group.on` Active Directory domain. The synchronization process ensures that the Active Directory domain remains consistent with the current employee roster — provisioning accounts for new hires and deprovisioning or disabling accounts for terminated employees. The exact scheduling interval and transport mechanism are managed by the Syseng team and documented in the Owners Manual on Confluence.

## Trigger

- **Type**: schedule
- **Source**: Syseng-managed scheduled import job running on a sync host
- **Frequency**: Scheduled (interval managed by Syseng operations; not documented in this repository)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Workday | Source of authoritative employee HR data | `workday` |
| Corp AD / LDAP Sync Process | Reads from Workday and writes identity records to Active Directory | `corpAdDirectoryService` |
| Active Directory Domain (group.on) | Target directory store — receives created/updated/disabled user objects | `corpAdDirectoryService` |

## Steps

1. **Initiates sync job**: The Syseng-managed sync process starts on schedule.
   - From: Sync host (Syseng-managed)
   - To: `workday`
   - Protocol: Workday HR API (exact transport not documented in repository)

2. **Fetches employee records**: The sync process queries Workday for the current employee roster including new hires, updated records, and terminations.
   - From: Sync host
   - To: `workday`
   - Protocol: Workday HR API

3. **Compares with existing AD objects**: The sync process compares the retrieved Workday records against existing user objects in the `group.on` Active Directory domain.
   - From: Sync host
   - To: `corpAdDirectoryService`
   - Protocol: LDAP / LDAPS (internal)

4. **Creates new user accounts**: For each new hire found in Workday but not present in Active Directory, the sync creates a new user object with appropriate attributes (name, email, `sAMAccountName`, `employeeID`, OU placement).
   - From: Sync host
   - To: `corpAdDirectoryService`
   - Protocol: LDAP `addRequest`

5. **Updates existing user attributes**: For existing employees whose Workday attributes have changed (e.g., display name, manager, department), the sync updates the corresponding AD user object attributes.
   - From: Sync host
   - To: `corpAdDirectoryService`
   - Protocol: LDAP `modifyRequest`

6. **Disables or removes terminated accounts**: For employees flagged as terminated in Workday, the sync disables or removes the corresponding AD user object to revoke all LDAP-based access.
   - From: Sync host
   - To: `corpAdDirectoryService`
   - Protocol: LDAP `modifyRequest` (disable) or `deleteRequest` (remove)

7. **Replicates changes across colos**: Active Directory replication propagates all changes from the updated domain controller to peer domain controllers in all three colos (snc1, dub1, sac1).
   - From: `corpAdDirectoryService` (updated DC)
   - To: `corpAdDirectoryService` (peer DCs)
   - Protocol: Active Directory replication (DRSUAPI over RPC)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Workday API unavailable | Sync job fails; no changes applied | AD retains last-synced state; new hires and terminations are deferred until next successful sync run |
| LDAP write failure (individual record) | Depends on sync implementation — likely logged and skipped | Individual user record may be out of sync; Syseng monitors sync logs |
| AD replication failure | Active Directory replication retry mechanisms apply | Cross-colo inconsistency until replication recovers; monitored via `repadmin` |
| Sync job timeout | Job is terminated; partial updates may have been applied | Syseng reviews logs and re-runs sync for affected records |

## Sequence Diagram

```
SyncJob -> Workday: Fetch employee roster (new hires, updates, terminations)
Workday --> SyncJob: Employee records
SyncJob -> corpAdDirectoryService: LDAP search (compare existing AD objects)
corpAdDirectoryService --> SyncJob: Existing user objects
SyncJob -> corpAdDirectoryService: LDAP add (new hire accounts)
SyncJob -> corpAdDirectoryService: LDAP modify (updated attributes)
SyncJob -> corpAdDirectoryService: LDAP modify/delete (terminated accounts)
corpAdDirectoryService -> corpAdDirectoryService: AD replication to peer DCs (snc1, dub1, sac1)
```

## Related

- Architecture dynamic view: `dynamic-corpAD`
- Related flows: [LDAP Authentication and Directory Query](ldap-authentication-query.md), [AD Group Membership Update](ad-group-membership-update.md)
- Owners Manual: `https://confluence.groupondev.com/display/IT/Group.on+Active+Directory+Owner%27s+Manual`
