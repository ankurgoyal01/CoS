---
service: "AudiencePayloadSpark"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
---

# API Surface

## Overview

AudiencePayloadSpark is a batch Spark application suite — it does not expose any HTTP, gRPC, or WebSocket endpoints. Its public interface is the fat JAR command-line interface invoked via `spark-submit`. Each entrypoint object (`AttrPayloadGeneratorMain`, `PAPayloadGeneratorMain`, `PAPayloadAggregatorMain`, `CAAttributeRedisWriterMain`, `CAAttributeBigTableWriterMain`, `HiveToKeyspaceWriter`, `CassandraWriterMain`) accepts structured CLI arguments parsed by `scopt`.

> No evidence found in codebase of any inbound HTTP, gRPC, or WebSocket API surface.

## Spark Job CLI Interface

The JAR is invoked as:

```
spark-submit AudiencePayloadSpark-assembly-<version>.jar [entrypoint-class] [args...]
```

### AttrPayloadGeneratorMain — Attribute Upload

| Flag | Long form | Required | Default | Purpose |
|------|-----------|----------|---------|---------|
| `-a` | `--env` | yes | `uat-na` | Target environment (e.g. `production-na`, `staging-emea`) |
| `-t` | `--payload-type` | yes | — | Audience type: `users` or `bcookie` |
| `-s` | `--system-table` | no | AMS API lookup | Hive source system table name |
| `-b` | `--base-table` | no | — | Base Hive table for delta upload |
| `--log-prefix` | `--log-prefix` | no | — | Log prefix string |
| `-c` | `--cassandra-write-throughput` | no | `0.04` | Cassandra write throughput (MB/s) — NA only |
| `-w` | `--concurrent-write` | no | `50` | Concurrent write count — EMEA only |

### PAPayloadGeneratorMain — PA Membership Upload/Delete

| Flag | Long form | Required | Default | Purpose |
|------|-----------|----------|---------|---------|
| `-a` | `--env` | yes | `uat-na` | Target environment |
| `-t` | `--payload-type` | no | `users` | Audience type: `users`, `bcookie`, or `universal` |
| `-n` | `--number-of-prev-days` | no | `-1` | Number of previous days to scan |
| `--log-prefix` | `--log-prefix` | no | — | Log prefix |
| `-s` | `--pa-state` | no | `PUBLISHED` | PA state filter: `PUBLISHED` or `REJECTED` |
| `-c` | `--cassandra-write-throughput` | no | `0.04` | Cassandra write throughput |
| `-w` | `--concurrent-write` | no | `50` | Concurrent writes |

### PAPayloadAggregatorMain — SAD/NonSAD Aggregation

| Flag | Long form | Required | Default | Purpose |
|------|-----------|----------|---------|---------|
| `-a` | `--env` | yes | `uat-na` | Target environment |
| `-t` | `--payload-type` | no | `users` | Audience type |
| `-n` | `--number-of-prev-days` | no | `-1` | Days to scan |
| `-p` | `--pa-type` | no | — | PA type: `sad`, `nonsad`, or `all` |
| `--log-prefix` | `--log-prefix` | no | — | Log prefix |
| `-c` | `--cassandra-write-throughput` | no | `0.04` | Throughput |
| `-w` | `--concurrent-write` | no | `50` | Concurrent writes |
| `-s` | `--send-date` | no | — | Override send date |
| `-l` | `--limit` | no | `0` (unlimited) | Max number of PAs to publish |
| `-m` | `--number-of-prev-days-pa` | no | `10` | Days to scan for one-time PAs |

### CAAttributeRedisWriterMain — CA Attributes to Redis

| Flag | Long form | Required | Default | Purpose |
|------|-----------|----------|---------|---------|
| `-a` | `--env` | yes | — | Target environment |
| `-p` | `--parallel` | yes | — | Parallelism level |
| `-s` | `--pipeline` | yes | — | Pipeline batch size |
| `-t` | `--jobType` | yes | — | `users` or `bcookie` |
| `--log-prefix` | `--log-prefix` | no | — | Log prefix |
| `-c` | `--calibration` | no | false | Full calibration mode (reconcile all Redis keys) |

### CAAttributeBigTableWriterMain — CA Attributes to Bigtable

Same flags as `CAAttributeRedisWriterMain`.

### HiveToKeyspaceWriter — Hive-to-Keyspaces Retry

| Flag | Long form | Required | Default | Purpose |
|------|-----------|----------|---------|---------|
| `-a` | `--env` | yes | `uat-na` | Target environment |
| `-t` | `--payload-type` | no | `users` | Audience type |
| `-n` | `--number-of-prev-days` | no | `-1` | Days to scan |
| `-p` | `--pa-type` | no | `SAD` | PA type |
| `--log-prefix` | `--log-prefix` | no | — | Log prefix |
| `-s` | `--send-date` | yes | — | SAD table name (must contain `user_sad`) |
| `-h` | `--source-Hive-Table` | yes | — | Source Hive table name (must contain `user_sad`) |
| `-l` | `--limit` | no | `0` | Limit PA count |

## Rate Limits

> No rate limiting configured. Throughput is governed by Spark executor settings (`spark.cassandra.output.throughput_mb_per_sec`, `spark.cassandra.output.concurrent.writes`) set per region.

## Versioning

> No API versioning strategy applicable — this is a CLI/library interface. The JAR version is `1.56.5-SNAPSHOT` (`build.sbt`). Published to Artifactory as `com.groupon.audiencemanagement:audiencepayloadspark_2.12`.

## OpenAPI / Schema References

> No evidence found in codebase. Interface is defined by `scopt` argument parsers in each `Main` object.
