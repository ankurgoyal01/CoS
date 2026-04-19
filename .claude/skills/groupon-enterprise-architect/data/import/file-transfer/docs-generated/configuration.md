---
service: "file-transfer"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "helm-values", "k8s-secret"]
---

# Configuration

## Overview

All runtime configuration is supplied through environment variables read at startup in `src/file_transfer/configuration.clj`. Defaults are compiled-in fallbacks (mostly empty strings); production values are injected by Kubernetes via Helm charts and secrets files. The `CLJ_ENV` variable controls which Leiningen profile is active (affects REPL port and logging behaviour).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CLJ_ENV` | Leiningen environment profile (`dev`, `test`, `production`) | yes | — | Helm values (`envVars.CLJ_ENV`) |
| `LEIN_REPL_PORT` | nREPL server port (worker deployment only) | no | 4601 | Helm values |
| `SSH_PATH` | Filesystem path to the SSH key directory inside the container | yes | `/root/.ssh` | env-var / k8s-secret |
| `FILE_SHARING_HOST` | Base URL of the internal File Sharing Service | yes | `""` | k8s-secret |
| `FILE_SHARING_USER_UUID` | Service account UUID for authenticating with FSS | yes | `""` | k8s-secret |
| `MESSAGEBUS_HOST` | Hostname of the messagebus STOMP broker | yes | `127.0.0.1` | k8s-secret |
| `MESSAGEBUS_PORT` | Port of the messagebus STOMP broker | yes | `61613` | k8s-secret |
| `MESSAGEBUS_USER` | Username for messagebus STOMP authentication | yes | `mbus` | k8s-secret |
| `MESSAGEBUS_PASSWORD` | Password for messagebus STOMP authentication | yes | `""` | k8s-secret |
| `MESSAGEBUS_CONNECTION_LIFETIME_MS` | Maximum producer connection lifetime in milliseconds | no | `300000` | k8s-secret |
| `DATABASE_SUBNAME` | JDBC subname for MySQL connection (`//host:port/db_name`) | yes | `//127.0.0.1:3306/file_transfer` | k8s-secret |
| `DATABASE_USER` | MySQL username | yes | `root` | k8s-secret |
| `DATABASE_PASSWORD` | MySQL password | yes | `""` | k8s-secret |
| `GETAWAYS_BOOKING_USER` | SSH/SFTP username for the Getaways booking server | yes | `""` | k8s-secret |
| `GETAWAYS_BOOKING_HOST` | Hostname of the Getaways booking SFTP server | yes | `""` | k8s-secret |
| `GETAWAYS_BOOKING_PUBKEY_PATH` | Relative path (from `SSH_PATH`) to the SSH private key | yes | `""` | k8s-secret (secretFile) |
| `GETAWAYS_BOOKING_PORT` | SFTP port on the Getaways booking server | yes | `""` | k8s-secret |
| `GETAWAYS_BOOKING_DOWNLOAD_DIR` | Remote directory to list/download from | yes | `""` | k8s-secret |
| `GETAWAYS_BOOKING_DOWNLOAD_FILE_REGEXP` | Regexp pattern used to filter files in `GETAWAYS_BOOKING_DOWNLOAD_DIR` | yes | `""` | k8s-secret |
| `GETAWAYS_DELETE_AFTER_IN_YEARS` | Number of years after which FSS should delete file content | no | `""` | k8s-secret |

> IMPORTANT: Actual secret values are never documented. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found in codebase. No feature flag system is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/file_transfer/configuration.clj` | Clojure | Defines the static configuration map and reads env vars at startup |
| `profiles.clj` | Clojure | Leiningen profiles for dev/test overrides |
| `resources/log4j.properties` | Properties | Log4j appender and log-level configuration |
| `.meta/deployment/cloud/components/cronjobs/<env>/common.yml` | YAML | Kubernetes CronJob base config (image, resources, log config) |
| `.meta/deployment/cloud/components/cronjobs/<env>/getaways.yml` | YAML | Getaways CronJob schedule (`30 0 */1 * *`) and job arguments |
| `.meta/deployment/cloud/components/cronjobs/<env>/unprocessed.yml` | YAML | Unprocessed-file check CronJob schedule (`0 1 */1 * *`) |
| `.meta/deployment/cloud/components/worker/common.yml` | YAML | Kubernetes Deployment base config (replicas, resources, probes) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GETAWAYS_BOOKING_PUBKEY_PATH` (file) | SSH private key for authenticating with the Getaways SFTP server | k8s-secret (secretFile via Cloud Migration Factory) |
| All `DATABASE_*` variables | MySQL credentials | k8s-secret |
| All `MESSAGEBUS_*` variables | Messagebus STOMP credentials | k8s-secret |
| All `GETAWAYS_BOOKING_*` variables | SFTP connection credentials | k8s-secret |
| `FILE_SHARING_*` variables | FSS connection credentials | k8s-secret |

> Secret values are NEVER documented. The secrets repo is `sox-inscope/file-transfer-secrets`.

## Per-Environment Overrides

- **dev / test**: `CLJ_ENV=dev` or `CLJ_ENV=test` selects the appropriate Leiningen profile. Database defaults to localhost MySQL; all external secrets must be set manually.
- **staging**: Deployed to namespace `file-transfer-staging-sox` on GCP `us-central1`. `CLJ_ENV=production` is set; secrets injected from staging secrets bundle. Both `finance-engineering` (staging branch) and `sox-inscope` (master) trigger staging deploys.
- **production**: Deployed to namespace `file-transfer-production-sox` on GCP `us-central1`. Only `sox-inscope/master` triggers production deploys. VIP: `file-transfer.us-central1.conveyor.prod.gcp.groupondev.com`.
