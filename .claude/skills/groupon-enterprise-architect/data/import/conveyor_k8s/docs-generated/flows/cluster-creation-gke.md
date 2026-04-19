---
service: "conveyor_k8s"
title: "Cluster Creation (GKE)"
generated: "2026-03-03"
type: flow
flow_name: "cluster-creation-gke"
flow_type: batch
trigger: "Jenkins `create-cluster-conveyor` job triggered manually by an operator"
participants:
  - "conveyorK8sPipelines"
  - "conveyorK8sTerraformGke"
  - "conveyorK8sAnsiblePlaybooks"
  - "gcp"
  - "kubernetesClusters"
architecture_ref: "dynamic-conveyorK8s"
---

# Cluster Creation (GKE)

## Summary

This flow creates a complete, Conveyor-ready GKE Kubernetes cluster from scratch. The pipeline first uses Terraform/Terragrunt to provision all GCP infrastructure (GKE cluster, node pools, GCS bucket, IAM configuration), then applies Ansible provisioning playbooks to install and configure Conveyor platform services (Prometheus, Open Policy Agent, webhooks, etc.) on the new cluster. Optionally, end-to-end integration tests are run before the cluster is considered ready.

## Trigger

- **Type**: manual
- **Source**: Jenkins `conveyor-cloud/create-cluster-conveyor` job; operator supplies `ENVIRONMENT`, `CLUSTER_TYPE`, `CLUSTER_NAME`, and region parameters
- **Frequency**: On-demand — when a new cluster is needed for an environment or region

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Conveyor K8s Pipelines | Orchestrates the creation and configuration steps | `conveyorK8sPipelines` |
| Conveyor GKE Terraform | Provisions GCP infrastructure using Terragrunt | `conveyorK8sTerraformGke` |
| Conveyor Provisioning Playbooks | Configures the newly created cluster with Conveyor services | `conveyorK8sAnsiblePlaybooks` |
| GCP GKE | Hosts the Kubernetes control plane and node pools | `gcp` (external stub) |
| GCP GCS | Stores Terraform remote state for all GKE modules | `gcp` (external stub) |
| Kubernetes Cluster | Target of Ansible configuration | `kubernetesClusters` (external stub) |

## Steps

1. **Checkout and set build description**: Jenkins checks out the repository; pipeline sets the build description with environment, region, and cluster name.
   - From: `conveyorK8sPipelines`
   - To: Jenkins SCM
   - Protocol: Git

2. **Apply Terraform (GKE infrastructure)**: Terragrunt applies all GKE modules (`gke-cluster`, `gcs`, `git_info`, `uuid`) for the target environment and region. Cross-module state is read from GCS. GCP resources (control plane, node pools, VPC peering, service account bindings) are created.
   - From: `conveyorK8sPipelines` → `conveyorK8sTerraformGke`
   - To: `gcp` GKE/GCS APIs
   - Protocol: Terraform CLI / GCP provider API

3. **Retrieve cluster credentials**: Pipeline retrieves the GKE cluster endpoint and CA certificate from Terraform outputs; kubeconfig is generated.
   - From: `conveyorK8sTerraformGke`
   - To: `gcp` GKE
   - Protocol: GCP API (`google_container_cluster` data source)

4. **Apply Ansible provisioning playbooks**: The pipeline triggers `conveyor-cloud/gke/apply-playbook` (Jenkins job) or calls `ansible-playbook` directly with the `kube.yml` playbook and GCP dynamic inventory (`inventory/gcp_grpn.py`), limited to the new cluster. This installs Prometheus, OPA, webhooks, and other Conveyor platform services.
   - From: `conveyorK8sPipelines` → `conveyorK8sAnsiblePlaybooks`
   - To: `kubernetesClusters` (Kubernetes API)
   - Protocol: Ansible / Kubernetes API

5. **Run integration tests** (optional, `RUN_INTEGRATION_TESTS=true`): End-to-end tests are executed against the new cluster via `conveyor-cloud/test-cluster-conveyor` Jenkins job.
   - From: `conveyorK8sPipelines`
   - To: `kubernetesClusters`
   - Protocol: HTTP / Kubernetes API

6. **Report completion**: Pipeline publishes the cluster name and status; cluster is available for use or promotion.
   - From: `conveyorK8sPipelines`
   - To: Operator (Jenkins build log, optional GChat notification)
   - Protocol: Jenkins build result

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Terraform apply fails | Pipeline fails with error; partial GCP resources may exist | Operator must inspect Terraform state and re-apply or manually clean up |
| Ansible playbook task fails | `ansible-playbook` exits non-zero; pipeline fails | Operator must fix the failing task and re-run the provisioning playbook |
| Integration tests fail | Pipeline fails; cluster may still exist | Operator reviews test output; may need to fix cluster config or delete and recreate |
| GCP authentication fails | GitHub Actions gcp-auth step fails immediately | Operator checks `GCP_SERVICE_ACCOUNT_JSON` secret validity |

## Sequence Diagram

```
Operator -> Jenkins: Trigger create-cluster-conveyor job (ENVIRONMENT, CLUSTER_NAME, REGION)
Jenkins -> Terragrunt: run-all apply (terra-gke/ modules)
Terragrunt -> GCP_GKE: Create GKE cluster + node pools
Terragrunt -> GCP_GCS: Write Terraform remote state
GCP_GKE --> Terragrunt: Cluster endpoint + CA certificate
Terragrunt --> Jenkins: Terraform apply complete

Jenkins -> AnsiblePlaybooks: ansible-playbook kube.yml --limit <cluster_name>
AnsiblePlaybooks -> KubernetesCluster: Install Prometheus, OPA, webhooks, etc.
KubernetesCluster --> AnsiblePlaybooks: Configuration applied
AnsiblePlaybooks --> Jenkins: Playbooks complete

Jenkins -> TestCluster: Run integration tests (optional)
TestCluster --> Jenkins: Tests passed / failed
Jenkins --> Operator: Cluster ready (build result)
```

## Related

- Architecture dynamic view: `dynamic-conveyorK8s`
- Related flows: [Cluster Promotion](cluster-promotion.md) — uses created clusters as source/destination; [Ansible Playbook Deployment (GitOps)](ansible-playbook-deployment-gitops.md) — ongoing configuration of existing clusters
