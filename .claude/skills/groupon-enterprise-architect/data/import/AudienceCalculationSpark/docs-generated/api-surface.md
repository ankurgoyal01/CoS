---
service: "AudienceCalculationSpark"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

AudienceCalculationSpark exposes no inbound HTTP API. It is a Spark batch job JAR that is invoked exclusively via `spark-submit` by `continuumAudienceManagementService`. All runtime inputs are passed as a JSON string on the command line at job submission time. The service does make outbound HTTPS calls to AMS endpoints to report lifecycle state and results — those are documented in [Integrations](integrations.md).

## Endpoints

> Not applicable. This service has no inbound HTTP or RPC endpoints.

## Request/Response Patterns

### Command-line invocation

Each Spark application is launched with a single JSON argument passed to the main class. The JSON schema is defined by the `AudienceManagementWorkFlowAPI` library. Example shapes per entrypoint:

**Sourced Audience (`AudienceImporterMain`)**

| Field | Type | Purpose |
|-------|------|---------|
| `id` | Long | Sourced audience ID in AMS |
| `audienceTable` | String | Output Hive table name |
| `database` | String | Hive database name |
| `amsEndpointHost` | String | AMS host for callbacks |
| `amsEndpointPort` | Int | AMS port |
| `publishHdfsURIPrefix` | String | HDFS base path for outputs |
| `publishHftpURIPrefix` | String | HFTP base path for outputs |
| `sqlQueries` | Array[String] | SQL statements to execute |
| `sourceType` | String | `csv`, `hive`, `custom`, or `pa_hive` |
| `hdfsPath` | String | HDFS path to uploaded CSV (csv source type) |
| `logPrefix` | String | Log prefix string for tracking |

**Published Audience (`AudiencePublisherMain`)**

| Field | Type | Purpose |
|-------|------|---------|
| `paId` | Int | Published audience ID in AMS |
| `sourceDataFrameCreationQuery` | String | SQL to build the base PA DataFrame |
| `segmentInputs` | Array | Segment definitions (percentage, label, table ID, CSV file) |
| `paCsvPath` | String | HDFS path for segment CSV outputs |
| `feedbackTableCreationQuery` | String | SQL for EDW feedback table |
| `feedbackCsvPath` | String | HDFS path for feedback CSV |
| `database` | String | Hive database name |
| `amsEndpointHost` | String | AMS host for callbacks |
| `hasCustomPayload` | Boolean | Whether rows include a `custom_payload` column |
| `sourcePaId` | Int | Source PA ID for dedup (-1 if not a dedup) |

**Joined Audience (`AudienceJoinedMain`)**

| Field | Type | Purpose |
|-------|------|---------|
| `paSparkInput` | Object | Full PA spark input (same shape as above) |
| `sourcedAudienceSparkInput` | Object | Full SA spark input (same shape as above) |
| `sourcedAudienceToBeSaved` | Boolean | Whether to persist the SA Hive table |
| `sourcedAudienceTempViewName` | String | Temp view name to pass SA data into PA |

**Batch Published Audience (`BatchPublishedAudience.Main`)**

| Field | Type | Purpose |
|-------|------|---------|
| `publishedAudienceIds` | Array[Long] | List of PA IDs to process in this batch |
| `cacheQuery` | String | SQL to compute and cache the shared base DataFrame |
| `cacheTempViewName` | String | Temp view name for the cached base |
| `logPrefix` | String | Log prefix string |

### Error format

> Not applicable — this service does not return HTTP responses. Errors are reported to AMS via the `updateImportResults`, `updatePublicationResults`, or `updateCalculationResults` endpoints.

### Pagination

> Not applicable.

## Rate Limits

> No rate limiting configured. Job concurrency is limited by YARN vcore queue capacity (NA: 1400 vcores, EMEA: 1000 vcores).

## Versioning

> Not applicable — no API to version. The JAR artifact is versioned (`4.35.25-SNAPSHOT` in `build.sbt`) and published to Nexus Artifactory.

## OpenAPI / Schema References

Workflow input DTOs are defined in the `AudienceManagementWorkFlowAPI` library (version `4.6.8`), hosted at `https://github.groupondev.com/crm/AudienceManagementWorkFlowAPI`.
