---
service: "minio"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for MinIO.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Object Upload](object-upload.md) | synchronous | S3 PUT API call from a Continuum service | Client uploads an object to a bucket via the S3-compatible PUT API |
| [Object Download](object-download.md) | synchronous | S3 GET API call from a Continuum service | Client retrieves an object from a bucket via the S3-compatible GET API |
| [Service Deployment](service-deployment.md) | event-driven | Git push to main branch / DeployBot trigger | Docker image build and Kubernetes deployment across target environments |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |
| Event-driven (CI/CD) | 1 |

## Cross-Service Flows

The object upload and download flows are initiated by upstream Continuum platform services. The specific services that consume MinIO's S3 API are tracked in the central Groupon architecture model rather than in this repository. Refer to the Continuum platform architecture for cross-service flow definitions involving MinIO as a dependency.
