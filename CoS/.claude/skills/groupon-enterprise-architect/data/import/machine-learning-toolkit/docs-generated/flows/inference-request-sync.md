---
service: "machine-learning-toolkit"
title: "Synchronous Inference Request Flow"
generated: "2026-03-03"
type: flow
flow_name: "inference-request-sync"
flow_type: synchronous
trigger: "POST request to API Gateway inference endpoint with valid API key"
participants:
  - "administrator"
  - "continuumMlToolkitApiGateway"
  - "continuumMlToolkitSageMakerEndpoints"
  - "continuumMlToolkitDataBuckets"
  - "continuumMlToolkitCloudWatch"
architecture_ref: "dynamic-inference-request-flow"
---

# Synchronous Inference Request Flow

## Summary

An authorized caller submits a JSON inference payload to the private API Gateway at the path `/{version}/{api_name}`. The API Gateway validates the request (schema, API key, content type), then immediately invokes the corresponding SageMaker endpoint using a direct AWS service integration. The SageMaker endpoint reads any required feature data from S3, runs the model, and returns the inference result inline. The full round-trip completes within the API Gateway's 29-second timeout.

## Trigger

- **Type**: API call
- **Source**: Authorized internal caller (data scientist, downstream service, or batch job) with a valid `X-API-Key` header
- **Frequency**: On-demand, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller | Initiates POST request with JSON payload and API key | — |
| ML Toolkit API Gateway | Validates request, applies API key check, routes to SageMaker | `continuumMlToolkitApiGateway` |
| Version Routing | Resolves the `/{version}` path segment to the correct API resource | `continuumMlToolkitVersionRouting` |
| Inference Routing | Maps the `/{api_name}` segment to the SageMaker integration | `continuumMlToolkitInferenceRouting` |
| Request Validation and Models | Validates JSON schema, required headers, and query parameters | `continuumMlToolkitRequestValidation` |
| Usage Plans and API Keys | Enforces API key authentication and usage plan throttle limits | `continuumMlToolkitUsagePlans` |
| SageMaker Invocation Adapter | Constructs the SageMaker Runtime invocation URI and passes IAM credentials | `continuumMlToolkitSageMakerInvocationAdapter` |
| ML Toolkit SageMaker Endpoints | Runs the inference model container; reads features if needed; returns prediction | `continuumMlToolkitSageMakerEndpoints` |
| ML Toolkit Data Buckets | Provides feature/model artifacts read by the SageMaker container | `continuumMlToolkitDataBuckets` |
| ML Toolkit CloudWatch | Receives API Gateway access logs and SageMaker invocation metrics | `continuumMlToolkitCloudWatch` |

## Steps

1. **Receives inference request**: Caller sends `POST /{version}/{api_name}` with `X-API-Key` header and JSON body.
   - From: Caller
   - To: `continuumMlToolkitApiGateway`
   - Protocol: HTTPS (private VPC endpoint)

2. **Validates API key and usage plan**: API Gateway checks the `X-API-Key` against the provisioned usage plan; rejects with 403 if invalid.
   - From: `continuumMlToolkitUsagePlans`
   - To: `continuumMlToolkitInferenceRouting`
   - Protocol: Internal API Gateway processing

3. **Validates request schema**: API Gateway request validator checks JSON body against the endpoint's model schema, required headers, and query parameters; rejects with 400 if invalid.
   - From: `continuumMlToolkitRequestValidation`
   - To: `continuumMlToolkitInferenceRouting`
   - Protocol: Internal API Gateway processing

4. **Maps request to SageMaker invocation**: SageMaker Invocation Adapter constructs the SageMaker Runtime invocation URI (`arn:aws:apigateway:{region}:runtime.sagemaker:path//endpoints/{endpoint-name}/invocations`) and attaches the project service role as credentials.
   - From: `continuumMlToolkitSageMakerInvocationAdapter`
   - To: `continuumMlToolkitSageMakerEndpoints`
   - Protocol: AWS service integration (HTTPS to SageMaker Runtime)

5. **Reads feature/model artifacts**: SageMaker endpoint container loads any required feature data or model artifacts from S3 during inference.
   - From: `continuumMlToolkitSageMakerEndpoints`
   - To: `continuumMlToolkitDataBuckets`
   - Protocol: S3 SDK

6. **Runs model and returns prediction**: SageMaker endpoint executes the model and returns the inference result to API Gateway.
   - From: `continuumMlToolkitSageMakerEndpoints`
   - To: `continuumMlToolkitApiGateway`
   - Protocol: HTTPS (SageMaker Runtime response)

7. **Emits invocation metrics and logs**: SageMaker endpoint emits invocation count, latency, and error metrics.
   - From: `continuumMlToolkitSageMakerEndpoints`
   - To: `continuumMlToolkitCloudWatch`
   - Protocol: CloudWatch SDK

8. **Emits API execution logs**: API Gateway logs access and execution details.
   - From: `continuumMlToolkitApiGateway`
   - To: `continuumMlToolkitCloudWatch`
   - Protocol: CloudWatch

9. **Returns inference response to caller**: API Gateway returns the SageMaker result (HTTP 200) or an error response.
   - From: `continuumMlToolkitApiGateway`
   - To: Caller
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or missing API key | API Gateway returns 403 | Request rejected; caller must obtain valid API key |
| Non-JSON body | API Gateway returns 415 | Request rejected; caller must set `Content-Type: application/json` |
| Schema validation failure | API Gateway returns 400 with error message | Request rejected; caller must fix payload |
| SageMaker application error | API Gateway maps to 424; response includes `OriginalMessage` from SageMaker | Caller receives SageMaker error details |
| SageMaker endpoint unavailable | API Gateway maps to 503 | Caller should retry; operator should check endpoint health and autoscaling policy |
| API Gateway timeout (> 29 seconds) | API Gateway returns 504 | Caller should retry with smaller payload or use async mode |

## Sequence Diagram

```
Caller -> continuumMlToolkitApiGateway: POST /{version}/{api_name} (X-API-Key, JSON body)
continuumMlToolkitApiGateway -> continuumMlToolkitUsagePlans: Validate API key
continuumMlToolkitApiGateway -> continuumMlToolkitRequestValidation: Validate request schema
continuumMlToolkitApiGateway -> continuumMlToolkitSageMakerInvocationAdapter: Map to SageMaker invocation URI
continuumMlToolkitSageMakerInvocationAdapter -> continuumMlToolkitSageMakerEndpoints: POST /invocations (IAM-signed)
continuumMlToolkitSageMakerEndpoints -> continuumMlToolkitDataBuckets: GetObject (feature/model artifacts)
continuumMlToolkitDataBuckets --> continuumMlToolkitSageMakerEndpoints: Feature data
continuumMlToolkitSageMakerEndpoints -> continuumMlToolkitCloudWatch: Emit invocation metrics
continuumMlToolkitSageMakerEndpoints --> continuumMlToolkitApiGateway: 200 inference result
continuumMlToolkitApiGateway -> continuumMlToolkitCloudWatch: Emit access logs
continuumMlToolkitApiGateway --> Caller: 200 inference result
```

## Related

- Architecture dynamic view: `dynamic-inference-request-flow`
- Related flows: [Asynchronous Inference Request](inference-request-async.md)
- See [API Surface](../api-surface.md) for endpoint contracts
- See [Runbook](../runbook.md) for SageMaker error troubleshooting steps
