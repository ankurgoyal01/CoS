---
service: "external_dns_tools"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-files", "ansible-vars"]
---

# Configuration

## Overview

The External DNS deploy tooling is configured entirely through a single YAML file (`tools/dns_deploy_config.yml`) that operators edit before running `dns_deploy.py`. There are no environment variables injected at runtime. The BIND server configuration (zone files, `named.conf`) is managed separately via the `ops-ns_public_config` GitHub repository and delivered to servers as packaged tarballs.

## Environment Variables

> No evidence found in codebase. The deploy tool does not use environment variables. All configuration is read from `dns_deploy_config.yml` and the Ansible inventory file.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `tools/dns_deploy_config.yml` | YAML | Primary operator configuration for the deploy tool: git remotes, working directory, host groups, QA test assertions, proxy settings, and active hostclass selection |
| `tools/dns_public_inventory` | Ansible INI | Ansible inventory defining `[local]`, `[test]`, and `[production]` host groups used by `dns_deploy.yml` and `test_branch.yml` |
| `tools/dns_deploy.yml` | YAML (Ansible playbook) | Full deployment orchestration playbook |
| `tools/test_branch.yml` | YAML (Ansible playbook) | Branch-testing playbook for validating in-progress zone config changes on staging servers |

### Key fields in `dns_deploy_config.yml`

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `task_timestamp` | Timestamp used to name the `ns_public_config-<timestamp>` package and `ns_public-<timestamp>` hostclass tag; auto-generated if empty | no | `""` (auto-generated as `%Y.%m.%d_%H.%M`) | config-file |
| `dns_change_release` | Human-readable release label committed to `ops-config` (e.g., `"External DNS - 2016.05.02_15.01"`) | no | `""` (auto-generated) | config-file |
| `dns_change_release_msg` | Free-text description of the change committed to `ops-config` | no | `""` | config-file |
| `dns_change_hostclass` | If non-empty, re-uses an existing `ns_public-<timestamp>` hostclass tag instead of creating a new package | no | `""` (new package created) | config-file |
| `hosts_groups` | List of Ansible host groups to target during deploy (`local`, `test`, `production`) | yes | `["local", "test", "production"]` | config-file |
| `playbook` | Path to the Ansible playbook to execute | yes | `"dns_deploy.yml"` | config-file |
| `qa_test` | Map of DNS records to expected `dig` output for change-specific QA validation | yes | `{groupon.com: '...'}` | config-file |
| `qa_test_default` | Map of baseline DNS records always validated after every deploy | yes | Five records including `groupon.com`, `www.groupon.com`, `origin.groupon.com`, `api.groupon.com`, `api.origin.groupon.com` | config-file |
| `working_dir` | Base directory on the utility server where repos are cloned | yes | `"/var/groupon"` | config-file |
| `ns_public.git` | SSH git remote for `ops-ns_public_config` zone file repo | yes | `"git@github:prod-ops/ops-ns_public_config.git"` | config-file |
| `ops_config.git` | SSH git remote for `ops-config` hostclass management repo | yes | `"git@git:ops-config"` | config-file |
| `proxy` | Whether to route traffic through an HTTP proxy | no | `no` | config-file |
| `proxy_env.http_proxy` | HTTP proxy URL if proxy is enabled | no | `""` | config-file |

## Secrets

> No evidence found in codebase. The deploy tool relies on operator SSH keys (ambient git authentication) rather than secrets management. No Vault, AWS Secrets Manager, or Kubernetes secrets are referenced.

## Per-Environment Overrides

- **Dev/Staging**: The `[test]` inventory group contains `ns-public1-staging.snc1` and `ns-public2-staging.snc1`. Operators may target only the `test` group by selecting option `c` in `dns_deploy.py`.
- **Production**: The `[production]` inventory group contains `ns-public1.dub1`, `ns-public2.dub1`, `ns-public1.snc1`, `ns-public3.snc1`, `ns-public1.sac1`, and `ns-public2.sac1`. Always deploy to staging and verify before promoting to production.
- The tool is run from designated utility servers only: `syseng-utility1.snc1`, `syseng-utility2.snc1` (production) or `syseng-utility1-uat.snc1` (UAT). Running from a developer laptop is not supported.
