---
service: "logging-elasticstack"
title: "Index Lifecycle Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "index-lifecycle-flow"
flow_type: scheduled
trigger: "Continuous background evaluation by Elasticsearch ILM engine"
participants:
  - "continuumLoggingElasticsearch"
  - "awsS3Snapshots"
architecture_ref: "dynamic-logging-logstashPipeline-flow"
---

# Index Lifecycle Flow

## Summary

Elasticsearch manages the full lifecycle of log indices automatically using Index Lifecycle Management (ILM) policies. Indices begin in the hot phase accepting active writes, transition to warm phase for read-only compressed storage after a rollover threshold is met, and are eventually deleted after the configured retention period expires. Snapshots to AWS S3 can be triggered at any phase for backup and archival purposes.

## Trigger

- **Type**: schedule
- **Source**: Elasticsearch ILM engine — evaluates all managed indices against their assigned policy on a continuous polling interval (default 10 minutes)
- **Frequency**: Continuous background evaluation; transitions triggered when index conditions (age, doc count, size) meet policy thresholds

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Elasticsearch ILM Engine | Evaluates index conditions against ILM policy; executes phase transition actions (rollover, shrink, migrate, delete) | `continuumLoggingElasticsearch` |
| Elasticsearch Index | Subject of lifecycle management; transitions through hot/warm/delete phases | `continuumLoggingElasticsearch` |
| Logstash Pipeline | Active writer to hot-phase indices; continues writing to active write index | `continuumLoggingLogstash` |
| AWS S3 | Receives Elasticsearch snapshots for backup and long-term archival | `awsS3Snapshots` |

## Steps

1. **Create index with ILM policy**: When Logstash first writes a new sourcetype, Elasticsearch creates the index using the registered index template which assigns the ILM policy. The `default_ilm_managed: true` flag enables ILM enrollment.
   - From: `continuumLoggingLogstash`
   - To: `continuumLoggingElasticsearch`
   - Protocol: REST HTTP (`PUT /<index>` with index template application)

2. **Hot phase — active writes**: The index resides on hot-tier nodes and accepts writes from Logstash. The index remains hot until the rollover condition is met (age, document count, or size threshold defined in the ILM policy).
   - From: `continuumLoggingLogstash`
   - To: `continuumLoggingElasticsearch`
   - Protocol: REST HTTP (`_bulk` writes to hot-tier index)

3. **Rollover evaluation**: ILM evaluates the hot index against the rollover condition. When the condition is met, ILM creates a new write index and marks the current index as rolled over.
   - From: `elasticsearchIndexer` (ILM engine)
   - To: `elasticsearchIndexer` (index alias management)
   - Protocol: internal Elasticsearch ILM

4. **Warm phase transition**: The rolled-over index transitions to the warm phase. ILM migrates the index to warm-tier nodes, optionally shrinks the shard count, and force-merges segments for read-optimized storage. The index becomes read-only.
   - From: `elasticsearchIndexer` (ILM engine)
   - To: `elasticsearchIndexer` (warm-tier nodes)
   - Protocol: internal Elasticsearch ILM

5. **Post-rollover retention clock starts**: The `default_elasticsearch_post_rollover_retention_in_hours` value (default `384` hours / 16 days) begins counting from the rollover moment.
   - From: `elasticsearchIndexer` (ILM engine)
   - To: `elasticsearchIndexer` (index metadata)
   - Protocol: internal Elasticsearch ILM

6. **Optional snapshot to S3**: At any phase, an S3 snapshot can be triggered (scheduled or manual) via the `_snapshot` API using the registered S3 repository.
   - From: `continuumLoggingElasticsearch`
   - To: `awsS3Snapshots`
   - Protocol: AWS S3 API (via Elasticsearch S3 repository plugin using boto3-provisioned credentials)

7. **Delete phase — index deletion**: After the retention period expires, ILM deletes the index from the cluster, freeing disk space.
   - From: `elasticsearchIndexer` (ILM engine)
   - To: `elasticsearchIndexer` (index deletion)
   - Protocol: internal Elasticsearch ILM (`DELETE /<index>`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| ILM step stuck (action blocked by conditions) | Check `GET /<index>/_ilm/explain`; manually advance with `POST /_ilm/move/<index>` | Index manually moved to next phase; root cause (disk space, allocation filter) must be resolved first |
| Disk watermark reached before ILM deletion | Elasticsearch stops accepting writes on affected nodes (high watermark 95%); ILM accelerates deletion evaluation | Urgent: add disk capacity or force-delete old indices; log ingestion halts on affected node |
| Snapshot failure to S3 | Elasticsearch marks snapshot as FAILED; returns error in `_snapshot` status API | Snapshot retried or manually re-triggered; log data retained in cluster; investigate S3 credentials or network connectivity |
| Rollover condition never met | Index grows indefinitely on hot tier | Review and adjust ILM policy rollover conditions; manually trigger rollover via `POST /<alias>/_rollover` |

## Sequence Diagram

```
Logstash -> Elasticsearch: First write to sourcetype (index created via template)
Elasticsearch -> Elasticsearch: Assigns ILM policy; index enters hot phase
Logstash -> Elasticsearch: Continuous bulk writes to hot-tier index
Elasticsearch -> Elasticsearch: ILM evaluates rollover condition (age/size/docs)
Elasticsearch -> Elasticsearch: Rollover — creates new write index; old index marked rolled-over
Elasticsearch -> Elasticsearch: Migrates rolled-over index to warm tier (shrink, force-merge)
Elasticsearch -> S3: Snapshot index to registered S3 repository (scheduled/manual)
S3 --> Elasticsearch: Snapshot acknowledged
Elasticsearch -> Elasticsearch: Retention clock expires (384h post-rollover)
Elasticsearch -> Elasticsearch: ILM deletes index from cluster
```

## Related

- Architecture dynamic view: `dynamic-logging-logstashPipeline-flow`
- Related flows: [Log Ingestion and Search Flow](logging-ingestion-search-flow.md), [Log Source Onboarding Flow](log-source-onboarding-flow.md)
