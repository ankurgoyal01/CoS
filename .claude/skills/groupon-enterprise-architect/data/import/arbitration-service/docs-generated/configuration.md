---
service: "arbitration-service"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The Arbitration Service is configured primarily through environment variables injected at container runtime via Kubernetes. YAML config files (parsed with `gopkg.in/yaml.v3`) provide additional static configuration. Secrets (database credentials, API tokens) are supplied as environment variables and managed externally to the service.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DB_HOST` | PostgreSQL server hostname | yes | none | env |
| `DB_PORT` | PostgreSQL server port | yes | none | env |
| `DB_USER` | PostgreSQL connection username | yes | none | env |
| `DB_PASSWORD` | PostgreSQL connection password (secret) | yes | none | env / k8s-secret |
| `DB_NAME` | PostgreSQL database name | yes | none | env |
| `CASSANDRA_HOSTS` | Comma-separated list of Cassandra contact points | yes | none | env |
| `CASSANDRA_KEYSPACE` | Cassandra keyspace name | yes | none | env |
| `CASSANDRA_USERNAME` | Cassandra authentication username | yes | none | env |
| `CASSANDRA_PASSWORD` | Cassandra authentication password (secret) | yes | none | env / k8s-secret |
| `REDIS_ADDR` | Redis server address (host:port) | yes | none | env |
| `REDIS_PASSWORD` | Redis authentication password (secret) | no | none | env / k8s-secret |
| `REDIS_DB` | Redis logical database index | no | none | env |
| `OPTIMIZELY_SDK_KEY` | Optimizely project SDK key for experiment config | yes | none | env / k8s-secret |
| `JIRA_URL` | Base URL for the Jira instance | yes | none | env |
| `JIRA_USERNAME` | Jira API username for approval workflow tickets | yes | none | env |
| `JIRA_TOKEN` | Jira API token (secret) | yes | none | env / k8s-secret |
| `APP_ENV` | Deployment environment identifier | yes | none | env |
| `LOG_LEVEL` | Zap structured log level | no | `info` | env |
| `PORT` | HTTP server listen port | no | `8080` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase for application-level feature flags distinct from Optimizely experiment variants. Experiment-driven behavior is configured via `OPTIMIZELY_SDK_KEY` and managed through the Optimizely project.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| > No evidence found in codebase | yaml | YAML config parsing is present via `gopkg.in/yaml.v3`; specific config file paths not discoverable from inventory |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DB_PASSWORD` | PostgreSQL connection password | k8s-secret |
| `CASSANDRA_PASSWORD` | Cassandra connection password | k8s-secret |
| `REDIS_PASSWORD` | Redis authentication password | k8s-secret |
| `OPTIMIZELY_SDK_KEY` | Optimizely project SDK key | k8s-secret |
| `JIRA_TOKEN` | Jira API token for approval workflow integration | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies are listed here.

## Per-Environment Overrides

The `APP_ENV` variable controls environment-specific behavior and is expected to be set to `development`, `staging`, or `production`. The service is deployed across multiple regions (snc1, sac1, dub1, cloud); region-specific configuration is managed via Kubernetes manifests and Conveyor/Krane deployment tooling. `LOG_LEVEL` is typically set to `debug` in development and `info` or `warn` in production.
