---
service: "audienceDerivationSpark"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

Audience Derivation Spark is a batch Spark application with no inbound HTTP, gRPC, or message-based API. It exposes no service endpoints to external callers. All invocation happens through command-line `spark-submit` executed by the operations scripts (`submit_derivation.py`, `submit_link_sad_base_table_generation.py`) or Fabric tasks, on a scheduled cron cadence or manually by operators.

The CLI interface for each Spark job entrypoint is documented below.

## CLI Entrypoints

### AudienceDerivationMain (users and bcookie derivation)

| Argument | Flag | Purpose | Required |
|----------|------|---------|----------|
| AMS environment | `-a` | AMS environment name (e.g., `production-na`) | yes |
| Stage | `--stage` | Deployment stage: `production`, `staging`, `uat` | yes |
| Region | `--region` | Region: `na` or `emea` | yes |
| Job type | `--job` | Derivation job: `users` or `bcookie` | yes |
| Config HDFS path | `-s` | HDFS path to YAML config directory | yes |
| Hive host | `-h` | Hive metastore host | yes |
| Hive port | `-p` | Hive metastore port | yes |
| Fields file | `-f` | Fields output file name | yes |
| Log prefix | `--log-prefix` | Log identifier prefix | yes |
| Sampling ratio | `-m` | Sample ratio between 0 and 1 (UAT/alpha only) | no |

### FieldSyncMain (AMS field synchronization)

| Argument | Flag | Purpose | Required |
|----------|------|---------|----------|
| AMS environment | `-a` | AMS environment name | yes |
| Log prefix | `--log-prefix` | Log identifier prefix | yes |
| Sync delete | `--syncDelete true` | Also delete extra fields from AMS DB | no |

### CQDFieldValidatorMain (CQD validation)

Invoked by `validate_ams_cqd.py`; validates CQD field definitions against current Hive and AMS state. No additional user-facing flags documented in source.

## Request/Response Patterns

> Not applicable — no HTTP API exists.

### Common headers

> Not applicable

### Error format

> Not applicable

### Pagination

> Not applicable

## Rate Limits

> Not applicable — no rate limiting configured. Jobs are submitted by cron schedule; at most one job per region/job-type runs concurrently.

## Versioning

The assembled JAR version is defined in `build.sbt` (`version := "2.64.4-SNAPSHOT"`). Snapshot versions end with `SNAPSHOT`; release versions do not. The deployed JAR is symlinked to `AudienceDerivationSpark-assembly-current.jar` on the job submitter host.

## OpenAPI / Schema References

No OpenAPI spec or proto files exist for this service. Field output schemas are defined in the YAML config files under `config/usersTablesNA/`, `config/usersTablesEMEA/`, `config/bcookieTablesNA/`, and `config/bcookieTablesEMEA/`. Field metadata is maintained in AMS and in the JSON files under `src/main/resources/fieldsConfig/`.
