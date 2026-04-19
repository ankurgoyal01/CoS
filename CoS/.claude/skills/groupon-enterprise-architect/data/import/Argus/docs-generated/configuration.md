---
service: "argus"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [cli-arguments, yaml-files, gradle-tasks]
---

# Configuration

## Overview

Argus is configured through two mechanisms: Gradle task definitions in `build.gradle` (which encode which environment's alert directory to process) and YAML alert definition files under `src/main/resources/alerts/`. There are no runtime environment variables. Authentication tokens for Wavefront are embedded in the Groovy source (`MainScript.groovy`) rather than externalized — this is a known limitation of the current implementation.

## Environment Variables

> No evidence found in codebase. Argus does not read environment variables at runtime. The CI environment variable `GITHUB_BRANCH` is used by the `Jenkinsfile` to gate which stages execute, but it is not consumed by Argus application code.

## CLI Arguments

Each Groovy script accepts CLI arguments parsed via `CliBuilder`:

### `alerts-builder.groovy`

| Argument | Long form | Purpose | Required |
|----------|-----------|---------|----------|
| `-d <dir>` | `--definition <dir>` | Path (relative to resources root) of the alert definitions directory to process | no (defaults to `alerts`) |
| `-s` | `--summary` | Enable alert summary mode instead of sync mode | no |
| `-t <N>` | `--threshold <N>` | In summary mode, only print alerts that fired more than `N` times | no |
| `-h` | `--help` | Print usage | no |

### `wf-graph-builder.groovy`

| Argument | Long form | Purpose | Required |
|----------|-----------|---------|----------|
| `-d <file>` | `--definition <file>` | YAML definition file for dashboard graph layout | yes |
| `-t <dir>` | `--template-dir <dir>` | Template directory path (default: `templates`) | no |
| `-nd` | `--no-dashboards` | Disable dashboard processing | no |
| `-p` | `--with-proxy` | Enable localhost HTTP proxy (`127.0.0.1:3132`) | no |
| `-g <name>` | `--graph-def <name>` | Only process a specific graph definition group | no |
| `-c` | `--create-only` | Only create new graphs; skip updates | no |
| `-w <wildcard>` | `--metric-wildcard <wildcard>` | Wildcard filter for metric names (default: `*`) | no |

## Feature Flags

> No evidence found in codebase. No feature flags are implemented.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/alerts/<env>/**/*.yml` | YAML | Alert definitions per environment and service — each file declares host, colo, template, displayExpression, target, tags, and a list of alert instances |
| `src/main/resources/definitions/clientsSLA.yml` | YAML | SLA threshold definitions per client service/method — used by the dashboard builder to populate SLA chart queries |
| `src/main/resources/templates/*.yml` | YAML | Wavefront chart templates (type + named TS queries) used by the dashboard payload builder |
| `build.gradle` | Groovy DSL | Defines all Gradle tasks, maps each task to an environment's alert definition directory |
| `gradle/wrapper/gradle-wrapper.properties` | Properties | Pins Gradle distribution to version 5.0 |
| `.ci/Dockerfile` | Dockerfile | CI container image based on `docker.groupondev.com/jtier/dev-java11-maven:2020-12-04-277a463` |

### Alert YAML Structure

Each alert definition file contains the following top-level fields:

| Field | Purpose |
|-------|---------|
| `host` | Wavefront source/service tag value for the monitored service |
| `colo` | Availability zone / colo identifier (e.g. `dub1`, `snc1`) |
| `template` | Groovy template string for the Wavefront TS condition expression |
| `displayExpression` | Groovy template string for the display expression (using `collect(...)`) |
| `target` | Comma-separated Wavefront webhook IDs for alert notifications |
| `tags` | Tag string applied to all alerts in the file |
| `servers` | (Optional) Number of server instances — if set, generates one alert per host |
| `alerts` | List of alert instances, each with `name`, `metric`, `httpMethod`, `minutesToFire`, `severity`, `method`, `threshold` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Wavefront Bearer token (`090a228a-...`) | Authenticates alert management API calls | Embedded in `MainScript.groovy` (not externalized) |
| Wavefront X-AUTH-TOKEN (`c822f667-...`) | Authenticates chart/metrics API calls | Embedded in `MainScript.groovy` (not externalized) |
| Wavefront X-AUTH-TOKEN (`c3eb0070-...`) | Authenticates dashboard submission calls | Embedded in `MainScript.groovy` (not externalized) |
| Wavefront webhook IDs (`webhook:UXcN0ynhr2fq7OYm`, etc.) | Alert notification routing | Embedded in alert YAML definition files |

> Secret values are NEVER documented here. The above are references only. The current practice of embedding tokens in source code is a security concern that should be migrated to a secrets management solution.

## Per-Environment Overrides

Alert definitions are organized in separate directories under `src/main/resources/alerts/`, one per environment. Each directory is processed by a dedicated Gradle task:

| Gradle Task | Alert Directory | Environment |
|-------------|----------------|-------------|
| `updateAlertsSNCProduction` | `alerts/production_snc1` | SNC1 Production |
| `updateAlertsSNCStaging` | `alerts/staging_snc1` | SNC1 Staging |
| `updateAlertsSACProduction` | `alerts/production_sac1` | SAC1 Production |
| `updateAlertsDUBProduction` | `alerts/production_dub1` | DUB1 Production |
| `updateAlertsEUWEST1Production` | `alerts/production_eu_west_1` | EU-WEST-1 Production |
| `updateAlertsUSWEST1Production` | `alerts/production_us_west_1` | US-WEST-1 Production |
| `updateAlertsEMEAStaging` | `alerts/emea_staging_snc1` | EMEA Staging |
| `updateAlertsUSWEST1Staging` | `alerts/staging_us_west_1` | US-WEST-1 Staging |
| `updateAlertsUSWEST2Staging` | `alerts/staging_us_west_2` | US-WEST-2 Staging |
| `updateAlertsMiscellaneous` | `alerts/miscellaneous` | Cross-environment / misc |
| `updateAll` | `alerts` (all) | All environments |
