---
service: "gcp-aiaas-terraform"
title: "Synchronous AI Inference via API Gateway"
generated: "2026-03-03"
type: flow
flow_name: "api-gateway-inference"
flow_type: synchronous
trigger: "HTTP POST request to a /v1/* inference endpoint via GCP API Gateway"
participants:
  - "External caller (internal Groupon service or Merchant Advisor tooling)"
  - "continuumApiGateway"
  - "continuumCloudFunctionsGen2"
  - "continuumVertexAi"
  - "continuumStorageBuckets"
  - "continuumSecretManager"
architecture_ref: "containers-gcp-aiaas"
---

# Synchronous AI Inference via API Gateway

## Summary

An internal consumer (e.g., Merchant Advisor tooling) submits an HTTP POST request to one of the `/v1/*` inference endpoints exposed by GCP API Gateway. The gateway validates the API key, routes the request to the appropriate Cloud Function (Gen 2) backend, and the function performs ML inference — optionally calling Vertex AI endpoints, reading model artefacts from Cloud Storage, and reading secrets from Secret Manager. The function returns the inference result as a JSON array to the gateway, which relays it back to the caller.

## Trigger

- **Type**: api-call
- **Source**: Internal consumer (Merchant Advisor tooling or another Groupon service) sending an HTTPS POST
- **Frequency**: On-demand (per-request, driven by merchant advisor workflows)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| External caller | Initiates the inference request | N/A |
| API Gateway | Validates API key; routes request to Cloud Function backend | `continuumApiGateway` |
| Cloud Functions Gen 2 | Executes ML inference logic; orchestrates downstream GCP calls | `continuumCloudFunctionsGen2` |
| Vertex AI | Serves ML model predictions when the function routes to a model endpoint | `continuumVertexAi` |
| Cloud Storage Buckets | Provides model artefacts or input data read by the function | `continuumStorageBuckets` |
| Secret Manager | Provides runtime secrets (API tokens, DB credentials) to the function | `continuumSecretManager` |

## Steps

1. **Receives inference request**: Caller sends `POST /v1/<endpoint>` with `Content-Type: application/json` and a valid API key header.
   - From: External caller
   - To: `continuumApiGateway`
   - Protocol: HTTPS

2. **Validates API key**: API Gateway checks the API key against the configured key set; rejects with HTTP 403 if invalid.
   - From: `continuumApiGateway`
   - To: `continuumApiGateway` (internal check)
   - Protocol: GCP API Gateway security

3. **Routes request to Cloud Function**: API Gateway forwards the request to the matching Cloud Function backend URL (e.g., `https://us-central1-prj-grp-aiaas-prod-0052.cloudfunctions.net/<function_name>`) with a backend deadline of 600 seconds.
   - From: `continuumApiGateway`
   - To: `continuumCloudFunctionsGen2`
   - Protocol: HTTPS (`x-google-backend`)

4. **Reads runtime secrets**: The Cloud Function reads required secrets (API tokens, credentials) from Secret Manager at startup or on-demand.
   - From: `continuumCloudFunctionsGen2`
   - To: `continuumSecretManager`
   - Protocol: GCP SDK

5. **Reads model artefacts or input data (optional)**: The function reads any required model files or input data from Cloud Storage.
   - From: `continuumCloudFunctionsGen2`
   - To: `continuumStorageBuckets`
   - Protocol: GCP SDK

6. **Invokes Vertex AI model endpoint (optional)**: For endpoints backed by Vertex AI, the function calls the relevant model endpoint to obtain predictions.
   - From: `continuumCloudFunctionsGen2`
   - To: `continuumVertexAi`
   - Protocol: HTTPS / GCP SDK

7. **Returns inference result**: The Cloud Function returns the result (JSON array) to the API Gateway.
   - From: `continuumCloudFunctionsGen2`
   - To: `continuumApiGateway`
   - Protocol: HTTPS

8. **Relays response to caller**: API Gateway relays the Cloud Function response back to the original caller.
   - From: `continuumApiGateway`
   - To: External caller
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid API key | API Gateway rejects with HTTP 403 | Caller receives 403; no Cloud Function invoked |
| Missing `Content-Type: application/json` | API Gateway or Cloud Function rejects with HTTP 415 | Caller receives 415 |
| Cloud Function application error | Cloud Function returns error to gateway | Caller receives HTTP 424 (Gateway Model Error) |
| Backend timeout (> 600s deadline) | API Gateway times out the connection | Caller receives HTTP 503 |
| Cloud Function unavailable / overloaded | API Gateway throttle or backend 503 | Caller receives HTTP 503; operator adjusts throttle or redeploys endpoint |

## Sequence Diagram

```
Caller        -> API Gateway          : POST /v1/<endpoint> [API Key]
API Gateway   -> API Gateway          : Validate API key
API Gateway   -> Cloud Function Gen 2 : Forward request (x-google-backend, deadline=600s)
Cloud Function -> Secret Manager      : Read secrets (GCP SDK)
Cloud Function -> Cloud Storage       : Read model artifacts (optional, GCP SDK)
Cloud Function -> Vertex AI           : Call model endpoint (optional, GCP SDK)
Vertex AI      --> Cloud Function     : Return predictions
Cloud Function --> API Gateway        : Return JSON result
API Gateway    --> Caller             : HTTP 200 JSON response
```

## Related

- Architecture dynamic view: `containers-gcp-aiaas`
- OpenAPI spec: `doc/swagger.yml`
- Related flows: [Async Background ML Processing Request](async-submit-request.md)
