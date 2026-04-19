---
service: "external_dns_tools"
title: "DNS Change PR and Serial Management"
generated: "2026-03-03"
type: flow
flow_name: "dns-change-pr"
flow_type: synchronous
trigger: "Operator initiates a zone file change request"
participants:
  - "externalDnsDeployTool"
  - "externalDnsConfigRepo_unk_3c2e"
  - "externalDnsMasters"
architecture_ref: "dynamic-externalDnsTools"
---

# DNS Change PR and Serial Management

## Summary

Before any DNS configuration can be deployed, an operator must prepare two PRs against the `ops-ns_public_config` repository: a change PR and a rollback PR. Each PR must contain a correctly incremented SOA serial number to ensure monotonic ordering. This flow documents the mandatory pre-deploy preparation checklist — checking the current production serial, computing the correct incremented serial, resolving merge conflicts, and verifying that the rollback PR is merge-conflict-free. This process gates all external DNS changes.

## Trigger

- **Type**: user-action
- **Source**: An internal team, CorpIT, or SysEng receives a DNS change request (e.g., new hostname, CNAME change, IP update for a service)
- **Frequency**: On-demand, per DNS change request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Requesting team / operator | Submits DNS change request; provides intended record values | N/A |
| Infrastructure Engineering / CorpIT SysEng | Prepares change PR and rollback PR; manages serial numbers | N/A |
| ops-ns_public_config GitHub repo | Stores zone files; receives change PR and rollback PR | `externalDnsConfigRepo_unk_3c2e` |
| External DNS Masters (BIND) | Source of truth for current production SOA serial via `dig SOA` | `externalDnsMasters` |

## Steps

1. **Query current production SOA serial**: Operator runs `dig SOA <record>` (e.g., `dig SOA www-sac1.o.groupon.com`) from any host (no VPN required) to obtain the current production serial number.
   - From: Operator workstation
   - To: `externalDnsMasters` (via public DNS or production BIND IP)
   - Protocol: DNS (dig)

2. **Prepare change PR**: Operator creates a PR to `ops-ns_public_config` modifying the target zone file; sets the SOA serial to exactly `current_serial + 1`.
   - From: Operator
   - To: `externalDnsConfigRepo_unk_3c2e`
   - Protocol: git / GitHub PR

3. **Prepare rollback PR**: Operator creates a second PR to `ops-ns_public_config` that reverts the zone file change; sets the SOA serial to `change_serial + 1` (i.e., `current_serial + 2`) to ensure rollback serial is always ahead of change serial.
   - From: Operator
   - To: `externalDnsConfigRepo_unk_3c2e`
   - Protocol: git / GitHub PR

4. **Resolve merge conflicts**: If either PR has merge conflicts (due to concurrent changes), the deployment must be postponed until conflicts are resolved. The rollback PR in particular must be conflict-free before proceeding.
   - From: Operator
   - To: `externalDnsConfigRepo_unk_3c2e`
   - Protocol: git

5. **Re-verify serial numbers (15 minutes before deploy)**: ~15 minutes before the scheduled change, operator re-runs `dig SOA <record>` to confirm the current serial has not changed since PR creation. If the serial changed, both PRs must be updated to use the new `current_serial + 1` and `current_serial + 2` values.
   - From: Operator workstation
   - To: `externalDnsMasters`
   - Protocol: DNS (dig)

6. **Get requestor sign-off on staging**: After deploying to staging, operator pings the requestor to verify the change. For urgent changes where the requestor is unavailable, operator performs a self-review.
   - From: Operator / requestor
   - To: staging BIND host (via dig or application test)
   - Protocol: DNS / application

7. **Rebase rollback PR to master**: After staging verification, operator rebases the rollback PR to master to ensure it will apply cleanly after the change PR is merged.
   - From: Operator
   - To: `externalDnsConfigRepo_unk_3c2e`
   - Protocol: git / GitHub PR

8. **Merge change PR and deploy to production**: Operator merges the change PR and runs the full DNS deploy to production (see [DNS Zone Deploy](dns-deploy.md)).
   - From: Operator
   - To: `externalDnsConfigRepo_unk_3c2e` / `externalDnsMasters`
   - Protocol: git + Ansible SSH

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Merge conflict in change PR | Postpone deployment; resolve conflict and update serial numbers | No change until conflicts resolved |
| Merge conflict in rollback PR | Deployment must be postponed; rollback PR conflict is critical | No production change until rollback PR is conflict-free |
| Serial number mismatch (pre-deploy re-check) | Update both PRs with revised serial numbers | Rework PRs before deploying |
| Production rollback needed | Merge rollback PR; deploy to staging for verification; deploy to production | Previous zone state restored |

## Sequence Diagram

```
Operator -> BIND master (prod): dig SOA <record> (check current serial N)
Operator -> ops-ns_public_config: Create change PR (serial = N+1)
Operator -> ops-ns_public_config: Create rollback PR (serial = N+2)
Operator -> ops-ns_public_config: Resolve any merge conflicts
Operator -> BIND master (prod): dig SOA <record> again ~15 min before deploy (verify serial still N)
Operator -> deploy tool: Run dns_deploy.py (staging deploy)
BIND master (staging) --> Operator/requestor: Staging verification (dig / app test)
Operator -> ops-ns_public_config: Rebase rollback PR to master
Operator -> deploy tool: Run dns_deploy.py (production deploy)
```

## Related

- Architecture dynamic view: `dynamic-externalDnsTools`
- Related flows: [DNS Zone Deploy](dns-deploy.md), [Branch Testing](branch-test.md)
- Deployment SOP: Confluence `https://groupondev.atlassian.net/wiki/spaces/IT/pages/80509337735/Deploy+public+DNS`
