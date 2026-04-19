---
service: "conveyor_k8s"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "conveyorK8sPipelines"
    - "conveyorK8sTerraformEks"
    - "conveyorK8sTerraformGke"
    - "conveyorK8sAnsiblePlaybooks"
    - "conveyorK8sAmiBaking"
    - "conveyorK8sPipelineUtils"
---

# Architecture Context

## System Context

Conveyor K8s sits within the Continuum Platform as the cluster lifecycle layer that all Groupon engineering teams depend on. It is orchestrated by Jenkins and GitHub Actions CI systems and drives infrastructure changes into AWS EKS and GCP GKE. It does not serve user-facing traffic; instead it produces the Kubernetes clusters and configurations on which all other Conveyor-managed services run. The pipeline layer invokes Terraform for cloud resource provisioning, Ansible for cluster-level configuration, and Go utility binaries for operational tasks such as AMI management, cluster discovery, readiness verification, and promotion state tracking.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Conveyor K8s Pipelines | `conveyorK8sPipelines` | Pipeline | Jenkins/GitHub Actions | conveyor-pipeline-dsl v1.0.167 | Jenkins (Groovy) and GitHub Actions pipeline definitions for cluster lifecycle, promotion, and automation |
| Conveyor EKS Terraform | `conveyorK8sTerraformEks` | IaC | Terraform | >= 0.13 | Terraform modules and Terragrunt configuration for Amazon EKS clusters (`terra-eks/`) |
| Conveyor GKE Terraform | `conveyorK8sTerraformGke` | IaC | Terraform | >= 1.7.5 | Terraform modules and Terragrunt configuration for Google GKE clusters (`terra-gke/`) |
| Conveyor Provisioning Playbooks | `conveyorK8sAnsiblePlaybooks` | Configuration management | Ansible | (runtime image) | Ansible playbooks for Kubernetes cluster provisioning and post-boot configuration (`conveyor_provisioning_playbook/`) |
| Machine Image Baking | `conveyorK8sAmiBaking` | Image factory | Packer | 1.6.5 | Packer templates and automation for building AMIs for EKS worker nodes (`machine-image-baking/`) |
| Pipeline Utils | `conveyorK8sPipelineUtils` | CLI toolset | Go | 1.24 | Go utility binaries (`ami_lookup`, `ami_publish`, `find_clusters`, `services_readiness`, `changelog`, `wavefront`, `promotion`) used by CI/CD pipelines |

## Components by Container

### Pipeline Utils (`conveyorK8sPipelineUtils`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `ami_lookup` | Looks up AMI IDs by git SHA and region from AWS EC2 | Go, AWS SDK |
| `ami_publish` | Copies AMIs from the sandbox account to other environments (dev, stable, production) in parallel | Go, AWS SDK |
| `find_clusters` | Queries AWS S3 Conveyor state buckets to discover clusters by SHA, version, prefix, and region | Go, AWS SDK |
| `services_readiness` | Polls Kubernetes LoadBalancer services on a destination cluster and compares against a source cluster to verify promotion readiness | Go, k8s client-go |
| `wavefront` | Creates and closes Wavefront events for deployment observability during promotions | Go, HTTP |
| `promotion` | Reads and writes cluster promotion metadata (status, source/destination cluster, eligible-time) into Kubernetes ConfigMaps | Go, k8s client-go |
| `changelog` | Generates changelog output for releases | Go |

### Conveyor K8s Pipelines (`conveyorK8sPipelines`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `Jenkinsfile` (main) | Runs PR and merge-build CI: validates Terraform plans, applies Ansible roles to dev clusters, tags releases | Jenkins Groovy DSL |
| `pipelines/create-cluster-conveyor.groovy` | Creates a complete Conveyor GKE cluster for an environment and region, applies Conveyor services (Prometheus, OPA, webhooks) | Jenkins Groovy DSL |
| `pipelines/create-cluster-eks.groovy` | Creates EKS clusters using Terraform and provisions them with Ansible | Jenkins Groovy DSL |
| `pipelines/promote-cluster.groovy` | Promotes a destination cluster to replace a source cluster including data and traffic migration | Jenkins Groovy DSL |
| `pipelines/ami.groovy` | Bakes AMIs using Packer | Jenkins Groovy DSL |
| `pipelines/sandbox-cleanup.groovy` | Detects and deletes stale sandbox clusters | Jenkins Groovy DSL |
| `pipelines/gke/manage-gke-cluster.groovy` | Applies Terraform changes to GKE clusters | Jenkins Groovy DSL |
| GitHub Actions workflows | GitOps-style Ansible deployments to dev (PR), stable (tag), production (tag + manual approval), and manual dispatch | GitHub Actions YAML |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `conveyorK8sPipelines` | `conveyorK8sTerraformEks` | Invokes infrastructure provisioning for EKS | CLI / Terragrunt |
| `conveyorK8sPipelines` | `conveyorK8sTerraformGke` | Invokes infrastructure provisioning for GKE | CLI / Terragrunt |
| `conveyorK8sPipelines` | `conveyorK8sAnsiblePlaybooks` | Applies provisioning and configuration to clusters | CLI / ansible-playbook |
| `conveyorK8sPipelines` | `conveyorK8sAmiBaking` | Triggers AMI builds | CLI / Packer |
| `conveyorK8sPipelines` | `conveyorK8sPipelineUtils` | Executes utility binaries for lookup, readiness, promotion, wavefront | CLI |
| `conveyorK8sTerraformEks` | `aws` (external) | Provisions EKS resources | AWS API (TF provider) |
| `conveyorK8sTerraformGke` | `gcp` (external) | Provisions GKE resources | GCP API (TF provider) |
| `conveyorK8sAnsiblePlaybooks` | `kubernetesClusters` (external) | Configures Kubernetes cluster state | Kubernetes API |

## Architecture Diagram References

- System context: `contexts-conveyorK8s`
- Container: `containers-conveyorK8s`
- Component: `components-conveyorK8s`
