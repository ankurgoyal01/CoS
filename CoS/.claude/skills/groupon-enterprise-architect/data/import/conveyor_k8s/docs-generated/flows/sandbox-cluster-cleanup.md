---
service: "conveyor_k8s"
title: "Sandbox Cluster Cleanup"
generated: "2026-03-03"
type: flow
flow_name: "sandbox-cluster-cleanup"
flow_type: scheduled
trigger: "Jenkins scheduled job (`sandbox-cleanup` pipeline) runs automatically on a schedule"
participants:
  - "conveyorK8sPipelines"
  - "conveyorK8sPipelineUtils"
  - "aws"
architecture_ref: "dynamic-conveyorK8s"
---

# Sandbox Cluster Cleanup

## Summary

Sandbox clusters are created on demand for PR testing and development but must be cleaned up to control infrastructure costs. The sandbox cleanup pipeline uses `find_clusters` to discover stale or old sandbox clusters and then triggers deletion jobs for each. The `find_clusters` binary queries S3 state buckets to enumerate existing sandbox clusters and filter for those eligible for cleanup based on age or status.

## Trigger

- **Type**: schedule
- **Source**: Jenkins `conveyor-cloud/sandbox-cleanup` job, run on a schedule (configured in Jenkins; not a cron in this repository)
- **Frequency**: Scheduled (runs automatically on a recurring basis — exact schedule managed in Jenkins configuration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Conveyor K8s Pipelines | Orchestrates sandbox discovery and deletion triggers | `conveyorK8sPipelines` |
| Pipeline Utils (`find_clusters`) | Discovers existing sandbox clusters via S3 bucket tags | `conveyorK8sPipelineUtils` |
| AWS S3 | Cluster state buckets identifying sandbox cluster metadata | `aws` (external stub) |
| AWS EKS / GCP GKE | Target clusters for deletion | `aws` / `gcp` (external stubs) |

## Steps

1. **Trigger cleanup job**: The Jenkins scheduler starts `sandbox-cleanup.groovy` on schedule.
   - From: Jenkins scheduler
   - To: `conveyorK8sPipelines`
   - Protocol: Jenkins scheduling

2. **Discover sandbox clusters**: The pipeline calls `find_clusters` with sandbox-appropriate filters (e.g., region, cluster name prefix for sandbox) to retrieve the current list of sandbox clusters from S3 state buckets.
   - From: `conveyorK8sPipelines` → `conveyorK8sPipelineUtils`
   - To: `aws` S3
   - Protocol: AWS SDK (ListBuckets, GetBucketTagging)

3. **Filter stale clusters**: The pipeline identifies clusters eligible for cleanup based on age (creation date) or other criteria defined in the cleanup policy within `sandbox-cleanup.groovy`.
   - From: `conveyorK8sPipelines`
   - To: (in-process evaluation)
   - Protocol: direct

4. **Trigger deletion for each stale cluster**: For each stale sandbox cluster identified, the pipeline triggers the appropriate delete job (`delete-cluster-eks.groovy` or `pipelines/gke/delete-cluster-gke.groovy`) with the cluster name and region.
   - From: `conveyorK8sPipelines`
   - To: `conveyorK8sPipelines` (delete sub-pipeline)
   - Protocol: Jenkins job invocation

5. **Delete cluster resources**: The deletion pipeline invokes Terraform destroy for the target cluster's modules, removing EKS/GKE resources, associated S3 buckets, and IAM/service account bindings.
   - From: `conveyorK8sPipelines`
   - To: `aws` EKS / `gcp` GKE
   - Protocol: Terraform CLI / cloud API

6. **Report cleanup results**: The cleanup job logs which clusters were deleted and which (if any) failed, producing a build summary.
   - From: `conveyorK8sPipelines`
   - To: Jenkins build log / GChat (optional notification)
   - Protocol: Jenkins build result

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `find_clusters` returns empty list | No deletion triggered; job succeeds | No-op; sandbox already clean |
| Deletion job fails for one cluster | Error logged; cleanup continues for remaining clusters | Failed cluster remains; operator must manually investigate and delete |
| AWS S3 list fails | `find_clusters` panics; cleanup job fails | No deletion triggered; operator checks AWS credentials |

## Sequence Diagram

```
JenkinsScheduler -> sandbox_cleanup: Trigger scheduled cleanup
sandbox_cleanup -> find_clusters: Execute (--prefix sandbox, --region us-west-2)
find_clusters -> AWS_S3: ListBuckets + GetBucketTagging
AWS_S3 --> find_clusters: Sandbox cluster list (with creation dates)
find_clusters --> sandbox_cleanup: JSON cluster list

sandbox_cleanup -> sandbox_cleanup: Filter clusters older than threshold
sandbox_cleanup -> delete_cluster: Trigger delete job for cluster A
delete_cluster -> AWS_EKS: Terraform destroy (cluster A modules)
AWS_EKS --> delete_cluster: Resources deleted
delete_cluster --> sandbox_cleanup: Cluster A deleted

sandbox_cleanup -> delete_cluster: Trigger delete job for cluster B
delete_cluster -> AWS_EKS: Terraform destroy (cluster B modules)
AWS_EKS --> delete_cluster: Resources deleted
delete_cluster --> sandbox_cleanup: Cluster B deleted

sandbox_cleanup --> JenkinsScheduler: Cleanup complete (build result)
```

## Related

- Architecture dynamic view: `dynamic-conveyorK8s`
- Related flows: [Cluster Discovery](cluster-discovery.md) — the `find_clusters` binary used in this flow is described in detail there; [Cluster Creation (GKE)](cluster-creation-gke.md) — creates the sandbox clusters this flow cleans up
