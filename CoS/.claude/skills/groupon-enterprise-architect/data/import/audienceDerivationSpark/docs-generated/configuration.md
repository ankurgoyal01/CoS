---
service: "audienceDerivationSpark"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, cli-args, spark-conf, crontab]
---

# Configuration

## Overview

Audience Derivation Spark is configured through a combination of CLI arguments passed to `spark-submit`, YAML config files stored in HDFS, JSON field config files bundled in the JAR, and Fabric environment/stage variables. There are no environment variables in the conventional sense; the deployment stage and region are specified as CLI arguments to both the Fabric tasks and the Python submit scripts. Secrets (Hive/Cassandra/AMS credentials) are not visible in this repository and are managed externally via Kerberos and credential files on the job submitter host.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `env.user` | SSH user for Fabric remote commands | yes | `audiencedeploy` | `fabfile.py` hardcoded |
| `env.deploy_project_root` | Base deployment path on job submitter host | yes | `/home/audiencedeploy/` | `fabfile.py` hardcoded |
| `env.hdfs_dir_root` | HDFS root for derivation config uploads | yes | `hdfs://cerebro-namenode/user/audiencedeploy/derivation/` | `fabfile.py` hardcoded |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `--syncDelete true` (FieldSyncMain) | Also delete extra fields from AMS DB during field sync | `false` (omit flag) | per-invocation |
| `-m {ratio}` (sampling) | Enable table sampling — selects random ratio of rows for UAT/alpha runs | disabled (omit flag) | per-environment |

## Config Files

### YAML Derivation Configuration Files

Each job type and region has a numbered sequence of YAML files that define the ordered SQL tempview transformations. Files are named `{NN}_{step_description}.yaml` and are loaded in numeric order at job startup.

| File / Directory | Format | Purpose |
|------|--------|---------|
| `config/usersTablesNA/01_user_entity_attrib_02.yaml` — `17_users_derived.yaml` | YAML | 17-step NA users derivation pipeline |
| `config/usersTablesEMEA/01_active_users.yaml` — `38_users_derived.yaml` | YAML | 38-step EMEA users derivation pipeline |
| `config/bcookieTablesNA/1_bcookie.yaml` | YAML | NA bcookie derivation pipeline |
| `config/bcookieTablesEMEA/1_bcookie.yaml` | YAML | EMEA bcookie derivation pipeline |

Each YAML file uses the following schema:

```yaml
sourceTableName: <hive_table>        # Source Hive table for this step (optional)
tempviewName: <tempview_name>         # Spark SQL tempview name registered
tempviewQueries:                      # Ordered list of SQL statements
  - SELECT ...
generalTableName: <output_table>      # Output Hive table name template (with %TableName%)
generalTableQueries:                  # DDL + INSERT statements for final output
  - CREATE TABLE %TableName% (...)
  - INSERT OVERWRITE TABLE %TableName% ...
```

### JSON Field Configuration Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/fieldsConfig/fields-user-na.json` | JSON | NA user field definitions for AMS sync |
| `src/main/resources/fieldsConfig/fields-user-emea.json` | JSON | EMEA user field definitions for AMS sync |
| `src/main/resources/fieldsConfig/fields-bcookie-na.json` | JSON | NA bcookie field definitions for AMS sync |
| `src/main/resources/fieldsConfig/fields-bcookie-emea.json` | JSON | EMEA bcookie field definitions for AMS sync |
| `src/main/resources/fieldsConfig/fields-none-na.json` | JSON | NA no-op field set |
| `src/main/resources/fieldsConfig/fields-none-emea.json` | JSON | EMEA no-op field set |
| `src/main/resources/fieldsConfig/user_category_cron.json` | JSON | User category cron configuration |

### Spark Submit Configuration (in `field_sync.py`)

| Config | Value | Purpose |
|--------|-------|---------|
| `--master yarn` | yarn | YARN cluster mode |
| `--deploy-mode cluster` | cluster | Driver runs on cluster |
| `--queue` | `audience` (NA) / `audience_emea` (EMEA) | YARN resource queue |
| `--driver-memory 5G` | 5 GB | Spark driver memory |
| `--executor-memory 5G` | 5 GB | Per-executor memory |
| `--executor-cores 4` | 4 | Cores per executor |
| `spark.dynamicAllocation.enabled` | `true` | Dynamic executor allocation |
| `spark.dynamicAllocation.minExecutors` | `5` | Minimum executors |
| `spark.dynamicAllocation.maxExecutors` | `10` | Maximum executors |
| `--files` | `hive-site.xml`, `log4j.properties` | Hive config and logging config distributed to executors |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Kerberos keytab / TGT | SSH and HDFS authentication for `audiencedeploy` service account | Kerberos KDC (on job submitter host) |
| `~/.ivy2/.credentials` | Nexus artifact repository credentials for SBT publish | File on build host (`build.sbt`: `credentials += Credentials(Path.userHome / ".ivy2" / ".credentials")`) |
| Hive Metastore credentials | Hive connection authentication | `hive-site.xml` on Cerebro cluster nodes |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The deployment stage is selected by the `--stage` CLI argument, which maps to HDFS paths and host targets:

| Stage | Deploy Directory | Job Submitter Host | HDFS Path |
|-------|-----------------|-------------------|-----------|
| `production` | `/home/audiencedeploy/ams/derivation/{region}/` | `cerebro-audience-job-submitter1.snc1` | `hdfs://.../derivation/production/` |
| `staging` | `/home/audiencedeploy/ams_staging/derivation/{region}/` | `cerebro-audience-job-submitter3.snc1` | `hdfs://.../derivation/staging/` |
| `uat` | `/home/audiencedeploy/ams_uat/derivation/{region}/` | `cerebro-audience-job-submitter3.snc1` | `hdfs://.../derivation/uat/` |
| `productionCloud` | `/home/audiencedeploy/ams_cloud/derivation/{region}/` | `cerebro-audience-job-submitter1.snc1` | `hdfs://.../derivation/productionCloud/` |
| `uatCloud` | `/home/audiencedeploy/ams_uat_cloud/derivation/{region}/` | `cerebro-audience-job-submitter3.snc1` | `hdfs://.../derivation/uatCloud/` |
| `stagingCloud` | `/home/audiencedeploy/ams_staging_cloud/derivation/{region}/` | `cerebro-audience-job-submitter3.snc1` | `hdfs://.../derivation/stagingCloud/` |

UAT and alpha environments additionally support table sampling (the `-m` ratio flag) to reduce data volume for testing purposes.
