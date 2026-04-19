---
service: "booster"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: []
---

# Configuration

## Overview

Booster is an external SaaS operated entirely by Data Breakers. There is no Groupon-owned service configuration for Booster itself. Configuration relevant to the Booster integration — such as API credentials, base URLs, and timeout settings — would be held within the Groupon services that call Booster (primarily `continuumRelevanceApi`). No configuration files, environment variables, or secrets are discoverable from this repository.

## Environment Variables

> No evidence found in codebase. Environment variables for the Booster API connection (e.g., API keys, base URLs) are expected to be configured in the calling service (`continuumRelevanceApi`), not in this integration boundary repository.

## Feature Flags

> No evidence found in codebase.

## Config Files

> No evidence found in codebase. No configuration files specific to the Booster integration are present in this repository.

## Secrets

> No evidence found in codebase. API credentials and authentication secrets for the Booster vendor API are managed by the vendor agreement and stored in Groupon's secrets management system, accessible through the calling service configuration.

## Per-Environment Overrides

> No evidence found in codebase. Environment-specific configuration (e.g., staging vs. production Booster endpoints) is managed by the calling services. The `.service.yml` file indicates `hosting_configured_via_ops_config: false` and `colos: none`, confirming Booster is not a Groupon-hosted service.
