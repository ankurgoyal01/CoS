---
service: "cls-gcp-dags"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: []
---

# Configuration

## Overview

> No evidence found in codebase. The `import-repos/cls-gcp-dags` directory contains only architecture DSL files; no Python source files, environment variable declarations, YAML/JSON config files, or Helm values were available for analysis. Configuration for Apache Airflow DAGs on Google Cloud Composer is typically managed through Airflow Variables, Airflow Connections, GCP Secret Manager references, and environment-level Composer configuration — but no specific configuration values or variable names are documented in the available DSL.

## Environment Variables

> No evidence found in codebase. No environment variable names or values are discoverable from the architecture DSL alone.

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| No evidence found in codebase. | | | | |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase.

## Config Files

> No evidence found in codebase. Airflow DAG configuration for GCP Cloud Composer is typically defined inline in Python DAG files or via Airflow Variables stored in the Composer environment.

| File | Format | Purpose |
|------|--------|---------|
| No evidence found in codebase. | | |

## Secrets

> No evidence found in codebase. GCP-based Airflow deployments typically use GCP Secret Manager or Airflow Connections for credentials, but no specific secret references are modeled in the architecture DSL.

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| No evidence found in codebase. | | |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

> No evidence found in codebase. Deployment configuration managed externally via Google Cloud Composer environment settings.
