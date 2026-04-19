---
service: "external_dns_tools"
title: "Branch Testing"
generated: "2026-03-03"
type: flow
flow_name: "branch-test"
flow_type: batch
trigger: "Manual operator action via dns_deploy.py option 't'"
participants:
  - "externalDnsDeployTool"
  - "externalDnsConfigRepo_unk_3c2e"
  - "externalDnsMasters"
architecture_ref: "dynamic-externalDnsTools"
---

# Branch Testing

## Summary

The Branch Testing flow allows an operator to test an in-progress zone configuration branch on the staging BIND servers without creating an official versioned package or updating any hostclass tags. This is used when a change is still in draft (e.g., a feature branch in `ops-ns_public_config`) and the operator wants to validate that `named-checkconf` passes and BIND starts correctly with the new config before committing to a formal deployment. The `test_branch.yml` Ansible playbook clones the specified branch, rsyncs zone files to staging servers, and reloads BIND.

## Trigger

- **Type**: manual
- **Source**: Operator selects option `t` in `dns_deploy.py` and provides a branch name from `ops-ns_public_config`
- **Frequency**: On-demand, used when testing draft zone config changes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Initiates test; provides branch name | N/A |
| External DNS Deploy Tooling | Runs `test_branch.yml` playbook against staging servers | `externalDnsDeployTool` |
| ops-ns_public_config repo | Source of the draft zone config branch under test | `externalDnsConfigRepo_unk_3c2e` |
| External DNS Masters (staging) | Target servers for branch validation; BIND is reloaded with branch config | `externalDnsMasters` |

## Steps

1. **Operator selects branch test option**: Operator selects `t` in `dns_deploy.py` menu; enters the `ops-ns_public_config` branch name to test and confirms.
   - From: Operator
   - To: `externalDnsDeployTool`
   - Protocol: CLI (stdin)

2. **Generate task timestamp**: Deploy tool generates `task_timestamp` (format: `%Y.%m.%d_%H.%M`) to namespace the test directory on staging servers.
   - From: `externalDnsDeployTool`
   - To: local
   - Protocol: direct

3. **Create test directory on staging servers**: Ansible creates `/var/groupon/tests/ns_public_<timestamp>` on each `[test]` host with appropriate ownership.
   - From: `externalDnsDeployTool`
   - To: `externalDnsMasters` (staging)
   - Protocol: SSH (Ansible)

4. **Clone branch from ops-ns_public_config**: On localhost, the Ansible playbook clones the specified branch from `ops-ns_public_config` using `git clone --version <branch>`.
   - From: `externalDnsDeployTool`
   - To: `externalDnsConfigRepo_unk_3c2e`
   - Protocol: git over SSH

5. **Rsync zone files to staging servers**: The playbook rsyncs the `etc/` subtree from the cloned branch to `/var/groupon/tests/ns_public_<timestamp>/` on each staging host via `rsync -avz -e 'ssh'`.
   - From: `externalDnsDeployTool` (localhost)
   - To: `externalDnsMasters` (staging)
   - Protocol: rsync over SSH

6. **Symlink named.conf and zones.conf**: On each staging host, Ansible creates symlinks from `/usr/local/etc/named.conf` and `/usr/local/etc/zones.conf` pointing to the test directory versions.
   - From: Ansible (on staging host)
   - To: `externalDnsMasters` (staging, local filesystem)
   - Protocol: direct (Ansible file module)

7. **Relink zones directory**: Removes existing zone file symlinks and the `zones/` directory; creates a new symlink pointing to `/var/groupon/tests/ns_public_<timestamp>/etc/zones`.
   - From: Ansible (on staging host)
   - To: `externalDnsMasters` (staging, local filesystem)
   - Protocol: direct (Ansible file module + shell)

8. **Validate with named-checkconf**: Runs `/usr/local/sbin/named-checkconf -z /usr/local/etc/named.conf` on the staging server to verify the branch config passes syntax checking.
   - From: Ansible (on staging host)
   - To: `externalDnsMasters` (staging, named-checkconf)
   - Protocol: exec

9. **Restart BIND named**: Restarts named on staging via `/usr/local/etc/init.d/named restart` to load the branch config.
   - From: Ansible (on staging host)
   - To: `externalDnsMasters` (staging, named daemon)
   - Protocol: exec

10. **Operator verifies results**: Operator manually validates DNS records on the staging BIND server using `dig @ns-public1-staging.snc1 <record>` to confirm the branch config behaves as expected.
    - From: Operator workstation
    - To: `externalDnsMasters` (staging)
    - Protocol: DNS (dig)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| git clone fails (branch not found) | Ansible task fails; deploy tool reports error | No changes made to staging; operator must correct branch name |
| named-checkconf fails | Ansible task runs with `ignore_errors: yes`; operator sees failure output | BIND restart may still be attempted; operator must fix zone file errors in the branch |
| BIND named restart fails | Ansible task runs with `ignore_errors: yes` | Staging may revert to previous config on next restart; operator investigates named errors |
| rsync connectivity failure | Ansible task fails; no zone files transferred | Staging unchanged; operator verifies SSH connectivity to staging hosts |

## Sequence Diagram

```
Operator -> dns_deploy.py: Select option 't'; enter branch name; confirm
dns_deploy.py -> dns_deploy.py: Generate task_timestamp
dns_deploy.py -> BIND masters (staging): SSH: create /var/groupon/tests/ns_public_<timestamp>/ directory
dns_deploy.py -> ops-ns_public_config (GitHub): git clone <branch>
dns_deploy.py -> BIND masters (staging): rsync etc/ to /var/groupon/tests/ns_public_<timestamp>/etc/
BIND masters (staging) -> BIND masters (staging): symlink named.conf -> test dir
BIND masters (staging) -> BIND masters (staging): symlink zones.conf -> test dir
BIND masters (staging) -> BIND masters (staging): relink /usr/local/etc/zones -> test dir
BIND masters (staging) -> BIND masters (staging): named-checkconf -z named.conf
BIND masters (staging) -> BIND masters (staging): /usr/local/etc/init.d/named restart
Operator -> BIND masters (staging): dig @ns-public1-staging.snc1 <record> (manual verification)
```

## Related

- Architecture dynamic view: `dynamic-externalDnsTools`
- Related flows: [DNS Zone Deploy](dns-deploy.md), [DNS Change PR and Serial Management](dns-change-pr.md)
