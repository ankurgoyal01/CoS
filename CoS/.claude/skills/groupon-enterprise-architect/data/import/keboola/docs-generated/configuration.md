---
service: "keboola"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: []
---

# Configuration

## Overview

Keboola Connection is a fully managed SaaS platform. Groupon does not manage environment variables, config files, or secrets directly for the Keboola runtime. All connector configurations, transformation scripts, orchestration schedules, and credential management are performed through the Keboola web UI or Keboola's management APIs. Platform-level configuration is owned and managed by the Keboola vendor team.

The `.service.yml` in this repository provides Groupon's service registry metadata (owner, team contact, GChat space, documentation links) but does not represent runtime application configuration.

## Environment Variables

> No evidence found in codebase. No application environment variables are defined; this is a managed SaaS with no Groupon-deployed runtime.

## Feature Flags

> No evidence found in codebase.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.service.yml` | YAML | Groupon service registry metadata — service name, owner (`rpadala`), team email (`gdoop-dev@groupon.com`), GChat space ID (`AAAArqovlCY`), documentation links |

## Secrets

> No evidence found in codebase. Credentials for Salesforce and BigQuery integrations are managed within the Keboola platform's secret store, administered by the Keboola vendor. Groupon does not manage these secrets directly.

## Per-Environment Overrides

> No evidence found in codebase. Keboola operates as a single managed environment; per-environment configuration distinctions are not documented in this repository. The `.service.yml` lists `colos: none: {}`, indicating no Groupon colo deployment.
