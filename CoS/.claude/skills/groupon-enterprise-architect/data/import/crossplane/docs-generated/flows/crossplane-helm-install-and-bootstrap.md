---
service: "crossplane"
title: "Crossplane Helm Install and Bootstrap"
generated: "2026-03-03"
type: flow
flow_name: "crossplane-helm-install-and-bootstrap"
flow_type: synchronous
trigger: "Platform team runs helm install crossplane in the target namespace"
participants:
  - "Platform team"
  - "Helm v3"
  - "crossplane-init container"
  - "crossplaneController"
  - "crossplaneRbacManager"
  - "webhookServer"
  - "Kubernetes API server"
architecture_ref: "crossplaneControllerComponents"
---

# Crossplane Helm Install and Bootstrap

## Summary

This flow describes the full bootstrap sequence when Crossplane is installed into a Kubernetes namespace via Helm. The Helm chart creates all required Kubernetes resources (ServiceAccounts, ClusterRoles, ClusterRoleBindings, Secrets, Service, Deployments). An init container runs first to set up TLS certificates and register initial provider/configuration packages. Once the init container completes, the main Crossplane controller starts, registers webhooks, and the RBAC Manager deployment starts in parallel.

## Trigger

- **Type**: manual (operator action)
- **Source**: Platform team runs `helm install crossplane --namespace crossplane-system`
- **Frequency**: Once per environment (initial install); repeated on `helm upgrade` for version changes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Platform team | Executes `helm install` | n/a (operator) |
| Helm v3 | Renders chart templates and applies Kubernetes manifests | n/a (tooling) |
| crossplane-init (init container) | Prepares TLS certificates and initial package configs | `crossplaneController` (init container) |
| Crossplane Controller | Main reconciliation engine; starts after init completes | `crossplaneController` |
| Webhook Server | Registers admission webhooks; serves on port 9443 | `webhookServer` |
| Crossplane RBAC Manager | Starts alongside main controller; provisions RBAC | `crossplaneRbacManager` |
| Kubernetes API server | Receives and persists all applied resources | `continuumKubernetesCluster` (stub) |

## Steps

1. **Helm renders templates and applies resources**: Helm renders the chart from `values.yaml` (merged with environment values file) and applies the following resources to the `crossplane-system` namespace:
   - `ServiceAccount` for Crossplane (`serviceAccount.create: true`)
   - `ServiceAccount` for RBAC Manager (`rbac-manager`)
   - `ClusterRole` and `ClusterRoleBinding` for Crossplane and RBAC Manager
   - Empty `Secret` objects: `crossplane-root-ca`, `crossplane-tls-server`, `crossplane-tls-client`
   - `Service` `crossplane-webhooks` on port `9443` (when `webhooks.enabled: true`)
   - `Deployment` for the Crossplane Controller
   - `Deployment` for the RBAC Manager
   - From: Helm
   - To: Kubernetes API server
   - Protocol: Kubernetes API

2. **Crossplane init container starts**: The init container (`crossplane-init`) runs before the main container. It uses the same image as the controller (`docker-conveyor.groupondev.com/crossplane/crossplane:v1.19.1`) with args `core init`.
   - From: Kubernetes (pod scheduler)
   - To: `crossplane-init` container
   - Protocol: Kubernetes Pod lifecycle

3. **Init container generates TLS certificates**: The init container reads the empty `crossplane-root-ca` Secret and generates a self-signed CA certificate, TLS server certificate, and TLS client certificate. It populates the Secrets `crossplane-root-ca`, `crossplane-tls-server`, and `crossplane-tls-client` in the namespace.
   - From: `crossplane-init`
   - To: Kubernetes API server (Secret patch)
   - Protocol: Kubernetes API

4. **Init container registers webhook TLS**: The init container registers the webhook service name, namespace, and port (`9443`) via env vars `WEBHOOK_SERVICE_NAME`, `WEBHOOK_SERVICE_NAMESPACE`, `WEBHOOK_SERVICE_PORT`.
   - From: `crossplane-init` (env var injection)
   - To: Crossplane controller configuration
   - Protocol: Pod environment variables

5. **Main Crossplane controller starts**: The init container exits, and the main `crossplane` container starts with args `core start`. It mounts TLS certs from Secrets at `/tls/server` and `/tls/client`. The startup probe (`tcpSocket` on port `8081`) must pass before Kubernetes marks the pod ready (`failureThreshold: 30, periodSeconds: 2`).
   - From: Kubernetes (pod lifecycle)
   - To: `crossplaneController` main container
   - Protocol: Kubernetes Pod lifecycle

6. **Webhook server registers admission webhooks**: The `webhookServer` component connects to the Kubernetes API server and registers `ValidatingWebhookConfiguration` and `MutatingWebhookConfiguration` resources pointing to the `crossplane-webhooks` service on port `9443`.
   - From: `webhookServer`
   - To: Kubernetes API server (`admissionregistration.k8s.io`)
   - Protocol: Kubernetes API

7. **RBAC Manager init container runs**: In parallel, the RBAC Manager Deployment's init container (`crossplane-init` with args `rbac init`) runs to set up RBAC-specific initialization.
   - From: Kubernetes (pod scheduler)
   - To: `crossplaneRbacManager` init container
   - Protocol: Kubernetes Pod lifecycle

8. **RBAC Manager main container starts**: The RBAC Manager starts with args `rbac start --provider-clusterrole=crossplane:allowed-provider-permissions`. It begins watching for provider installations and provisions RBAC resources.
   - From: Kubernetes (pod lifecycle)
   - To: `crossplaneRbacManager` main container
   - Protocol: Kubernetes Pod lifecycle

9. **Bootstrap complete**: Both the Crossplane Controller and RBAC Manager pods are `Running` and `Ready`. The Package Manager is ready to install providers. Application teams can now submit `Bucket` claims.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Init container fails (TLS cert generation error) | Kubernetes restarts the init container; deployment remains pending | Controller pod does not start; check init container logs |
| Startup probe timeout (port 8081 not ready in 60 seconds) | Kubernetes marks pod as failed and restarts it | Investigate container startup logs; may indicate resource contention or image issue |
| Webhook registration fails (API server rejects) | Controller logs admission registration error; webhooks not enforced | Resources can be applied but without validation; diagnose ClusterRole permissions for `admissionregistration.k8s.io` |
| Helm apply partially fails | Helm marks release as failed; partial resources may exist | Run `helm uninstall crossplane -n crossplane-system` and reinstall cleanly |

## Sequence Diagram

```
Platform Team    Helm    Kubernetes API    crossplane-init    crossplaneController    crossplaneRbacManager
     |            |             |                 |                    |                       |
     |--helm install-->|        |                 |                    |                       |
     |            |--apply resources (SA, Secrets, Deployments...)---->|                      |
     |            |             |--start init container--------------->|                      |
     |            |             |                 |--generate TLS certs|                      |
     |            |             |<--patch Secrets (TLS)----------------|                      |
     |            |             |--start main controller (core start)->|                      |
     |            |             |                 |                    |--register webhooks-->|
     |            |             |--start rbac-manager init container------------------------->|
     |            |             |<--RBAC init done-----------------------------------------------|
     |            |             |--start rbac-manager (rbac start)-------------------------------->|
     |<--helm install complete--|                 |                    |                       |
```

## Related

- Architecture component views: `crossplaneControllerComponents`, `crossplaneRbacManagerComponents`
- Related flows: [Provider Package Installation](provider-package-installation.md)
- Deployment details: [Deployment](../deployment.md)
