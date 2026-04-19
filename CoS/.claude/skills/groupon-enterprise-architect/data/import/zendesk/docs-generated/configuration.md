---
service: "zendesk"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: []
---

# Configuration

## Overview

Zendesk is a SaaS platform with no Groupon-owned application code or deployment configuration in this repository. All service configuration (agent settings, ticket forms, triggers, automations, and API credentials) is managed within Zendesk's own hosted admin interface. Integration-level configuration (such as API tokens) is managed externally by the GSS team. No environment variables, config files, or secret references are present in the codebase.

## Environment Variables

> No evidence found in codebase. Configuration is managed within the Zendesk SaaS platform and is not exposed in this repository.

## Feature Flags

> No evidence found in codebase.

## Config Files

> No evidence found in codebase. No application configuration files are present in this repository. Refer to the Zendesk admin panel for active configuration.

## Secrets

> No evidence found in codebase. API credentials for Zendesk are managed externally by the GSS team. See the owners manual at [https://confluence.groupondev.com/display/GSS/Owners+Manual+-+Zendesk](https://confluence.groupondev.com/display/GSS/Owners+Manual+-+Zendesk) for credential management procedures.

## Per-Environment Overrides

> No evidence found in codebase. As a SaaS platform, environment separation (e.g., staging vs. production Zendesk instances) is managed within Zendesk's own account structure and is not reflected in this repository.
