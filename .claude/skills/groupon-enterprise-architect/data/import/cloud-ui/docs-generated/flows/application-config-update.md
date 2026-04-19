---
service: "cloud-ui"
title: "Application Config Update Flow"
generated: "2026-03-03"
type: flow
flow_name: "application-config-update"
flow_type: synchronous
trigger: "User edits component settings (autoscaling, resources, probes, env vars, secrets) and saves in the Cloud UI"
participants:
  - "continuumCloudUi"
  - "continuumCloudBackendApi"
  - "continuumCloudBackendPostgres"
architecture_ref: "components-cloud-backend-backendApplicationsApi"
---

# Application Config Update Flow

## Summary

The Application Config Update flow allows engineers to modify component-level configuration for a specific environment (staging or production) without triggering an immediate deployment. The Cloud UI collects the updated component configuration through the edit modal, sends it to the Cloud Backend with an optional `targetEnvironment` specifier, and the backend merges the changes into the environment-specific `environmentComponents` JSONB map before persisting. The change can then be deployed via the GitOps Deployment flow.

## Trigger

- **Type**: user-action
- **Source**: Engineer edits a component in the edit-component modal in `cloudUiPages` and clicks Save
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud UI Web App | Presents the edit form; sends updated component config to the backend | `continuumCloudUi` |
| Cloud Backend API | Loads the existing application; merges updated component config; persists changes | `continuumCloudBackendApi` |
| Cloud Backend PostgreSQL | Stores the updated `config` JSONB (including `environmentComponents`) and top-level fields | `continuumCloudBackendPostgres` |

## Steps

1. **User Edits Component Config**: Engineer modifies autoscaling, resources, probes, environment variables, secrets, Helm chart version, or other component settings in the edit-component modal.
   - From: Engineer (browser)
   - To: `cloudUiPages`
   - Protocol: UI interaction

2. **Validate Configuration** (optional): Frontend may call `POST /cloud-backend/helm/validate` to validate the component config before saving.
   - From: `cloudUiApiClient`
   - To: `continuumCloudBackendApi` (`backendHelmApi`)
   - Protocol: HTTPS/JSON

3. **Submit Update Request**: Frontend calls `PUT /cloud-backend/applications/:id` with the updated `components` array and optional `targetEnvironment` (`"staging"` or `"production"`).
   - From: `continuumCloudUi` (`cloudUiApiClient`)
   - To: `continuumCloudBackendApi` (`backendApplicationsApi`)
   - Protocol: HTTPS/JSON

4. **Load Existing Application**: Backend retrieves the full application record including current `environmentComponents` configuration from PostgreSQL.
   - From: `backendApplicationsApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL (`SELECT ... FROM applications WHERE id = $1`)

5. **Merge Component Config**: Backend determines update strategy:
   - If `targetEnvironment` is set: updates `environmentComponents[targetEnvironment]` with the supplied `components` array; if `targetEnvironment = staging`, also updates the legacy `components` field for backward compatibility.
   - If `targetEnvironment` is absent: updates the legacy flat `components` field (affects all environments).
   - If `environmentComponents` map is provided directly: merges each environment key.
   - From: `backendApplicationsApi`
   - To: (in-process)
   - Protocol: In-process

6. **Serialize Updated Config**: Backend marshals the updated `components`, `environmentComponents`, `autoscaling`, `resources`, `pdb`, `probes`, `storage`, and `secrets` into the `config` JSONB structure.
   - From: `backendApplicationsApi`
   - To: (in-process)
   - Protocol: In-process

7. **Persist Updated Application**: Backend executes `UPDATE applications SET ... WHERE id = $1` with the new `config` JSONB, `updated_at` timestamp, and any top-level field changes.
   - From: `backendApplicationsApi`
   - To: `continuumCloudBackendPostgres`
   - Protocol: SQL

8. **Return Updated Application**: Backend returns the full updated application object.
   - From: `continuumCloudBackendApi`
   - To: `continuumCloudUi`
   - Protocol: HTTPS/JSON

9. **Refresh UI**: Frontend refreshes the application detail view with the updated configuration.
   - From: `cloudUiPages`
   - To: Engineer (browser)
   - Protocol: UI rendering

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Application not found | Returns `not_found` error | UI displays error |
| Component config validation fails (via `helm/validate`) | Returns `{ valid: false, errors }` | UI highlights invalid fields before saving |
| Database update fails | Returns `internal` error | UI shows failure message; no changes persisted |
| Invalid `targetEnvironment` value | No constraint — accepted as-is; creates new environment key in `environmentComponents` | Config is saved under the new environment key |

## Sequence Diagram

```
CloudUI -> CloudBackendAPI: PUT /applications/:id { components: [...], targetEnvironment: "staging" }
CloudBackendAPI -> PostgreSQL: SELECT * FROM applications WHERE id = :id
PostgreSQL --> CloudBackendAPI: { id, config: { environmentComponents: { staging: [...], production: [...] } } }
CloudBackendAPI -> CloudBackendAPI: Merge components into environmentComponents["staging"]
CloudBackendAPI -> CloudBackendAPI: Marshal updated config to JSONB
CloudBackendAPI -> PostgreSQL: UPDATE applications SET config = $1, updated_at = NOW() WHERE id = :id
PostgreSQL --> CloudBackendAPI: OK
CloudBackendAPI --> CloudUI: { id, name, environmentComponents: { staging: [<updated>], ... } }
CloudUI -> CloudUI: Refresh application detail view
```

## Related

- Architecture component view: `components-cloud-backend-backendApplicationsApi`
- Related flows: [Application Creation](application-creation.md), [GitOps Deployment](gitops-deployment.md), [Helm Chart Rendering](helm-chart-rendering.md)
