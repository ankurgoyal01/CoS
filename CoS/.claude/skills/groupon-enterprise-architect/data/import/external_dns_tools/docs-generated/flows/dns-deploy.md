---
service: "external_dns_tools"
title: "DNS Zone Deploy"
generated: "2026-03-03"
type: flow
flow_name: "dns-deploy"
flow_type: batch
trigger: "Manual operator action via dns_deploy.py"
participants:
  - "externalDnsDeployTool"
  - "externalDnsConfigRepo_unk_3c2e"
  - "internal-config-service"
  - "externalDnsMasters"
  - "akamaiEdgeDns_unk_0b6c"
architecture_ref: "dynamic-externalDnsTools"
---

# DNS Zone Deploy

## Summary

The DNS Zone Deploy flow is the full end-to-end process by which an operator applies updated DNS zone configuration (zone files with incremented SOA serials) to the BIND master servers and causes Akamai EdgeDNS to pick up the changes. The operator runs `dns_deploy.py` on a designated utility server, which orchestrates the Ansible playbook `dns_deploy.yml` to clone repositories, package zone files, validate syntax, push to servers, and trigger BIND reloads. The flow always deploys to staging (test) before production, with QA assertions at each stage.

## Trigger

- **Type**: manual
- **Source**: Operator runs `python dns_deploy.py` on `syseng-utility1.snc1` or `syseng-utility2.snc1`
- **Frequency**: On-demand, whenever a zone file change PR has been merged to `ops-ns_public_config`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (SysEng/CorpIT) | Initiates deploy, makes hostclass/ticket selections in CLI | N/A |
| External DNS Deploy Tooling | Orchestrates full deploy via interactive CLI and Ansible | `externalDnsDeployTool` |
| ops-ns_public_config repo | Source of zone file content | `externalDnsConfigRepo_unk_3c2e` |
| ops-config repo | Hostclass management — receives new package/hostclass tags | internal |
| Internal config service (`http://config/`) | Stores packaged tarballs; reports hostclass propagation status | internal |
| External DNS Masters (BIND) | Receives and loads updated zone configuration | `externalDnsMasters` |
| Akamai EdgeDNS | Detects SOA serial change and pulls zone transfer from BIND masters | `akamaiEdgeDns_unk_0b6c` |

## Steps

1. **Launch deploy tool**: Operator runs `python dns_deploy.py` from the utility server. The tool syncs `ops-config` and presents the interactive menu.
   - From: Operator workstation
   - To: `externalDnsDeployTool` (localhost)
   - Protocol: CLI

2. **Select deploy scope**: Operator selects target host groups (`c` = test only, `d` = production only, `e` = test + production) and optionally selects an existing hostclass tag or accepts new package creation.
   - From: Operator
   - To: `externalDnsDeployTool`
   - Protocol: CLI (stdin)

3. **Clone and sync zone config repo**: Ansible playbook clones `ops-ns_public_config` via `git clone git@github:prod-ops/ops-ns_public_config.git`; syncs to `origin/master`.
   - From: `externalDnsDeployTool`
   - To: `externalDnsConfigRepo_unk_3c2e` (GitHub)
   - Protocol: git over SSH

4. **Package zone configuration**: Creates symlink and tarball `ns_public_config-<timestamp>.tar.gz` from the `config/` and `etc/` directories using GNU tar.
   - From: `externalDnsDeployTool` (localhost)
   - To: local filesystem
   - Protocol: direct

5. **Local validation**: Installs `bind-9.9.5p1` and `ns_public_config-<timestamp>` locally via `epkg`; runs `named-checkconf -z /usr/local/etc/named.conf` to validate all zone file syntax and collect deployed zone names and serial numbers.
   - From: `externalDnsDeployTool`
   - To: localhost (epkg + named-checkconf)
   - Protocol: exec

6. **Upload package to config service**: Uploads the validated tarball to `http://config/package/` via `curl --upload-file`.
   - From: `externalDnsDeployTool`
   - To: Internal config service
   - Protocol: HTTP PUT

7. **Tag and update hostclass in ops-config**: Adds the new package to the `ns_public` hostclass (`./bin/add_package`); commits; creates git tag `ns_public-<timestamp>`; pushes tag to ops-config repo.
   - From: `externalDnsDeployTool`
   - To: ops-config repo
   - Protocol: git over SSH + internal OCQ tool

8. **Assign hostclass to test servers and push**: Assigns `ns_public-<timestamp>` hostclass to `[test]` hosts via `./bin/set_hostclass`; commits; pushes via `ops-config-queue -v -ocq`.
   - From: `externalDnsDeployTool`
   - To: ops-config repo / internal config service
   - Protocol: git + OCQ

9. **Wait for config propagation to test servers**: Polls `http://config.<dc>/host/<hostname>` until the new hostclass is reported for all test hosts (up to 500 retries, 2-second delay).
   - From: `externalDnsDeployTool`
   - To: Internal config service
   - Protocol: HTTP GET

10. **Roll test servers**: SSHes to each `[test]` host and runs `/var/tmp/roll` to apply the new hostclass (BIND reloads with updated zone files).
    - From: `externalDnsDeployTool`
    - To: `externalDnsMasters` (staging)
    - Protocol: SSH (Ansible)

11. **QA validation on test servers**: Runs `named-checkconf` and `dig +noall +answer @127.0.0.1` assertions for both `qa_test_default` records and the change-specific `qa_test` records; asserts expected values match.
    - From: `externalDnsDeployTool` / test BIND host
    - To: local BIND daemon on test host
    - Protocol: exec + DNS

12. **Serial comparison check**: Compares SOA serials of all deployed zones between production (`@ns-public1.snc1`) and staging (`@ns-public1-staging.snc1`) to confirm staging serials are not behind production.
    - From: `externalDnsDeployTool`
    - To: `externalDnsMasters` (prod + staging)
    - Protocol: DNS (dig)

13. **Assign hostclass to production servers and push**: Assigns `ns_public-<timestamp>` to `[production]` hosts; commits; pushes via `ops-config-queue`.
    - From: `externalDnsDeployTool`
    - To: ops-config repo / internal config service
    - Protocol: git + OCQ

14. **Wait for config propagation to production servers**: Polls config service until new hostclass is confirmed on all production hosts.
    - From: `externalDnsDeployTool`
    - To: Internal config service
    - Protocol: HTTP GET

15. **Roll production servers**: SSHes to each `[production]` host and runs `/var/tmp/roll`; runs `named-checkconf` and `qa_test_default` assertions.
    - From: `externalDnsDeployTool`
    - To: `externalDnsMasters` (production)
    - Protocol: SSH (Ansible)

16. **Akamai zone transfer pickup**: After BIND masters reload with updated zone files, Akamai ZTAs detect the incremented SOA serials and perform zone transfers (AXFR/IXFR) to synchronize records.
    - From: `externalDnsMasters`
    - To: `akamaiEdgeDns_unk_0b6c`
    - Protocol: DNS zone transfer (AXFR/IXFR, TCP 53)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `named-checkconf` validation fails on localhost | Ansible task fails; deploy halts before any package upload | No change deployed; operator must fix zone files in `ops-ns_public_config` |
| `ops-config-queue` push fails | Playbook task set with `retries: 10, delay: 5`; if all retries fail, operator must manually `git pull --rebase` and re-run `ops-config-queue` | Operator selects existing hostclass tag in `dns_deploy.py` to resume |
| QA dig assertion fails on test servers | Ansible `assert` task fails; deploy halts before production promotion | Operator investigates BIND config on test host; redeploys after fix |
| Production roll fails | Operator must merge rollback PR to `ops-ns_public_config` and redeploy | Previous zone configuration restored |
| Serial comparison shows staging behind production | Ansible `assert` fails; production roll blocked | Operator investigates SOA serial discrepancy; may need to increment serial and redeploy |

## Sequence Diagram

```
Operator -> dns_deploy.py: Run python dns_deploy.py; select option 's'
dns_deploy.py -> ops-ns_public_config (GitHub): git clone / git pull --rebase
dns_deploy.py -> localhost: Create ns_public_config-<timestamp>.tar.gz
dns_deploy.py -> localhost: epkg install; named-checkconf -z named.conf
dns_deploy.py -> config service (http://config/): curl --upload-file ns_public_config-<timestamp>.tar.gz
dns_deploy.py -> ops-config (GitHub): add_package; git tag ns_public-<timestamp>; ops-config-queue push
dns_deploy.py -> config service: poll until ns_public-<timestamp> confirmed for test hosts
dns_deploy.py -> BIND masters (test): SSH /var/tmp/roll
BIND masters (test) -> BIND masters (test): named-checkconf; dig QA assertions
dns_deploy.py -> BIND masters (prod+staging): dig SOA serial comparison
dns_deploy.py -> ops-config (GitHub): set_hostclass for production hosts; ops-config-queue push
dns_deploy.py -> config service: poll until ns_public-<timestamp> confirmed for production hosts
dns_deploy.py -> BIND masters (production): SSH /var/tmp/roll
BIND masters (production) -> BIND masters (production): named-checkconf; dig QA assertions
Akamai ZTAs -> BIND masters (production): AXFR/IXFR zone transfer (SOA serial change detected)
BIND masters (production) --> Akamai ZTAs: Zone data
Akamai EdgeDNS --> end users: Updated DNS records served
```

## Related

- Architecture dynamic view: `dynamic-externalDnsTools`
- Related flows: [Zone Transfer to Akamai](zone-transfer.md), [DNS Change PR and Serial Management](dns-change-pr.md), [Branch Testing](branch-test.md)
