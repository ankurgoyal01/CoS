---
service: "tableau-terraform"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Tableau Server Infrastructure (tableau-terraform).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Infrastructure Provisioning](infrastructure-provisioning.md) | synchronous | Manual operator Make command | Provisions or updates all Tableau GCP resources via Terragrunt/Terraform plan and apply |
| [Primary Node Initialisation](primary-node-initialisation.md) | event-driven | GCE VM startup (metadata script) | Installs Tableau Server on the primary node, configures LDAP, initialises TSM, and distributes the bootstrap file to worker nodes |
| [Worker Node Cluster Join](worker-node-cluster-join.md) | event-driven | GCE VM startup (metadata script) | Worker VM polls for the bootstrap file, installs Tableau Server, and joins the cluster |
| [Daily Backup and Log Upload](daily-backup-log-upload.md) | scheduled | Cron at 01:30 GMT daily | Sends Tableau Server backup archives and log files to the GCS bucket |
| [Process Health Monitoring](process-health-monitoring.md) | scheduled | Cron every 5 minutes | Checks Tableau process status via systeminfo.xml and sends email alerts if any process is down |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

The infrastructure provisioning flow interacts with the GCP control plane (Compute Engine API, GCS API, Certificate Manager API, Cloud DNS API) via Terraform. The primary and worker node startup flows coordinate across VMs within the `tableauInstanceGroup` via SCP over SSH. No flows span other Groupon services defined in the central architecture model.
