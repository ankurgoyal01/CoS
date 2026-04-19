---
service: "gcp-tls-certificate-manager"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for GCP TLS Certificate Manager.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [New Certificate Provisioning](new-certificate-provisioning.md) | event-driven | Push to `main` branch with new `requests/*.json` file | Detects a new certificate request, triggers DeployBot, issues a TLS certificate via cert-manager, and publishes TLS material to GCP Secret Manager |
| [Certificate Update / Accessor Change](certificate-update.md) | event-driven | Push to `main` branch with modified `requests/*.json` file | Detects a modification to an existing certificate request, regenerates the certificate, and updates the GCP Secret Manager secret |
| [Certificate Deletion](certificate-deletion.md) | event-driven | Push to `main` branch with deleted `requests/*.json` file | Detects removal of a certificate request, removes the cert-manager resources from Conveyor Cloud, and deletes the GCP Secret Manager secret |
| [Monthly Certificate Refresh](monthly-certificate-refresh.md) | scheduled | Jenkins cron trigger (`H 12 1-7 * 1` — first Monday of each month) | Renews all registered certificates regardless of change status and updates all GCP Secret Manager versions |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 0 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

All flows span multiple systems. The key cross-service path is:

`Jenkins` → `gcpTlsCertificateManagerPipeline` → `DeployBot` → `Conveyor Cloud Kubernetes` / `cert-manager` → `GCP Secret Manager` → (downstream GCP service reads the secret)

- For new/update/delete flows: see [New Certificate Provisioning](new-certificate-provisioning.md), [Certificate Update](certificate-update.md), [Certificate Deletion](certificate-deletion.md)
- For scheduled renewal: see [Monthly Certificate Refresh](monthly-certificate-refresh.md)
