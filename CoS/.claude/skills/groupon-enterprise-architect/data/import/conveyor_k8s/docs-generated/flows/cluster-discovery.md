---
service: "conveyor_k8s"
title: "Cluster Discovery"
generated: "2026-03-03"
type: flow
flow_name: "cluster-discovery"
flow_type: synchronous
trigger: "Pipeline step invokes `find_clusters` binary with filtering criteria"
participants:
  - "conveyorK8sPipelineUtils"
  - "aws"
architecture_ref: "dynamic-conveyorK8s"
---

# Cluster Discovery

## Summary

Cluster discovery enables promotion and rollback pipelines to resolve cluster references (by SHA, version, name prefix, and region) without hard-coding cluster names. The `find_clusters` Go binary queries all Conveyor-tagged S3 buckets in `us-west-2`, reads their metadata tags, and returns a filtered JSON list of matching clusters. This is a synchronous, on-demand operation invoked as a pipeline step.

## Trigger

- **Type**: pipeline-call (CLI invocation)
- **Source**: Jenkins promotion and cluster management pipelines invoke `find_clusters` as a shell step
- **Frequency**: On-demand — called during pipeline execution when cluster names need to be resolved

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pipeline Utils (`find_clusters`) | Queries S3 cluster state buckets and applies filters | `conveyorK8sPipelineUtils` |
| AWS S3 (us-west-2) | Stores Conveyor cluster state buckets tagged with cluster metadata | `aws` (external stub) |

## Steps

1. **Invoke find_clusters binary**: The pipeline calls `find_clusters` with filtering flags:
   - `--sha <git_sha>` — restrict by git commit SHA tag
   - `--version <semver>` — restrict by version tag
   - `--prefix <name_prefix>` — restrict by cluster name prefix
   - `--region <aws_region>` — restrict by region tag
   - `--exclude-clusters <cluster1,cluster2>` — exclude known clusters (e.g., source cluster when looking for destination)
   - `--last` — return only the most recent matching cluster
   - From: `conveyorK8sPipelines`
   - To: `conveyorK8sPipelineUtils`
   - Protocol: CLI exec

2. **Get all Conveyor S3 buckets**: `find_clusters` initialises an S3 client in `us-west-2` and calls `GetConveyorBuckets` which lists all S3 buckets and filters for those following the Conveyor naming convention.
   - From: `conveyorK8sPipelineUtils`
   - To: `aws` S3
   - Protocol: AWS SDK (ListBuckets)

3. **Read bucket tags per cluster**: For each candidate bucket, `GetBucketTagSet` retrieves the tag set. Tags include `KubernetesCluster`, `SHA`, `Version`, and `Region`. The `Cluster` struct is populated from these tags.
   - From: `conveyorK8sPipelineUtils`
   - To: `aws` S3
   - Protocol: AWS SDK (GetBucketTagging)

4. **Apply filters**: The in-memory list of clusters is filtered against all provided criteria (SHA, version, prefix, region, exclusion set). Results are sorted by creation date.
   - From: `conveyorK8sPipelineUtils`
   - To: (in-process)
   - Protocol: direct

5. **Return JSON output**: The filtered cluster list (or last single cluster if `--last`) is marshalled to JSON and printed to stdout. The calling pipeline captures this output.
   - From: `conveyorK8sPipelineUtils`
   - To: `conveyorK8sPipelines`
   - Protocol: stdout / shell

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No clusters match criteria | Returns empty JSON array | Pipeline receives empty list; calling script decides behaviour |
| AWS S3 API error (list buckets) | `panic(err)` — process exits non-zero | Pipeline step fails; operator checks AWS credentials and bucket permissions |
| AWS S3 API error (get tags) | Error logged; bucket skipped | Cluster not included in results; may miss matching clusters |
| JSON marshal error | `panic(err)` | Pipeline step fails |

## Sequence Diagram

```
Jenkins -> find_clusters: Execute binary (--sha, --version, --prefix, --region, --exclude, --last)
find_clusters -> AWS_S3: ListBuckets (us-west-2)
AWS_S3 --> find_clusters: All bucket names + creation dates
find_clusters -> AWS_S3: GetBucketTagging (for each Conveyor bucket)
AWS_S3 --> find_clusters: {KubernetesCluster, SHA, Version, Region} tags
find_clusters -> find_clusters: Apply filters (SHA, version, prefix, region, exclusions)
find_clusters -> find_clusters: Sort by CreationDate
find_clusters --> Jenkins: JSON array of matching Cluster objects
```

## Related

- Architecture dynamic view: `dynamic-conveyorK8s`
- Related flows: [Cluster Promotion](cluster-promotion.md) — uses cluster discovery to resolve source and destination cluster names
