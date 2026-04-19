---
service: "api-proxy-config"
title: "Configuration Bundle Deploy"
generated: "2026-03-03"
type: flow
flow_name: "config-bundle-deploy"
flow_type: batch
trigger: "DeployBot Git tag trigger matching -v(?P<version>.*)$ pattern per target environment"
participants:
  - "continuumApiProxyConfigBundle"
  - "continuumApiProxyConfigTools"
  - "apiProxy"
architecture_ref: "components-api-proxy-config-bundle"
---

# Configuration Bundle Deploy

## Summary

The configuration bundle deploy flow packages the environment-scoped JSON configuration files from `src/main/conf/` into a versioned Docker image via the Maven assembly descriptor, then deploys that image to the target Kubernetes environment using Helm (`cmf-java-api` chart v3.92.0) and `krane`. The deployed image is consumed by the `apiProxy` runtime, which reads the configuration at startup using the `CONFIG` environment variable. This is the primary mechanism by which routing rule changes committed to Git take effect in live environments.

## Trigger

- **Type**: manual (production) / auto-promote (staging → production for NA us-central1 and EMEA europe-west1)
- **Source**: Engineer creates a Git tag matching the DeployBot target regex (`-v(?P<version>.*)$`); DeployBot v2 picks up the tag and initiates the deployment sequence
- **Frequency**: On-demand after any configuration change is merged to main

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Proxy Config Bundle | Source of versioned JSON configuration files; Maven assembly packages them into the Docker image | `continuumApiProxyConfigBundle` |
| DeployBot v2 | Orchestrates the full deploy: detects tag, renders Helm manifests, invokes `krane` | (CI/CD system, not modelled in Structurizr) |
| Kubernetes (`api-proxy-<env>` namespace) | Receives Helm manifests via `krane`; manages rolling pod replacement | (Infrastructure, not modelled in Structurizr) |
| `apiProxy` runtime | Mounts the config artifact from `/app/conf/`; reads `mainConf.json` on startup via `CONFIG` env var | `apiProxy` |

## Steps

1. **Engineer tags the repository**: Creates a Git tag matching the pattern for the target environment (e.g., `production-us-central1-v1.2.3`); DeployBot detects the tag
   - From: Engineer
   - To: DeployBot v2
   - Protocol: Git tag webhook

2. **Render Helm manifests for application**: DeployBot runs `helm3 template cmf-java-api` using `common.yml`, the secrets overlay (from `api-proxy-secrets` submodule), and the per-environment override file (e.g., `production-us-central1.yml`), setting `appVersion` and `changeCause` from DeployBot metadata
   - From: DeployBot
   - To: Helm registry (`http://artifactory.groupondev.com/artifactory/helm-generic/`)
   - Protocol: HTTP (Helm chart fetch + template render)

3. **Render Helm manifests for Telegraf sidecar**: DeployBot renders `cmf-generic-telegraf` chart using `telegraf-agent/common.yml` and the per-environment telegraf override file
   - From: DeployBot
   - To: Helm registry
   - Protocol: HTTP

4. **Deploy to Kubernetes**: DeployBot pipes both rendered manifest streams to `krane deploy <namespace> <context>` with `--no-prune` and an environment-specific `--global-timeout` (300s for dev, 4000s for staging/production)
   - From: DeployBot
   - To: Kubernetes API server
   - Protocol: kubectl/krane (Kubernetes API)

5. **Rolling pod replacement**: Kubernetes applies the rolling update strategy (`maxUnavailable: 0`, `maxSurge: 25%`); new pods start with the updated Docker image and mount configuration from `/app/conf/`
   - From: Kubernetes
   - To: `apiProxy` pods
   - Protocol: Kubernetes pod lifecycle

6. **`apiProxy` startup with new config**: Each new `apiProxy` pod sleeps for `SLEEP_TIME_SECONDS` (90s), then reads `mainConf.json` from the path specified by the `CONFIG` env var and initializes the routing table
   - From: `apiProxy` runtime
   - To: `continuumApiProxyConfigBundle` (file artifact at `/app/conf/`)
   - Protocol: File I/O

7. **Readiness probe passes**: Once the `apiProxy` routing table is initialized, `/grpn/ready` on port 9000 returns HTTP 200; Kubernetes marks the pod as ready and routes traffic to it
   - From: Kubernetes
   - To: `apiProxy` pods
   - Protocol: HTTP

8. **Auto-promote to production** (staging only): After `staging-us-central1` deployment succeeds, DeployBot automatically triggers `production-us-central1`; after `staging-europe-west1` succeeds, DeployBot triggers `production-eu-west-1`
   - From: DeployBot
   - To: DeployBot (next target)
   - Protocol: Internal DeployBot promotion chain

9. **Drain old pods**: Old pods receive a drain signal; they complete in-flight requests and terminate after the `drainTimeout` (30s dev, 60s staging, 90s production) via the `drain-pod.sh` script at `/app/drain-pod.sh`
   - From: Kubernetes
   - To: `apiProxy` (old pods)
   - Protocol: Kubernetes SIGTERM / drain script

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Malformed `routingConf.json` or missing `mainConf.json` | `apiProxy` fails to start; readiness probe at `/grpn/ready:9000` never returns 200 | `krane` times out after `--global-timeout`; deployment fails; old pods remain in service |
| Helm registry unreachable | `helm3 template` fails; DeployBot reports deployment failure | No manifests generated; deployment aborted |
| Kubernetes API unreachable | `krane deploy` fails; DeployBot reports deployment failure | No changes applied to cluster |
| Pod OOM during startup | JVM killed; pod restarts; eventually enters `CrashLoopBackOff` | `krane` times out; deployment fails; old pods remain |
| Secrets submodule not accessible | `helm3 template` cannot read secrets overlay; deployment aborted | No deployment proceeds |

## Sequence Diagram

```
Engineer -> Git: Create release tag (e.g., production-us-central1-v1.2.3)
Git -> DeployBot: Tag event trigger
DeployBot -> HelmRegistry: helm3 template cmf-java-api (common.yml + secrets + production-us-central1.yml)
HelmRegistry --> DeployBot: Rendered K8s manifests (app)
DeployBot -> HelmRegistry: helm3 template cmf-generic-telegraf (telegraf common.yml + production-us-central1.yml)
HelmRegistry --> DeployBot: Rendered K8s manifests (telegraf)
DeployBot -> Kubernetes: krane deploy api-proxy-production <context> --global-timeout=4000s
Kubernetes -> apiProxy (new pods): Start with updated Docker image; mount /app/conf/
apiProxy -> routingConfigArtifacts: Read mainConf.json (via CONFIG env var)
routingConfigArtifacts --> apiProxy: Parsed routing config
apiProxy -> Kubernetes: /grpn/ready:9000 returns 200
Kubernetes -> apiProxy (old pods): Drain + terminate (after drainTimeout)
DeployBot -> DeployBot: Auto-promote to production-us-central1 (if staging)
```

## Related

- Architecture component view: `components-api-proxy-config-bundle`
- Architecture dynamic view: `dynamic-promote-route-request-flow`
- Related flows: [Promote Route Request](promote-route-request.md)
- Source: `.deploy_bot.yml`, `.meta/deployment/cloud/scripts/deploy.sh`
