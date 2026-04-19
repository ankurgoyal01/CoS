---
service: "conveyor_k8s"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for Conveyor K8s.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [AMI Baking and Publishing](ami-baking-and-publishing.md) | batch | Jenkins `ami` pipeline job trigger | Builds Packer-based AMIs for EKS worker nodes and copies them across AWS accounts and regions |
| [Cluster Creation (GKE)](cluster-creation-gke.md) | batch | Jenkins `create-cluster-conveyor` job trigger | Provisions a complete GKE cluster with Terraform then configures it with Ansible playbooks |
| [Cluster Promotion](cluster-promotion.md) | batch | Jenkins `promote-cluster` job trigger | Promotes a destination cluster to replace a source cluster, including data migration, readiness checks, and traffic cutover |
| [Ansible Playbook Deployment (GitOps)](ansible-playbook-deployment-gitops.md) | event-driven | GitHub pull request or version tag push | Detects changed Ansible playbooks and applies them to dev, stable, or production clusters using GitHub Actions |
| [Cluster Discovery](cluster-discovery.md) | synchronous | Pipeline step (CLI invocation) | Queries AWS S3 cluster state buckets to find clusters matching SHA, version, region, and name criteria |
| [Sandbox Cluster Cleanup](sandbox-cluster-cleanup.md) | scheduled | Jenkins scheduled job | Detects stale sandbox clusters and triggers their deletion |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 4 |

## Cross-Service Flows

All flows in this service are infrastructure-layer operations. They interact with:

- AWS EKS/EC2/S3 APIs (cluster provisioning, AMI management, state storage)
- GCP GKE/GCS APIs (cluster provisioning, state storage)
- Kubernetes API (readiness checks, promotion metadata)
- Wavefront REST API (deployment event markers during promotion)
- Jenkins and GitHub Actions (orchestration layer)

No cross-service flows with other Groupon application microservices have been identified in this repository.
