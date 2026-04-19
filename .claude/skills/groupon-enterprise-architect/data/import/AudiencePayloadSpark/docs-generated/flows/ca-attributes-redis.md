---
service: "AudiencePayloadSpark"
title: "CA Attributes to Redis"
generated: "2026-03-03"
type: flow
flow_name: "ca-attributes-redis"
flow_type: batch
trigger: "Daily cron job or manual Fabric command"
participants:
  - "continuumAudiencePayloadOps"
  - "continuumAudiencePayloadSpark"
  - "hiveMetastore"
  - "redisCluster"
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumAudiencePayloadSpark", "continuumAudiencePayloadOps"]
architecture_ref: "dynamic-payload_generation_flow"
---

# CA Attributes to Redis

## Summary

The CA (Consumer Authority) attributes to Redis flow reads daily consumer attribute data from the Hive table `cia_realtime.user_attr_daily`, computes a versioned schema hash, writes metadata keys and per-consumer attribute rows into Redis, and then performs a delta cleanup to remove any consumer IDs present in yesterday's dataset but absent from today's. A calibration mode performs a full Redis scan-and-reconcile instead of the delta approach. The result is a Redis store keyed by consumer_id containing the latest versioned attribute values, consumed by the RTCIA service for low-latency attribute lookups.

## Trigger

- **Type**: schedule / manual
- **Source**: Daily cron on `cerebro-audience-job-submitter1.snc1` (production) or `fab production:na upload_ca_redis:users`
- **Frequency**: Daily (cron: `36 21 * * *`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cron / Fabric scripts (`continuumAudiencePayloadOps`) | Submits `spark-submit` job | `continuumAudiencePayloadOps` |
| `CAAttributeRedisWriterMain` | Spark entrypoint; parses args, builds SparkSession | `caAttributeRedisWriterMain` |
| Hive Metastore (`cia_realtime.user_attr_daily`) | Source table of current CA consumer attributes | `hiveMetastore` |
| `RedisClientV2` (Lettuce + Jedis) | Writes versioned metadata and per-consumer data to Redis; removes stale keys | `redisAccessLayer` |
| Redis Cluster | Target store — `consumer-authority-user--redis.prod.prod.us-west-1.aws.groupondev.com:6379` | `redisCluster` |

## Steps

1. **Submit job**: Cron or `fab production:na upload_ca_redis:users` triggers `submit_consumer_attributes_redis.py`.
   - From: cron / `fabricTasks`
   - To: `submitCaRedisScript` → `spark-submit`
   - Protocol: spark-submit

2. **Load CA attributes from Hive**: Executes `SELECT consumer_id, <ca_attributes> FROM cia_realtime.user_attr_daily WHERE consumer_id IS NOT NULL`. In staging, `sampleRate=0.01` limits to 1% of consumers.
   - From: `caAttributeRedisWriterMain`
   - To: `hiveMetastore`
   - Protocol: Spark SQL

3. **Compute version hash**: Sorts attribute names alphabetically; computes SHA-256 of concatenated `attrNamesStr + attrTypeValues` to produce a `version` string.
   - From: `caAttributeRedisWriterMain` (`getChecksum`)
   - Protocol: in-memory (Java `MessageDigest.SHA-256`)

4. **Write metadata keys to Redis**: Writes three metadata records:
   - `latest-version` → `version` (SHA-256 hash)
   - `name-<version>` → `<updatedAt>!attr1!attr2!...`
   - `type-<version>` → `type1!type2!...`
   - From: `caAttributeRedisWriterMain`
   - To: `redisCluster` (via `RedisClientV2.writeKeyValue`)
   - Protocol: Redis SET

5. **Write per-consumer data rows to Redis**: Pipeline-writes all consumer rows as `consumer_id → version,val1,val2,...`. Parallelism and pipeline batch size are configurable CLI arguments.
   - From: `redisAccessLayer` (`RedisClientV2.writeDf`)
   - To: `redisCluster`
   - Protocol: Redis pipelined SET

6. **Delta cleanup (normal mode)**: Loads yesterday's Hive tracking table `user_attr_daily_consumer_id_last`, computes `leftanti` diff against today's consumer IDs, validates diff ratio <= 10% (`DiffRatioThreshold`), and calls `redisClient.removeKeys()` to delete stale consumer_id keys.
   - From: `caAttributeRedisWriterMain` (`removeExtraConsumerIds`)
   - To: `redisCluster`
   - Protocol: Redis DEL (via pipeline)

7. **Update Hive tracking tables**: Renames `user_attr_daily_consumer_id` to `user_attr_daily_consumer_id_last`, then saves today's consumer IDs as a new `user_attr_daily_consumer_id` Parquet table.
   - From: `caAttributeRedisWriterMain`
   - To: `hiveMetastore`
   - Protocol: Spark SQL (`ALTER TABLE RENAME`, `saveAsTable`)

### Calibration Mode (Full Reconcile)

When `--calibration` flag is set, step 6 is replaced by a full Redis scan:
- Calls `redisClient.getDbSize()` to determine batch count (`ScanBatchSize = 2,000,000` keys/batch)
- Iterates all Redis keys via `SCAN` in batches
- For each batch, performs a Spark SQL `leftanti` join against today's consumer IDs
- Deletes any Redis key not present in today's Hive table

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Diff ratio >= 10% (too many removals) | Exception thrown with diff stats | Job fails; operator re-runs with `calibration` flag if intentional |
| Redis write failure | Exception propagated from `RedisClientV2` | Spark job fails; attributes may be partially written |
| Hive table missing (`user_attr_daily_consumer_id`) | Condition check — if table absent, skip delta cleanup | No cleanup performed; safe for first-time runs |
| Spark job failure before tracking table rename | Next run will start fresh delta cycle | Stale keys may persist until next calibration run |

## Sequence Diagram

```
Cron              -> submitCaRedisScript  : /home/.../submit_consumer_attributes.py production na users
submitCaRedisScript -> CAAttributeRedisWriterMain : spark-submit --env production-na --jobType users
CAAttributeRedisWriterMain -> HiveMetastore : SELECT consumer_id, <attrs> FROM cia_realtime.user_attr_daily
HiveMetastore     --> CAAttributeRedisWriterMain : DataFrame
CAAttributeRedisWriterMain -> CAAttributeRedisWriterMain : computeVersionHash(attrNames + types)
CAAttributeRedisWriterMain -> RedisCluster  : SET latest-version = <hash>
CAAttributeRedisWriterMain -> RedisCluster  : SET name-<hash> = <timestamp>!attr1!attr2!...
CAAttributeRedisWriterMain -> RedisCluster  : SET type-<hash> = type1!type2!...
CAAttributeRedisWriterMain -> RedisCluster  : pipelined SET <consumer_id> = <hash>,val1,val2,... (for all consumers)
CAAttributeRedisWriterMain -> HiveMetastore : SELECT consumer_id FROM user_attr_daily_consumer_id (yesterday)
HiveMetastore     --> CAAttributeRedisWriterMain : yesterday's DataFrame
CAAttributeRedisWriterMain -> CAAttributeRedisWriterMain : diff(yesterday - today) [validate ratio < 10%]
CAAttributeRedisWriterMain -> RedisCluster  : DEL <stale_consumer_ids>
CAAttributeRedisWriterMain -> HiveMetastore : DROP user_attr_daily_consumer_id_last; RENAME user_attr_daily_consumer_id
CAAttributeRedisWriterMain -> HiveMetastore : saveAsTable user_attr_daily_consumer_id (today's IDs)
```

## Related

- Architecture dynamic view: `dynamic-payload_generation_flow`
- Related flows: [Attribute Payload Upload](attribute-payload-upload.md)
