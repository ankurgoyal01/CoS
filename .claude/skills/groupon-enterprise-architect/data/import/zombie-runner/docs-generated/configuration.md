---
service: "zombie-runner"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, workflow-yaml]
---

# Configuration

## Overview

Zombie Runner is configured through three layers: environment variables set on the Dataproc cluster node, INI-format configuration files (`~/.zrc2` and `~/.odbc.ini`), and per-workflow YAML files (`tasks.yml`). There is no Consul, Vault, or Helm-based config management — the service runs as a per-invocation CLI process and reads its configuration at startup.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ODBCINI` | Path to the ODBC configuration file used for database DSN resolution | No | `/etc/odbc.ini` | env |
| `ZOMBIERC` | Path to the Zombie Runner runtime configuration file (`.zrc2` format) | No | `~/.zrc2` | env |
| `SPARK_HOME` | Path to the Spark installation directory for `SparkSubmit` tasks | Conditional | From context or `spark-home` config key | env |
| `ZR_LOG_LEVEL` | Controls logging verbosity (`DEBUG`, `INFO`, `WARN`, `ERROR`) | No | `INFO` | env |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase. Zombie Runner does not use a feature flag system. Conditional task execution is controlled by the `conditions` key in workflow YAML.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `~/.zrc2` (path overridden by `ZOMBIERC`) | INI | Global Zombie Runner configuration: log level, log file path, database connection settings, email SMTP settings |
| `~/.odbc.ini` (path overridden by `ODBCINI`) | INI | ODBC DSN definitions for database connections (PostgreSQL, MySQL, Teradata, Snowflake) used by SQL task operators |
| `<workflow_dir>/tasks.yml` | YAML | Workflow definition: context variables, settings, resources, and task definitions |
| `zombie_runner/shared/resource/snowflake-load.tpl` | Mako template | SQL template for Snowflake COPY INTO staging workflow |
| `zombie_runner/shared/resource/teradata-bteq.tpl` | Mako template | BTEQ script template for Teradata bulk loads |
| `zombie_runner/shared/resource/teradata-tpt.tpl` | Mako template | TPT (Teradata Parallel Transporter) script template |
| `zombie_runner/shared/resource/tpt-export.tpl` | Mako template | TPT export script template |
| `zombie_runner/shared/resource/sql_report.tpl` | Mako template | SQL report rendering template |
| `zombie_runner/shared/resource/abbreviations.txt` | Text | Abbreviation lookup resource for string normalization |
| `zombie_runner/shared/resource/reserved_words.hive` | Text | Reserved words list for Hive SQL generation |
| `zombie_runner/shared/resource/reserved_words.teradata` | Text | Reserved words list for Teradata SQL generation |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| ODBC DSN password (in `odbc.ini`) | Database authentication credential for RDBMS connections | Local INI file (encrypted via `decrypt_key` setting when configured) |
| Snowflake ODBC credentials | Snowflake warehouse authentication | Local ODBC DSN |
| AWS IAM role / credentials | S3 upload and EMR step submission | IAM instance role attached to Dataproc/EMR service account |
| Salesforce API credentials | Salesforce object access | Task-level `username` / `password` parameters in workflow YAML |
| Jira API token | Jira issue creation and update | `auth` parameter passed to `JiraServer` constructor |
| HTTP Basic Auth credentials | External REST endpoint authentication | `username` / `password` keys in `RestGetTask` / `RestUploadTask` configuration |

> Secret values are NEVER documented. Only names and rotation policies.

## Workflow YAML Configuration Reference

The `tasks.yml` file supports the following global settings keys:

| Setting Key | Purpose | Default |
|-------------|---------|---------|
| `settings.attempts` | Number of retry attempts per task on failure | 1 |
| `settings.cooldown` | Seconds to wait between retry attempts | 0 |
| `settings.timeout` | Task execution timeout in seconds | None |
| `resources.<name>` | Number of slots available for the named resource pool | User-defined |

## Per-Environment Overrides

Zombie Runner has no formal environment promotion system. The workflow YAML `context` section and CLI `--<key>=<value>` flags serve as the mechanism for injecting environment-specific values (e.g., `--env=prod`, `--region=us-east1`). Cluster-level configuration differences (project, region, subnet, metastore) are managed at Dataproc cluster creation time via `gcloud dataproc clusters create` parameters. Separate Dataproc cluster images may be used for sandbox vs. production environments.
