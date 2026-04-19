---
service: "tableau-terraform"
title: "Worker Node Cluster Join"
generated: "2026-03-03"
type: flow
flow_name: "worker-node-cluster-join"
flow_type: event-driven
trigger: "GCE VM startup event (metadata startup script)"
participants:
  - "workerNodes"
  - "primaryNode"
  - "tableauInstanceGroup"
architecture_ref: "dynamic-tableauTerraform"
---

# Worker Node Cluster Join

## Summary

When a worker GCE VM starts (on initial provisioning or reprovision), GCP executes the `worker_user_data.sh.tpl` startup script. The worker writes its TSM credentials, sets up an SFTP-restricted user account, and then polls for the bootstrap file (`bootstrap_primary_node.json`) that the primary node deposits at `/home/tableaulogin/`. Once the bootstrap file is detected, the worker installs Tableau Server RPM and calls `initialize-tsm` with the bootstrap file to join the cluster as a worker node.

## Trigger

- **Type**: event (GCE VM boot — metadata startup script execution)
- **Source**: GCP Compute Engine metadata service executes the script on worker VM first boot
- **Frequency**: Once per VM provisioning; re-runs if the VM is recreated by Terraform

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GCE Worker VM | Executes worker startup script; polls for bootstrap file; installs and joins Tableau cluster | `workerNodes` |
| GCP Metadata Service | Injects startup script and template variables (TSM credentials, Tableau download URL) at boot | external (GCP) |
| GCE Primary VM | Generates and SCPs the bootstrap file to the worker | `primaryNode` |
| Tableau download server | Provides the Tableau Server RPM via HTTPS | external (`downloads.tableau.com`) |

## Steps

1. **Create working directory and log file**: Script creates `/home/tableau/` and redirects all output to `/home/tableau/install.log`.
   - From: `workerNode` (startup script)
   - To: local filesystem
   - Protocol: shell

2. **Write TSM secrets file**: Script writes `/home/tableau/secrets.properties` with `tsm_admin_user` and `tsm_admin_pass` injected from Terraform template variables.
   - From: `workerNode`
   - To: local filesystem
   - Protocol: shell

3. **Set up SFTP for tableauadmin**: Configures OpenSSH (`sshd_config`) to restrict `tableauadmin` to SFTP-only with chroot, creates user and home directory, then restarts `sshd`.
   - From: `workerNode`
   - To: `sshd`
   - Protocol: shell / SSH config

4. **Download Tableau Server RPM**: Downloads `tableau-server-2025-1-4.x86_64.rpm` from `https://downloads.tableau.com/esdalt/2025.1.4/tableau-server-2025-1-4.x86_64.rpm` via `curl`.
   - From: `workerNode`
   - To: Tableau download server
   - Protocol: HTTPS

5. **Poll for bootstrap file**: Script enters a `while` loop, sleeping 60 seconds between iterations, until `/home/tableaulogin/bootstrap_primary_node.json` is present (deposited by the primary node via SCP).
   - From: `workerNode`
   - To: local filesystem
   - Protocol: shell (polling)

6. **Install Tableau Server RPM**: Once the bootstrap file is detected, runs `yum -y install /home/tableau/tableau-server.rpm`.
   - From: `workerNode`
   - To: local RPM package
   - Protocol: yum

7. **Initialise TSM with bootstrap file**: Runs `initialize-tsm -b /home/tableaulogin/bootstrap_primary_node.json -a tableauadmin --accepteula -f` to register this VM as a worker node in the existing Tableau cluster.
   - From: `workerNode`
   - To: TSM
   - Protocol: TSM CLI

8. **Add admin users to tsmadmin group**: Runs `usermod -G tsmadmin -a tableauadmin` and `usermod -G tsmadmin -a tableaulogin` to grant TSM access.
   - From: `workerNode`
   - To: local OS user management
   - Protocol: shell

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Bootstrap file never arrives | While loop polls indefinitely; no timeout configured | Worker VM hangs waiting; manual intervention needed — verify primary completed and SCP the file manually |
| RPM download failure | `curl` exits non-zero; subsequent `yum install` fails | Tableau not installed; check `/home/tableau/install.log` and re-run |
| TSM initialisation with bootstrap fails | `initialize-tsm` exits non-zero | Worker does not join cluster; manual re-run of `initialize-tsm` required |
| SFTP setup fails | Script continues; worker may start without correct SSH config | Bootstrap file SCP from primary may fail if `tableaulogin` SSH path is incorrect |

## Sequence Diagram

```
GCP_Metadata -> WorkerVM: Execute startup script
WorkerVM -> LocalFS: Write secrets.properties (TSM creds)
WorkerVM -> SSHD: Configure SFTP for tableauadmin, restart sshd
WorkerVM -> TableauDownloadServer: curl tableau-server-2025-1-4.x86_64.rpm
TableauDownloadServer --> WorkerVM: Tableau Server RPM
WorkerVM -> LocalFS: Poll for bootstrap_primary_node.json (60s intervals)
PrimaryVM -> WorkerVM: scp bootstrap_primary_node.json (triggered by primary script)
WorkerVM -> LocalFS: Detects bootstrap_primary_node.json
WorkerVM -> WorkerVM: yum install tableau-server.rpm
WorkerVM -> TSM: initialize-tsm -b bootstrap_primary_node.json
TSM --> WorkerVM: Worker node registered in cluster
WorkerVM -> OS: usermod tsmadmin group for tableauadmin, tableaulogin
```

## Related

- Architecture dynamic view: `dynamic-tableauTerraform`
- Related flows: [Infrastructure Provisioning](infrastructure-provisioning.md), [Primary Node Initialisation](primary-node-initialisation.md)
