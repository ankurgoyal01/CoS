---
service: "cloud-ui"
title: "Application Creation Flow"
generated: "2026-03-03"
type: flow
flow_name: "application-creation"
flow_type: synchronous
trigger: "User submits the new application form in the Cloud UI"
participants:
  - "continuumCloudUi"
  - "continuumCloudBackendApi"
  - "continuumCloudBackendPostgres"
architecture_ref: "components-cloud-backend-backendApplicationsApi"
---

# Application Creation Flow

## Summary

The Application Creation flow registers a new Kubernetes application within an organization. The user fills in the application name, selects a parent organization, and defines one or more components with their container image, port, chart type, autoscaling, resources, probes, and secrets. The Cloud Backend validates all inputs, applies defaults, auto-derives a secrets repository URL from the main repository URL, and persists the application with environment-specific component configuration initialized to staging.

## Trigger

- **Type**: user-action
- **Source**: Engineer submits the new application form in `continuumCloudUi`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud UI Web App | Collects form input; calls backend creation endpoint; displays result | `continuumCloudUi` |
| Cloud Backend API | Validates request, applies defaults, persists application | `continuumCloudBackendApi` |
| Cloud Backend PostgreSQL | Stores the new application record with full JSONB configuration | `continuumCloudBackendPostgres` |

## Steps

1. **Submit Application Form**: User fills in application details (name, organization, components, Git URLs) and clicks Create in `cloudUiPages`.
   - From: `continuumCloudUi`
   - To: `continuumCloudBackendApi`
   - Protocol: HTTPS/JSON via `POST /cloud-backend/applications`

2. **Validate Organization Exists**: Backend verifies `organizationId` maps to an existing organization row.
   - From: `backendApplicationsApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL (`SELECT EXISTS ... FROM organizations WHERE id = $1`)

3. **Validate and Apply Defaults for Each Component**: Backend iterates over the `components` array; validates name, image, and port; applies defaults: `minReplicas=1`, `maxReplicas=minReplicas+2`, `targetCPU=80`, `cpu=100m`, `memory=512Mi`, `memoryLimit=1Gi`, `pdb.maxUnavailable=20%`, `workloadType=deployment`.
   - From: `backendApplicationsApi`
   - To: `backendValidation` (in-process)
   - Protocol: In-process

4. **Validate Port and Image Registry**: Backend calls `validation.ValidatePort` and `validation.ValidateImageRegistry` to enforce port range and allowed container registry prefixes.
   - From: `backendApplicationsApi`
   - To: `backendValidation`
   - Protocol: In-process

5. **Auto-Derive Secrets Repository URL**: If `mainRepoUrl` is provided and `secretsRepoUrl` is empty, backend derives it by appending `-secrets` before the `.git` suffix (e.g., `git@github.com:org/repo.git` → `git@github.com:org/repo-secrets.git`).
   - From: `backendApplicationsApi`
   - To: (in-process logic)
   - Protocol: In-process

6. **Build Config JSONB**: Backend serializes `components` array and initializes `environmentComponents` with the components assigned to the `staging` key.
   - From: `backendApplicationsApi`
   - To: (in-process)
   - Protocol: In-process

7. **Persist Application**: Backend inserts the application row into `applications` with all fields including `config` JSONB.
   - From: `backendApplicationsApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL (`INSERT INTO applications ...`)

8. **Return Created Application**: Backend returns the full application object including derived fields.
   - From: `continuumCloudBackendApi`
   - To: `continuumCloudUi`
   - Protocol: HTTPS/JSON

9. **Display Application Detail**: Frontend navigates to the application detail page, loading the newly created application for further configuration or deployment.
   - From: `cloudUiPages`
   - To: `cloudUiApiClient`
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `name` is empty | Returns `invalid_argument` error | UI displays validation error |
| `organizationId` does not exist | Returns `invalid_argument` — "Organization not found" | UI prompts user to select a valid organization |
| Duplicate application name | Returns `already_exists` error | UI prompts user to choose a different name |
| Invalid port number | Returns `invalid_argument` from `ValidatePort` | UI highlights port field |
| Invalid image registry | Returns `invalid_argument` from `ValidateImageRegistry` | UI highlights image field |
| Component missing `name` or `image` | Returns `invalid_argument` for that component | UI highlights the specific component field |

## Sequence Diagram

```
CloudUI -> CloudBackendAPI: POST /cloud-backend/applications { name, organizationId, components, mainRepoUrl }
CloudBackendAPI -> PostgreSQL: SELECT EXISTS FROM organizations WHERE id = organizationId
CloudBackendAPI -> BackendValidation: ValidatePort, ValidateImageRegistry per component
CloudBackendAPI -> CloudBackendAPI: Apply defaults (replicas, resources, PDB, workloadType)
CloudBackendAPI -> CloudBackendAPI: Derive secretsRepoUrl from mainRepoUrl
CloudBackendAPI -> CloudBackendAPI: Build config JSONB with components + environmentComponents[staging]
CloudBackendAPI -> PostgreSQL: INSERT INTO applications (id, name, organization_id, config, ...)
PostgreSQL --> CloudBackendAPI: OK
CloudBackendAPI --> CloudUI: { id, name, organizationId, components, environmentComponents, ... }
CloudUI -> CloudUI: Navigate to /applications/:name
```

## Related

- Architecture component view: `components-cloud-backend-backendApplicationsApi`
- Related flows: [Application Config Update](application-config-update.md), [GitOps Deployment](gitops-deployment.md)
