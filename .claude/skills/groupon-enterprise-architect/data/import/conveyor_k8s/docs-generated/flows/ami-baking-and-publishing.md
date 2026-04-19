---
service: "conveyor_k8s"
title: "AMI Baking and Publishing"
generated: "2026-03-03"
type: flow
flow_name: "ami-baking-and-publishing"
flow_type: batch
trigger: "Jenkins `ami` pipeline job triggered manually or from main build pipeline"
participants:
  - "conveyorK8sPipelines"
  - "conveyorK8sAmiBaking"
  - "conveyorK8sPipelineUtils"
  - "aws"
architecture_ref: "dynamic-conveyorK8s"
---

# AMI Baking and Publishing

## Summary

This flow produces AWS machine images (AMIs) for EKS worker nodes and distributes them to all non-sandbox AWS accounts and regions. Packer is invoked to bake the AMI in the sandbox account, then the `ami_publish` Go binary copies the AMI to dev, stable, and production accounts in parallel. The resulting AMI IDs are made available to EKS cluster provisioning pipelines.

## Trigger

- **Type**: manual / pipeline-call
- **Source**: Jenkins `conveyor-cloud/ami` job triggered manually, or by the main `conveyor_k8s` Jenkins pipeline (`pipelines/ami.groovy`)
- **Frequency**: On-demand — triggered when `machine-image-baking/` content changes or a new AMI is needed for a cluster upgrade

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Conveyor K8s Pipelines | Orchestrates the baking and publishing steps | `conveyorK8sPipelines` |
| Machine Image Baking | Runs Packer to build the AMI in the sandbox AWS account | `conveyorK8sAmiBaking` |
| Pipeline Utils (ami_lookup, ami_publish) | Looks up built AMI IDs by SHA and publishes them cross-account | `conveyorK8sPipelineUtils` |
| AWS EC2 (sandbox) | Executes the Packer build; hosts the source AMI | `aws` (external stub) |
| AWS EC2 (dev/stable/production) | Receives copied AMIs | `aws` (external stub) |

## Steps

1. **Trigger bake job**: The Jenkins `ami.groovy` pipeline is triggered with a git ref and target regions.
   - From: `conveyorK8sPipelines`
   - To: `conveyorK8sAmiBaking`
   - Protocol: Jenkins job invocation (DSL)

2. **Run Packer build**: Packer executes the machine image template, creating an AMI in the sandbox AWS account. The AMI is tagged with the git SHA.
   - From: `conveyorK8sAmiBaking`
   - To: `aws` EC2 (sandbox account)
   - Protocol: Packer CLI / AWS API

3. **Look up built AMI IDs**: The `ami_lookup` binary queries EC2 for AMIs matching the git SHA across the target regions. It reads `REGIONS` and `SHA` from environment variables and outputs a JSON map of `{region: ami_id}`.
   - From: `conveyorK8sPipelineUtils`
   - To: `aws` EC2 (sandbox)
   - Protocol: AWS SDK (aws-sdk-go)

4. **Publish AMIs cross-account**: The `ami_publish` binary copies the AMI from the sandbox account to dev, stable, and production accounts for each region, in parallel goroutines. Sandbox is explicitly skipped (original AMIs already exist there).
   - From: `conveyorK8sPipelineUtils`
   - To: `aws` EC2 (dev, stable, production accounts)
   - Protocol: AWS SDK EC2 CopyImage API

5. **Report results**: Pipeline logs success or failure per region/environment and exits with non-zero on any copy failure.
   - From: `conveyorK8sPipelineUtils`
   - To: `conveyorK8sPipelines` (stdout / exit code)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMI not found for SHA | `ami_lookup` exits non-zero if `FAILNOTFOUND=true` | Pipeline fails; operator must re-trigger Packer bake |
| AMI copy failure in one environment | `ami_publish` returns error from goroutine; main process returns error | Pipeline fails; partial copies may exist; operator re-runs |
| EC2 API throttling | No explicit retry in `ami_publish` | Pipeline fails; operator re-runs |

## Sequence Diagram

```
ConveyorPipeline -> PackerBake: Invoke Packer build for SHA + regions
PackerBake -> AWS_EC2_Sandbox: Build AMI image
AWS_EC2_Sandbox --> PackerBake: AMI ID (per region)
PackerBake --> ConveyorPipeline: Bake complete

ConveyorPipeline -> ami_lookup: Lookup AMIs by SHA (REGIONS + SHA env vars)
ami_lookup -> AWS_EC2_Sandbox: DescribeImages filter by SHA tag
AWS_EC2_Sandbox --> ami_lookup: {region: amiId} map
ami_lookup --> ConveyorPipeline: JSON output

ConveyorPipeline -> ami_publish: Publish AMIs to [dev, stable, production]
ami_publish -> AWS_EC2_Dev: CopyImage (parallel per region)
ami_publish -> AWS_EC2_Stable: CopyImage (parallel per region)
ami_publish -> AWS_EC2_Production: CopyImage (parallel per region)
AWS_EC2_Dev --> ami_publish: Success
AWS_EC2_Stable --> ami_publish: Success
AWS_EC2_Production --> ami_publish: Success
ami_publish --> ConveyorPipeline: All copies complete
```

## Related

- Architecture dynamic view: `dynamic-conveyorK8s`
- Related flows: [Cluster Creation (GKE)](cluster-creation-gke.md) — consumes published AMIs for EKS worker node configuration
