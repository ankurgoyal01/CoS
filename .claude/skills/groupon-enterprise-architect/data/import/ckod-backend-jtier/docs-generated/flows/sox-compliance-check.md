---
service: "ckod-backend-jtier"
title: "SOX Compliance Check"
generated: "2026-03-03"
type: flow
flow_name: "sox-compliance-check"
flow_type: synchronous
trigger: "HTTP GET /deployments/sox"
participants:
  - "continuumCkodBackendJtier"
  - "githubEnterprise"
architecture_ref: "dynamic-ckod-deployment-tracking-flow"
---

# SOX Compliance Check

## Summary

When a deployment automation or engineer needs to determine whether a given pipeline is subject to SOX compliance requirements, they call `GET /deployments/sox` with a Deploybot URL. CKOD resolves the GitHub repository from the Deploybot URL, then fetches and parses the SOX scoping CSV maintained in a GitHub repository (`asadauskas/pipeline-sox-scopings`). The result is a boolean determination with an explanatory message indicating whether the pipeline is SOX-scoped or not. If the pipeline is not found in the registry, CKOD defaults to treating it as SOX-compliant for safety.

## Trigger

- **Type**: api-call
- **Source**: Deployment automation, CI pipeline, or engineer calls `GET /deployments/sox?deploybot_url={url}`
- **Frequency**: On-demand (per deployment pipeline evaluation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CKOD API Resource (`DeploymentResource`) | Receives request and delegates to service layer | `continuumCkodBackendJtier` |
| CKOD Domain Service (`DeploymentService`) | Orchestrates SOX determination logic | `continuumCkodBackendJtier` |
| CKOD Integration Client (`HttpClient.isSoxPipeline()`) | Fetches SOX scoping CSV from GitHub | `continuumCkodBackendJtier` |
| GitHub Enterprise | Hosts the `pipeline-sox-scopings` repository containing `PIPELINES_PROD.csv` | `githubEnterprise` |

## Steps

1. **Receive check request**: API Resource receives `GET /deployments/sox?deploybot_url={url}`. The `deploybot_url` parameter is required.
   - From: Caller
   - To: `continuumCkodApiResources`
   - Protocol: REST

2. **Extract repository from Deploybot URL**: Parses the Deploybot URL to extract the GitHub `org` and `repo` values that identify the pipeline.
   - From: `continuumCkodDomainServices`
   - To: (internal)
   - Protocol: Direct (in-process)

3. **Fetch SOX scoping CSV**: Calls `GET https://api.github.groupondev.com/repos/asadauskas/pipeline-sox-scopings/contents/PIPELINES_PROD.csv` with `Accept: application/vnd.github.v3.raw` and the `GITHUB_API_TOKEN` bearer token.
   - From: `continuumCkodIntegrationClients`
   - To: `githubEnterprise`
   - Protocol: HTTPS/REST

4. **Parse CSV and look up repo**: Reads the CSV line by line, locating columns `repo` and `SOX?`. Searches for a row matching the extracted repository name.
   - From: `continuumCkodDomainServices`
   - To: (internal)
   - Protocol: Direct (in-process)

5. **Return SOX determination**: Returns a `SoxDetermination` with:
   - `sox: false` and explanation message if the repo row has `SOX? = FALSE`
   - `sox: true` and explanation message if `SOX? = TRUE` or row is not `FALSE`
   - `sox: true` (safety default) with advisory message if the repository is not found in the CSV or if required columns are missing
   - From: `continuumCkodApiResources`
   - To: Caller
   - Protocol: REST/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GitHub API returns non-2xx | `IOException` thrown | Request fails; caller receives error |
| CSV header columns `repo` or `SOX?` missing | `IOException` thrown with descriptive message | Request fails |
| Repository not found in CSV | Returns `SoxDetermination(sox: true, "Repository not found in SOX registry — treating as SOX compliant for safety")` | Safe default: treated as SOX-scoped |
| CSV data unavailable (empty file) | Returns `SoxDetermination(sox: true, "SOX compliance data unavailable — treating as SOX compliant for safety")` | Safe default |
| `GITHUB_API_TOKEN` not set | `IllegalStateException` at service startup (not runtime) | Service will not start without this token |

## Sequence Diagram

```
Caller -> DeploymentResource: GET /deployments/sox?deploybot_url=...
DeploymentResource -> DeploymentService: isSoxPipeline(deploybotUrl)
DeploymentService -> HttpClient: isSoxPipeline(repo)
HttpClient -> githubEnterprise: GET /repos/asadauskas/pipeline-sox-scopings/contents/PIPELINES_PROD.csv
githubEnterprise --> HttpClient: CSV content (raw)
HttpClient -> HttpClient: parse CSV, lookup repo row
HttpClient --> DeploymentService: SoxDetermination(sox, message)
DeploymentService --> DeploymentResource: SoxResponseModel
DeploymentResource --> Caller: { sox: true/false, message: "..." }
```

## Related

- Architecture dynamic view: `dynamic-ckod-deployment-tracking-flow`
- Related flows: [Deployment Tracking — Keboola](deployment-tracking-keboola.md), [Deployment Tracking — Airflow](deployment-tracking-airflow.md)
