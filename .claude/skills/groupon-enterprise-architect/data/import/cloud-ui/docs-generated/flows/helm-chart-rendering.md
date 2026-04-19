---
service: "cloud-ui"
title: "Helm Chart Rendering Flow"
generated: "2026-03-03"
type: flow
flow_name: "helm-chart-rendering"
flow_type: synchronous
trigger: "User opens the component configuration editor or clicks 'Preview Manifests' in the Cloud UI"
participants:
  - "continuumCloudUi"
  - "continuumCloudBackendApi"
architecture_ref: "components-cloud-backend-backendApplicationsApi"
---

# Helm Chart Rendering Flow

## Summary

The Helm Chart Rendering flow enables engineers to preview the Kubernetes manifests that will be generated for a component before committing them to Git. The Cloud UI calls the Cloud Backend Helm API to resolve the correct chart (from Artifactory), map component configuration to Helm values, and render the full Kubernetes YAML manifest using the Helm SDK. Results are displayed in the UI for review.

## Trigger

- **Type**: user-action
- **Source**: Engineer opens the component configuration editor or requests a manifest preview in `cloudUiPages` via `cloudUiHelmClient`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud UI Web App | Initiates chart info lookup and template rendering; displays rendered YAML | `continuumCloudUi` |
| Cloud Backend API | Resolves chart from Artifactory; maps config to values; renders manifests via Helm SDK | `continuumCloudBackendApi` |

## Steps

1. **Resolve Chart for Workload Type**: Frontend calls `POST /cloud-backend/helm/chart-for-workload` with `workloadType: "api"` or `"worker"`.
   - From: `continuumCloudUi` (`cloudUiHelmClient`)
   - To: `continuumCloudBackendApi` (`backendHelmApi`)
   - Protocol: HTTPS/JSON

2. **Check Artifactory Index Cache**: `backendArtifactoryClient` checks the in-memory index cache (TTL 6 hours) for the Helm repository index.
   - From: `backendHelmApi`
   - To: `backendArtifactoryClient`
   - Protocol: In-process

3. **Fetch Chart Index from Artifactory** (on cache miss): Client fetches `index.yaml` from `https://artifactory.groupondev.com/artifactory/list/helm-generic/` and caches it.
   - From: `backendArtifactoryClient`
   - To: Artifactory
   - Protocol: HTTPS

4. **Return Chart Info**: Backend maps workload type to chart name (`cmf-generic-api` for `api`, `cmf-generic-worker` for `worker`) and returns `{ chartName, latestVersion, workloadType, description }`.
   - From: `continuumCloudBackendApi`
   - To: `continuumCloudUi`
   - Protocol: HTTPS/JSON

5. **Validate Chart Version** (optional): Frontend may call `POST /cloud-backend/helm/validate-version` with `{ chartName, version }` to confirm a specific version is available in Artifactory.
   - From: `continuumCloudUi`
   - To: `continuumCloudBackendApi`
   - Protocol: HTTPS/JSON

6. **Render Kubernetes Manifests**: Frontend calls `POST /cloud-backend/helm/render-template` with `{ repoUrl, chartName, chartVersion, config, imageTag }`.
   - From: `continuumCloudUi` (`cloudUiHelmClient`)
   - To: `continuumCloudBackendApi` (`backendHelmApi`)
   - Protocol: HTTPS/JSON

7. **Check Chart File Cache**: Backend checks the filesystem chart cache (`/tmp/helm-chart-cache`) for the specific chart version `.tgz` file (TTL 24 hours).
   - From: `backendHelmApi`
   - To: `backendArtifactoryClient` / `chartCache`
   - Protocol: In-process

8. **Download Chart Archive** (on cache miss): Backend downloads the `.tgz` chart archive from Artifactory and saves it to the chart cache.
   - From: `backendArtifactoryClient`
   - To: Artifactory (`https://artifactory.groupondev.com/artifactory/list/helm-generic/`)
   - Protocol: HTTPS

9. **Load and Map Values**: Backend loads the chart via the Helm SDK (`chart/loader`); calls `backendHelmAdapter.ToHelmValues(config, imageTag)` to produce the values map from the component configuration.
   - From: `backendHelmApi`
   - To: `backendHelmAdapter`
   - Protocol: In-process

10. **Render Template**: Backend calls `helmClient.RenderTemplate(ctx, chart, valuesMap, releaseName, namespace)` to produce full Kubernetes YAML manifests.
    - From: `backendHelmApi`
    - To: Helm SDK (in-process)
    - Protocol: In-process

11. **Return Manifests**: Backend returns `{ manifests: "<YAML string>", chartInfo: { chartName, chartVersion, appName } }`.
    - From: `continuumCloudBackendApi`
    - To: `continuumCloudUi`
    - Protocol: HTTPS/JSON

12. **Display Manifests**: Frontend renders the manifest YAML in a preview pane for engineer review.
    - From: `cloudUiPages`
    - To: Engineer (browser)
    - Protocol: UI rendering

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid `workloadType` (not `api` or `worker`) | Returns `invalid_argument` | UI shows error |
| Artifactory unreachable | Returns `internal` error if cache is cold; cache serves requests if warm | Rendering fails if both cache and Artifactory are unavailable |
| Chart version not found in Artifactory | `validate-version` returns `valid: false`; `render-template` returns `internal` error on download failure | UI shows version-not-found message |
| Component config validation fails | `POST /cloud-backend/helm/validate` returns `{ valid: false, errors: [...] }` | UI highlights config errors before rendering |
| Helm SDK rendering error | Returns `internal` error | UI shows rendering failure message |

## Sequence Diagram

```
CloudUI -> CloudBackendAPI: POST /helm/chart-for-workload { workloadType: "api" }
CloudBackendAPI -> ArtifactoryClient: GetLatestChartVersion("cmf-generic-api") [cache check first]
ArtifactoryClient -> Artifactory: GET index.yaml [if cache miss]
CloudBackendAPI --> CloudUI: { chartName: "cmf-generic-api", latestVersion: "3.94.0" }
CloudUI -> CloudBackendAPI: POST /helm/render-template { chartName, chartVersion, config, imageTag }
CloudBackendAPI -> ChartCache: GetCachedPath("cmf-generic-api", "3.94.0") [cache check]
CloudBackendAPI -> Artifactory: DownloadChart("cmf-generic-api", "3.94.0") [if cache miss]
CloudBackendAPI -> HelmAdapter: ToHelmValues(config, imageTag)
CloudBackendAPI -> HelmSDK: RenderTemplate(chart, values, releaseName, namespace)
CloudBackendAPI --> CloudUI: { manifests: "<k8s yaml>", chartInfo: { ... } }
```

## Related

- Architecture component view: `components-cloud-backend-backendApplicationsApi`
- Related flows: [GitOps Deployment](gitops-deployment.md), [Application Config Update](application-config-update.md)
