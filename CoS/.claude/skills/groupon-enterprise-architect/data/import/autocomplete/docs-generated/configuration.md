---
service: "autocomplete"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [config-files, dynamic-config]
---

# Configuration

## Overview

The autocomplete service is configured through two layers: static Dropwizard YAML configuration files packaged with the service, and dynamic runtime configuration supplied by `gConfigService` via the Archaius 0.7.6 polling client. Archaius continuously polls gConfigService so endpoint URLs, feature toggles, and tuning parameters can be changed without a service restart.

## Environment Variables

> No evidence found in codebase. Specific environment variable names are not defined in the architecture model. Standard JTier/Dropwizard deployment will inject host, port, and credential values via environment at deploy time.

## Feature Flags

> No evidence found in codebase. Feature flags are resolved at runtime via Finch/Birdcage experiment treatments (`CardsFinchClient`, `V2FinchClient`). Specific flag names are not defined in the architecture model.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| Dropwizard application YAML | YAML | Static service configuration: server port, logging, thread pools, connector settings |
| Embedded term files (`continuumAutocompleteTermFiles`) | JSON/Text | Term corpus and division recommendation datasets loaded at startup |

## Secrets

> No evidence found in codebase. Secrets such as DataBreakers API credentials and any service-to-service tokens are expected to be injected at deploy time via the platform secrets mechanism. Specific secret names are not defined in the architecture model.

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. Environment-specific configuration differences (dev, staging, production) are managed externally by the deployment platform and gConfigService properties. The architecture model does not define per-environment configuration values.
