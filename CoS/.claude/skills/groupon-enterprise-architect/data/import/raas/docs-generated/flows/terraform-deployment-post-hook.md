---
service: "raas"
title: "Terraform Deployment Post-Hook"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "terraform-deployment-post-hook"
flow_type: event-driven
trigger: "Operator runs post-Terraform reporting hook after a Terraform apply"
participants:
  - "continuumRaasTerraformAfterhookService"
  - "continuumRaasElastiCacheApi"
architecture_ref: "components-continuumRaasTerraformAfterhookService"
---

# Terraform Deployment Post-Hook

## Summary

The Terraform Deployment Post-Hook flow runs after a Terraform apply operation on Redis infrastructure. It processes the Terraform diff output to compute operational deltas, generates static report pages for RaaS dashboards, and validates that alerting prerequisites (such as SNS subscription state) are correctly configured for the newly deployed or modified ElastiCache resources.

## Trigger

- **Type**: manual / event-driven
- **Source**: Operator invokes the Terraform Afterhook after a `terraform apply` completes
- **Frequency**: On-demand, triggered per Terraform deployment

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Terraform Diff Processor | Loads Terraform outputs and computes operational deltas | `continuumRaasTerraformAfterhookService` |
| Pages Generator | Generates static report assets for RaaS dashboards | `continuumRaasTerraformAfterhookService` |
| AWS ElastiCache API | Provides SNS subscription state for alerting prerequisite checks | `continuumRaasElastiCacheApi` |
| Administrator | Initiates the post-hook and reviews generated reports | (operator) |

## Steps

1. **Receive Terraform outputs**: The operator runs the post-hook; the Terraform Diff Processor loads Terraform apply outputs and state files.
   - From: Administrator
   - To: `continuumRaasTerraformAfterhookService_raasTerraformDiffProcessor`
   - Protocol: CLI invocation

2. **Compute operational deltas**: The Terraform Diff Processor analyzes the Terraform diff to identify added, removed, or modified Redis cluster resources.
   - From: `continuumRaasTerraformAfterhookService_raasTerraformDiffProcessor`
   - To: (internal processing)
   - Protocol: In-process

3. **Check SNS subscription state**: The Terraform Afterhook queries the AWS ElastiCache API to verify that SNS alerting subscriptions are correctly configured for the affected resources.
   - From: `continuumRaasTerraformAfterhookService`
   - To: `continuumRaasElastiCacheApi`
   - Protocol: AWS SDK

4. **Generate static report pages**: The Pages Generator produces static report assets from the computed deltas for consumption by RaaS dashboards.
   - From: `continuumRaasTerraformAfterhookService_raasTerraformDiffProcessor`
   - To: `continuumRaasTerraformAfterhookService_raasPagesGenerator`
   - Protocol: In-process

5. **Output reports**: Generated static report pages are written to the configured output path for dashboard consumption.
   - From: `continuumRaasTerraformAfterhookService_raasPagesGenerator`
   - To: Report output directory
   - Protocol: Filesystem write

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Terraform output files missing or malformed | Diff Processor fails to parse; hook exits with error | No report generated; operator must re-run after verifying Terraform state |
| ElastiCache API unreachable | SNS subscription check fails; hook logs warning | Reports may be generated without SNS validation; alerting prerequisites unverified |
| Pages Generator failure | Report generation aborts; static files not written | Dashboard does not update; operator must manually re-run the post-hook |

## Sequence Diagram

```
Administrator                               -> continuumRaasTerraformAfterhookService : Run post-terraform hook
continuumRaasTerraformAfterhookService      -> continuumRaasTerraformAfterhookService : Load Terraform outputs and compute deltas
continuumRaasTerraformAfterhookService      -> continuumRaasElastiCacheApi            : Check SNS subscription state
continuumRaasElastiCacheApi                 --> continuumRaasTerraformAfterhookService : Return SNS state
continuumRaasTerraformAfterhookService      -> PagesGenerator                         : Generate static report assets
PagesGenerator                              --> continuumRaasTerraformAfterhookService : Report pages written
continuumRaasTerraformAfterhookService      --> Administrator                          : Post-hook complete; reports available
```

## Related

- Architecture dynamic view: `components-continuumRaasTerraformAfterhookService`
- Related flows: [Kubernetes Config Sync](kubernetes-config-sync.md), [Redis Database Provisioning](redis-database-provisioning.md)
