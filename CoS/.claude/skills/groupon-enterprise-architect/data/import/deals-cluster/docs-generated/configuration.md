---
service: "deals-cluster"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "secrets-config-files"]
---

# Configuration

## Overview

Deals Cluster is configured through two properties files loaded at job startup based on the `ENV` environment variable: a main config file (`config/<ENV>.properties`) and a secrets file (`secrets-config/<ENV>.properties`). These are bundled into the JAR at build time from the `deals-cluster-secrets` git submodule. The `ENV` variable controls which environment's properties are loaded.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ENV` | Selects the active environment profile (`staging`, `production`, `development`, `gcp_dev`, `gcp_stable`, `gcp_prod`) | yes | None | Shell environment on Cerebro job submitter |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No runtime feature flags are used; behavior is controlled entirely via clustering rules fetched from the Rules API.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `config/<ENV>.properties` | Java properties | Main application configuration — HDFS paths, Hive table names, rule API URLs, Cerebro connection details, metrics configuration |
| `secrets-config/<ENV>.properties` | Java properties | Secret values — database credentials, Cerebro credentials, keystore passwords |
| `deals-cluster-secrets/` | (git submodule) | External secrets submodule providing the above secrets config files; excluded from version control |

### Key Configuration Properties (from `Constants.java`)

| Property Key | Purpose |
|-------------|---------|
| `db.url` | JDBC URL for the PostgreSQL DaaS cluster output database |
| `db.user` | PostgreSQL username |
| `db.password` | PostgreSQL password |
| `db.driver` | JDBC driver class name |
| `db.table` | Target PostgreSQL table for `DealsClusterJob` output |
| `db.top_clusters_table` | Target PostgreSQL table for `TopClustersJob` output |
| `db.write_size` | JDBC batch write size (number of rows per JDBC batch) |
| `db.stringtype` | PostgreSQL JDBC string type setting (e.g., `unspecified`) |
| `numPartitions` | Number of Spark-to-JDBC write partitions |
| `hdfs_path` | Base HDFS output path for cluster JSON files (e.g., `/user/grp_gdoop_mars_mds/deals_cluster_production`) |
| `cluster_rule_source` | Base URL for the Deals Cluster Rules API endpoint |
| `top_clusters_rule_source` | Base URL for the Top Clusters Rules API endpoint |
| `deals_cluster_rule_hb_url` | Host header value for rules API HTTP requests (internal VIP routing) |
| `cerebro.driver` | Hive JDBC driver class for Cerebro |
| `cerebro.url` | Hive JDBC URL for the Cerebro metastore |
| `cerebro.table` | Hive table name for the deals cluster partition registration |
| `cerebro.users` | Cerebro Hive service account username |
| `cerebro.password` | Cerebro Hive service account password |
| `cerebro.edw_table` | EDW Hive table name (`edwprod.agg_gbl_traffic_fin_deal`) |
| `cerebro.sold_gifts_table` | Hive table for sold gifts decoration data |
| `cerebro.analytics_table` | Hive table for analytics decoration data |
| `cerebro.dim_day_table` | Hive dimension table for date lookups |
| `cerebro.exchange_rate_table` | Hive table for currency exchange rates |
| `cities_source.emea` | Path or URL for EMEA city decoration data |
| `cities_source.us` | Path or URL for US city decoration data |
| `pds_tag_mapping_table` | Hive table for gift PDS tag mapping decoration |
| `deal_score_table` | Hive table for deal score decoration |
| `instalily_deal_score_table` | Hive table for Instalily deal score decoration |
| `metrics_endpoint` | InfluxDB HTTP endpoint URL |
| `metrics_namespace` | InfluxDB measurement namespace |
| `metrics_db_name` | InfluxDB database name |
| `metrics_flush_duration_in_millis` | InfluxDB batch flush interval in milliseconds |
| `metrics_tags_source` | InfluxDB tag value for `source` |
| `metrics_tags_env` | InfluxDB tag value for `env` |
| `metrics_tags_service` | InfluxDB tag value for `service` |
| `ils_schema` | ILS campaign Hive schema for ILS campaign decoration (`AppConfig`) |
| `ils_campaign_deals` | ILS campaign Hive table name for ILS campaign decoration (`AppConfig`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `db.password` | PostgreSQL DaaS database password | Git submodule (`deals-cluster-secrets`) / secrets-config file |
| `db.user` | PostgreSQL DaaS database username | Git submodule / secrets-config file |
| `cerebro.password` | Cerebro Hive service account password | Git submodule / secrets-config file |
| `javax.net.ssl.keyStorePassword` | PKCS12 keystore password for mTLS rules API calls | System property set at runtime from `/var/groupon/mis-data-pipelines-keystore.jks` |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The `ENV` environment variable selects the properties file set. Supported environments:

| Environment | Config File | Notes |
|-------------|-------------|-------|
| `development` | `config/development.properties` + `secrets-config/development.properties` | Local development; Spark master set to `local[1]` |
| `staging` | `config/staging.properties` + `secrets-config/staging.properties` | Cerebro staging; job submitter: `cerebro-job-submitter3.snc1` |
| `production` | `config/production.properties` + `secrets-config/production.properties` | Cerebro production; job submitter: `cerebro-job-submitter2.snc1` |
| `gcp_dev` | `config/gcp_dev.properties` + `secrets-config/gcp_dev.properties` | GCP development environment |
| `gcp_stable` | `config/gcp_stable.properties` + `secrets-config/gcp_stable.properties` | GCP stable environment |
| `gcp_prod` | `config/gcp_prod.properties` + `secrets-config/gcp_prod.properties` | GCP production environment |

The crontab files for each environment are located at:
- Production: `src/main/resources/run/production/crontab`
- Staging: `src/main/resources/run/staging/crontab`
