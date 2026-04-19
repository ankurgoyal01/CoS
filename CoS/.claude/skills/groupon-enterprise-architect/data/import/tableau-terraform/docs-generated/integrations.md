---
service: "tableau-terraform"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 8
internal_count: 1
---

# Integrations

## Overview

`tableau-terraform` integrates with eight external systems during infrastructure provisioning and ongoing operations. GCP is the primary provider for all compute, networking, storage, and certificate resources. LDAP/Active Directory provides identity store integration configured at Tableau startup. The Tableau software download server delivers the installation RPM at VM startup. An SMTP server supports operational email alerting from on-VM cron scripts. Internally, Terragrunt depends on GCS for remote state management, co-located with the provisioned environment.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| GCP Compute Engine | GCP API (Terraform) | Provisions GCE VMs (primary and worker nodes), config disk, and unmanaged instance group | yes | `tableauInstanceGroup` |
| GCP Internal Load Balancer | GCP API (Terraform) | Provisions internal TCP load balancer, backend service, health check, and forwarding rule | yes | `tableauLoadBalancer` |
| GCP Certificate Manager | GCP API (Terraform) | Provisions self-managed TLS certificate for HTTPS | yes | `tableauCertificates` |
| GCP Cloud DNS | GCP API (Terraform) | Creates DNS A-record pointing to the load balancer forwarding rule IP | yes | `tableauLoadBalancer` |
| GCS (Google Cloud Storage) | GCP API (Terraform) | Hosts Tableau backup/log bucket and Terraform remote state bucket | yes | `tableauStorageBucket` |
| LDAP / Active Directory | LDAP (port 389) | Identity store for Tableau user authentication via Active Directory domain `group.on` | yes | `tableauInstanceGroup` |
| Tableau download server | HTTPS | Delivers the Tableau Server 2025.1.4 RPM during VM startup initialisation | yes | `tableauInstanceGroup` |
| SMTP server | SMTP (port 25) | Sends process-down alert emails from on-VM cron scripts to `dnd-tools@groupon.com` | no | `tableauInstanceGroup` |

---

### GCP Compute Engine Detail

- **Protocol**: GCP REST API via `google` Terraform provider
- **Base URL / SDK**: Terraform `google` provider (authenticated via impersonated service account `grpn-sa-terraform-tableau`)
- **Auth**: GCP service account impersonation using short-lived access tokens (3600s lifetime)
- **Purpose**: Creates and manages GCE VM instances (primary + workers), `pd-ssd` persistent disks, and the unmanaged instance group with named ports for HTTP (80) and HTTPS (443)
- **Failure mode**: `terraform apply` fails; existing infrastructure continues running unaffected
- **Circuit breaker**: Not applicable — Terraform is run manually or via CI pipeline

---

### GCP Internal Load Balancer Detail

- **Protocol**: GCP REST API via `google` Terraform provider
- **Base URL / SDK**: Terraform resources `google_compute_region_backend_service`, `google_compute_region_health_check`, `google_compute_forwarding_rule`
- **Auth**: GCP service account impersonation
- **Purpose**: Provisions internal TCP load balancer that routes traffic on ports 80 and 443 to the Tableau instance group; health check polls port 80 every 5 seconds with 2-second timeout
- **Failure mode**: Load balancer creation or update fails; Terraform reports error and halts
- **Circuit breaker**: Not applicable

---

### LDAP / Active Directory Detail

- **Protocol**: LDAP, port 389, simple bind (STARTTLS disabled: `wgserver.domain.ldap.starttls.enabled = false`)
- **Base URL / SDK**: `use2-ldap-vip.group.on:389`
- **Auth**: Service account `svc_tableaubind` with credentials injected from `secrets/tableau/gcp/<env>/smtp/smtp.json` at startup
- **Purpose**: Tableau Server identity store; all user logins are authenticated against the Groupon Active Directory domain `group.on` (nickname `GROUPON`)
- **Failure mode**: Tableau Server users cannot authenticate; Tableau processes may report unhealthy
- **Circuit breaker**: Not applicable — connection managed by Tableau Server internally

---

### Tableau Download Server Detail

- **Protocol**: HTTPS (public, unauthenticated)
- **Base URL / SDK**: `https://downloads.tableau.com/esdalt/2025.1.4/tableau-server-2025-1-4.x86_64.rpm`
- **Auth**: None (public download endpoint)
- **Purpose**: Downloads the Tableau Server 2025.1.4 RPM during VM startup script execution via `curl`
- **Failure mode**: VM startup script fails; Tableau Server is not installed; manual intervention required
- **Circuit breaker**: Not applicable

---

### SMTP Server Detail

- **Protocol**: SMTP, port 25 (internal relay)
- **Base URL / SDK**: `stable-smtp-uswest2.groupondev.com:25`
- **Auth**: None (internal unauthenticated relay)
- **Purpose**: Delivers process-down alert emails to `dnd-tools@groupon.com` when `process_status_check_prod.py` detects any Tableau process in `Down` status
- **Failure mode**: Alert emails are not delivered; no secondary alerting configured in the codebase
- **Circuit breaker**: Not applicable

---

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| GCS Terraform state bucket | GCS | Stores and locks Terraform remote state per environment and module | `tableauTerraformRunner` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. This repository provisions infrastructure consumed by internal Groupon analytics users who access Tableau Server at `analytics.groupondev.com`.

## Dependency Health

The load balancer health check (`google_compute_region_health_check`) polls TCP port 80 on each instance group member every 5 seconds with a 2-second timeout. If an instance fails the health check it is removed from the load balancer backend. No retry or circuit breaker patterns are implemented at the Terraform provisioning layer — health and failover behaviours are concerns for Tableau Server itself.
