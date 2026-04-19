---
service: "deal-performance-bucketing-and-export-pipelines"
title: "Experiment Event Decoration"
generated: "2026-03-03"
type: flow
flow_name: "experiment-event-decoration"
flow_type: batch
trigger: "Sub-step within UserDealBucketingPipeline (triggered as part of DpsUserDealBucketingTask)"
participants:
  - "continuumDealPerformanceDataPipelines"
  - "hdfsCluster"
architecture_ref: "dynamic-continuumDealPerformanceDataPipelines"
---

# Experiment Event Decoration

## Summary

The Experiment Event Decoration flow is a sub-pipeline embedded within the `UserDealBucketingPipeline`. It reads A/B experiment participation records (experiment instances) from the Janus HDFS data store, validates and filters them by experiment name prefix, then joins them to deal events by `bcookie` to attribute each deal event to an experiment ID. This enables deal performance metrics to be bucketed by experiment segment, supporting A/B test analysis for the Relevance Ranking team.

## Trigger

- **Type**: sub-step within parent batch pipeline
- **Source**: `UserDealBucketingPipeline.readExperimentEvents()` — called per event-config directory during `DpsUserDealBucketingTask`
- **Frequency**: Hourly, co-scheduled with the parent bucketing pipeline; independently enable/disable-able via `eventDecorationPipelineConfig.enabled`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| EventDecorationPipeline (config) | Provides configuration for HDFS URL, input path, hour format, experiment prefix | `continuumDealPerformanceDataPipelines` |
| AbExperimentHDFSReadTransform | Reads ExperimentInstance Avro records from Janus HDFS, filtered by experiment name prefix | `continuumDealPerformanceDataPipelines` / `hdfsCluster` |
| AbExperimentHDFSPersistenceDoFn | (Optional) Persists intermediate experiment data | `continuumDealPerformanceDataPipelines` |
| Janus / HDFS | Source of experiment participation data | `hdfsCluster` |
| DecorationJoinDoFn | Joins deal events and experiment instances by bcookie via CoGroupByKey | `continuumDealPerformanceDataPipelines` |

## Steps

1. **Check if decoration is enabled**: `eventDecorationPipelineConfig.enabled` is read. If `false`, an empty `PCollection<ExperimentInstance>` is returned immediately and no Janus read is performed.
   - From: `UserDealBucketingPipeline`
   - To: `UserDealBucketingPipeline`
   - Protocol: direct (config check)

2. **Compute experiment directories from deal event directories**: For each deal event directory path, derives the corresponding Janus experiment directory using the date-hour partition format (`/ds={date}/hour={hour}`).
   - From/To: `UserDealBucketingPipeline`
   - Protocol: direct (string computation)

3. **Validate experiment directories exist**: `TimeBasedDirectoryFilter.validateDirs()` checks that each derived Janus directory exists in HDFS. Missing directories are excluded (non-strict validation — missing dirs log a warning rather than failing).
   - From: `UserDealBucketingPipeline`
   - To: HDFS/Janus (`hdfsCluster`)
   - Protocol: HDFS FileSystem API

4. **Read experiment instances**: `AbExperimentHDFSReadTransform` reads Avro `ExperimentInstance` records from validated Janus HDFS directories, applying the experiment name prefix filter `relevance-explore-exploit-` to include only relevant experiments.
   - From: HDFS/Janus (`hdfsCluster`)
   - To: `UserDealBucketingPipeline`
   - Protocol: HDFS API (Avro)

5. **Key experiment instances by bcookie**: `ExperimentInstance` records are keyed by `bcookie` for the CoGroupByKey join. Records with null bcookie are assigned the placeholder key `NO_BCOOKIE_FOUND_IN_EXPERIMENT`.
   - From/To: `UserDealBucketingPipeline`
   - Protocol: direct (in-process Beam)

6. **CoGroupByKey join with deal events**: `DecorationJoinDoFn` performs the join of deal events and experiment instances keyed by bcookie. Matching experiment IDs are attributed to the `DecoratedDealEvent`.
   - From/To: `UserDealBucketingPipeline`
   - Protocol: direct (in-process Beam `CoGroupByKey`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Decoration disabled (`enabled: false`) | Empty experiment collection returned immediately | Bucketing proceeds without experiment ID attribution |
| Janus directory not found for date-hour | Warning logged; directory excluded from processing | Events for that hour bucketed without experiment attribution |
| No experiment data read for all directories | Warning logged with both expected and validated directory lists; empty collection returned | Bucketing proceeds without experiment attribution |
| ExperimentInstance missing bcookie | Assigned placeholder key `NO_BCOOKIE_FOUND_IN_EXPERIMENT`; will not match any deal event | Effectively dropped from join |

## Sequence Diagram

```
UserDealBucketingPipeline -> EventDecorationConfig: Check enabled flag
EventDecorationConfig --> UserDealBucketingPipeline: enabled = true
UserDealBucketingPipeline -> UserDealBucketingPipeline: Derive experiment dirs from deal event dirs
UserDealBucketingPipeline -> HDFS/Janus (hdfsCluster): Validate directory existence
HDFS/Janus (hdfsCluster) --> UserDealBucketingPipeline: Valid directory list
UserDealBucketingPipeline -> HDFS/Janus (hdfsCluster): Read ExperimentInstance Avro records (prefix: relevance-explore-exploit-)
HDFS/Janus (hdfsCluster) --> UserDealBucketingPipeline: ExperimentInstance PCollection
UserDealBucketingPipeline -> UserDealBucketingPipeline: Key by bcookie
UserDealBucketingPipeline -> UserDealBucketingPipeline: CoGroupByKey join with deal events (DecorationJoinDoFn)
UserDealBucketingPipeline --> UserDealBucketingPipeline: DecoratedDealEvent PCollection (with experiment attribution)
```

## Related

- Architecture dynamic view: `dynamic-continuumDealPerformanceDataPipelines`
- Related flows: [Deal Event Bucketing](deal-event-bucketing.md)
