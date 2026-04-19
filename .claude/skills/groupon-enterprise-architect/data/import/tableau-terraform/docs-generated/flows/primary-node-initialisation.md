---
service: "tableau-terraform"
title: "Primary Node Initialisation"
generated: "2026-03-03"
type: flow
flow_name: "primary-node-initialisation"
flow_type: event-driven
trigger: "GCE VM startup event (metadata startup script)"
participants:
  - "primaryNode"
  - "tableauInstanceGroup"
  - "tableauStorageBucket"
architecture_ref: "dynamic-tableauTerraform"
---

# Primary Node Initialisation

## Summary

When the primary GCE VM starts for the first time (or after a reprovision), GCP executes the `primary_user_data.sh.tpl` startup script. This script installs the Tableau Server RPM, configures LDAP/Active Directory integration, initialises Tableau Services Manager (TSM), activates the license, creates the initial REST API user, and generates a cluster bootstrap file that worker nodes need to join the cluster. The bootstrap file is transferred to each worker node via SCP.

## Trigger

- **Type**: event (GCE VM boot — metadata startup script execution)
- **Source**: GCP Compute Engine metadata service executes the script on first boot
- **Frequency**: Once per VM provisioning; re-runs if the VM is recreated by Terraform

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GCE Primary VM | Executes the startup script end-to-end | `primaryNode` |
| GCP Metadata Service | Injects script and template variables at boot time | external (GCP) |
| Tableau download server | Provides the Tableau Server RPM | external (`downloads.tableau.com`) |
| Active Directory (LDAP) | Identity store configured for Tableau user authentication | external (`use2-ldap-vip.group.on`) |
| Worker VMs | Receive the bootstrap file via SCP | `workerNodes` |
| GCE SFTP (tableauadmin user) | Staging area for the bootstrap file before SCP distribution | `primaryNode` |

## Steps

1. **Create working directory and log file**: Script creates `/home/tableau/` and redirects all output to `/home/tableau/install.log`.
   - From: `primaryNode` (startup script)
   - To: local filesystem
   - Protocol: shell

2. **Write LDAP configuration file**: Script writes `/home/tableau/config.json` with Active Directory connection parameters (`domain: group.on`, `hostname: use2-ldap-vip.group.on`, `port: 389`, `bind: simple`, `username: svc_tableaubind`). Password is injected from the Terraform-rendered template variable `${ldap_password}`.
   - From: `primaryNode`
   - To: local filesystem
   - Protocol: shell

3. **Write TSM secrets file**: Script writes `/home/tableau/secrets.properties` with `tsm_admin_user` and `tsm_admin_pass` from Terraform template variables.
   - From: `primaryNode`
   - To: local filesystem
   - Protocol: shell

4. **Write registration file**: Script writes `/home/tableau/registration.json` with Groupon organisation details for Tableau license registration.
   - From: `primaryNode`
   - To: local filesystem
   - Protocol: shell

5. **Set up SFTP for tableauadmin**: Configures OpenSSH (`sshd_config`) to restrict `tableauadmin` user to SFTP-only with chroot, then restarts `sshd`.
   - From: `primaryNode`
   - To: `sshd`
   - Protocol: shell / SSH config

6. **Download Tableau Server RPM**: Downloads `tableau-server-2025-1-4.x86_64.rpm` from `https://downloads.tableau.com/esdalt/2025.1.4/tableau-server-2025-1-4.x86_64.rpm`.
   - From: `primaryNode`
   - To: Tableau download server
   - Protocol: HTTPS

7. **Install Tableau Server RPM**: Runs `yum -y install /home/tableau/tableau-server.rpm`.
   - From: `primaryNode`
   - To: local RPM package
   - Protocol: yum

8. **Initialise TSM**: Runs `initialize-tsm -a tableauadmin --accepteula -f` and sources the Tableau Server environment profile.
   - From: `primaryNode`
   - To: TSM
   - Protocol: shell / TSM CLI

9. **Log in to TSM and activate license**: Runs `tsm login` then `tsm licenses activate -k <license-key>`.
   - From: `primaryNode`
   - To: TSM
   - Protocol: TSM CLI

10. **Register Tableau**: Runs `tsm register --file /home/tableau/registration.json`.
    - From: `primaryNode`
    - To: TSM
    - Protocol: TSM CLI

11. **Import LDAP configuration**: Runs `tsm configuration set` to disable STARTTLS, then `tsm settings import -f /home/tableau/config.json`, followed by `tsm pending-changes apply`.
    - From: `primaryNode`
    - To: TSM / Active Directory
    - Protocol: TSM CLI / LDAP

12. **Initialise and start Tableau Server**: Runs `tsm initialize --start-server --request-timeout 1800`.
    - From: `primaryNode`
    - To: TSM
    - Protocol: TSM CLI

13. **Create initial REST API user**: Runs `tabcmd initialuser --server localhost:80 --username svc_tabapiuser --password <password>`.
    - From: `primaryNode`
    - To: Tableau REST API (localhost)
    - Protocol: HTTP (tabcmd)

14. **Generate cluster bootstrap file**: Runs `tsm topology nodes get-bootstrap-file --file /home/tableau/bootstrap_primary_node.json` and moves it to the SFTP staging directory.
    - From: `primaryNode`
    - To: local filesystem
    - Protocol: TSM CLI

15. **Distribute bootstrap file to worker nodes**: For each worker IP in `${worker_ips}`, SCPs `/home/tableauadmin/files/bootstrap_primary_node.json` to `tableaulogin@<worker-ip>:/home/tableaulogin/` using the SSH private key at `/home/tableau/ssh.pem`.
    - From: `primaryNode`
    - To: `workerNodes`
    - Protocol: SCP over SSH

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| RPM download failure | `curl` exits non-zero; script continues but `yum install` fails | Tableau not installed; check `/home/tableau/install.log` and re-run |
| TSM initialisation timeout | `tsm initialize` has a 1800 s request timeout | Script fails; manual TSM restart required |
| SCP of bootstrap file fails | Script logs failure and continues | Worker nodes cannot join the cluster; manual SCP required |
| LDAP configuration import fails | `tsm pending-changes apply` exits non-zero | Tableau starts without LDAP; user auth fails |

## Sequence Diagram

```
GCP_Metadata -> PrimaryVM: Execute startup script
PrimaryVM -> LocalFS: Write config.json (LDAP config)
PrimaryVM -> LocalFS: Write secrets.properties (TSM creds)
PrimaryVM -> LocalFS: Write registration.json
PrimaryVM -> SSHD: Configure SFTP for tableauadmin, restart sshd
PrimaryVM -> TableauDownloadServer: curl tableau-server-2025-1-4.x86_64.rpm
TableauDownloadServer --> PrimaryVM: Tableau Server RPM
PrimaryVM -> PrimaryVM: yum install tableau-server.rpm
PrimaryVM -> TSM: initialize-tsm, tsm login, tsm licenses activate
PrimaryVM -> TSM: tsm settings import (LDAP), tsm pending-changes apply
PrimaryVM -> ActiveDirectory: Verify LDAP (tsm user-identity-store verify-user-mappings)
PrimaryVM -> TSM: tsm initialize --start-server
PrimaryVM -> TableauRestAPI: tabcmd initialuser (svc_tabapiuser)
PrimaryVM -> TSM: tsm topology nodes get-bootstrap-file
PrimaryVM -> WorkerVM[0]: scp bootstrap_primary_node.json
PrimaryVM -> WorkerVM[N]: scp bootstrap_primary_node.json
```

## Related

- Architecture dynamic view: `dynamic-tableauTerraform`
- Related flows: [Infrastructure Provisioning](infrastructure-provisioning.md), [Worker Node Cluster Join](worker-node-cluster-join.md)
