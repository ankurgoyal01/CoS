---
service: "openvpn-config"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars]
---

# Configuration

## Overview

OpenVPN Config Automation is configured entirely through environment variables. There are no config files, feature flags, or external config stores (Vault, Consul, Helm). All three required variables must be set in the shell environment before running any script. The base API URL and OAuth credentials are the only configurable parameters.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `OPENVPN_API` | Base URL of the OpenVPN Cloud Connexa tenant API (e.g., `https://<tenant>.openvpn.com`) | yes | None | env |
| `OPENVPN_CLIENT_ID` | OAuth 2.0 client ID used to obtain a Bearer token from `/api/beta/oauth/token` | yes | None | env |
| `OPENVPN_CLIENT_SECRET` | OAuth 2.0 client secret paired with `OPENVPN_CLIENT_ID` | yes | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No feature flags are used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `backup/networks.json` | JSON | Persisted snapshot of Cloud Connexa networks; read by restore and query scripts |
| `backup/users.json` | JSON | Persisted snapshot of Cloud Connexa users |
| `backup/user_groups.json` | JSON | Persisted snapshot of Cloud Connexa user groups |
| `backup/apps.json` | JSON | Persisted snapshot of Cloud Connexa applications |
| `backup/ip_services.json` | JSON | Persisted snapshot of Cloud Connexa IP services |
| `backup/access_groups.json` | JSON | Persisted snapshot of Cloud Connexa access groups |

These files are inputs/outputs of the automation scripts rather than configuration files, but they are stored in the repository and referenced by the query scripts in `scripts/`.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `OPENVPN_CLIENT_ID` | OAuth 2.0 client ID for Cloud Connexa API authentication | env (operator-managed; store not specified in codebase) |
| `OPENVPN_CLIENT_SECRET` | OAuth 2.0 client secret for Cloud Connexa API authentication | env (operator-managed; store not specified in codebase) |

> Secret values are NEVER documented. Only names and rotation policies are documented. Actual secrets management store (e.g., AWS Secrets Manager, Vault) is not specified in the codebase.

## Per-Environment Overrides

No environment-specific configuration mechanism is implemented in the scripts. The operator sets `OPENVPN_API`, `OPENVPN_CLIENT_ID`, and `OPENVPN_CLIENT_SECRET` to point to the appropriate Cloud Connexa tenant for each operation. Multiple tenants or environments (e.g., dev vs. prod Cloud Connexa accounts) would be handled by switching environment variable values before script execution.
