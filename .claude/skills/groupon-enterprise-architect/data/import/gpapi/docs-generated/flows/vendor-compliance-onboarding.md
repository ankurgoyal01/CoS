---
service: "gpapi"
title: "Vendor Compliance Onboarding"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "vendor-compliance-onboarding"
flow_type: synchronous
trigger: "Vendor submits compliance documentation via Vendor Portal"
participants:
  - "continuumGpapiService"
  - "continuumGpapiDb"
  - "continuumVendorComplianceService"
  - "Amazon S3"
architecture_ref: "dynamic-vendorOnboardingFlow"
---

# Vendor Compliance Onboarding

## Summary

The vendor compliance onboarding flow orchestrates the collection and verification of vendor compliance documentation through gpapi. Vendors submit required compliance data and supporting documents via the Vendor Portal; gpapi stores documents in Amazon S3, persists compliance state in its database, and delegates the verification workflow to the Vendor Compliance Service. This flow is often triggered as part of the broader [Vendor Onboarding](vendor-onboarding.md) flow but can also be re-triggered independently when compliance documentation needs renewal.

## Trigger

- **Type**: api-call
- **Source**: Vendor submitting compliance documentation via Vendor Portal UI
- **Frequency**: On demand (initial onboarding and periodic compliance renewal)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Vendor Portal UI | Collects and submits compliance data and documents | — |
| Goods Product API | Orchestrates compliance data flow; owns local compliance state | `continuumGpapiService` |
| gpapi Database | Stores vendor compliance status and metadata | `continuumGpapiDb` |
| Amazon S3 | Stores uploaded compliance documents | — |
| Vendor Compliance Service | Performs compliance verification and status management | `continuumVendorComplianceService` |

## Steps

1. **Receive compliance submission**: Vendor Portal UI submits compliance data and optional document files.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v1/vendor_compliance`
   - Protocol: REST (multipart form data for file uploads)

2. **Upload documents to S3**: gpapi uploads any attached compliance documents to Amazon S3.
   - From: `continuumGpapiService`
   - To: Amazon S3 (AWS SDK)
   - Protocol: HTTPS SDK

3. **Persist compliance record**: gpapi writes the compliance submission record with status `pending_review` and S3 document references.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

4. **Submit to Vendor Compliance Service**: gpapi forwards the compliance data and document references to the Vendor Compliance Service for verification.
   - From: `continuumGpapiService`
   - To: `continuumVendorComplianceService` (submit compliance data)
   - Protocol: REST

5. **Return submission confirmation**: gpapi returns the compliance submission result to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 200 OK with compliance status)

6. **Poll or receive compliance status update**: Subsequently, Vendor Portal UI polls for compliance status via `GET /api/v1/vendor_compliance`.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `GET /api/v1/vendor_compliance`
   - Protocol: REST

7. **Fetch status from Vendor Compliance Service**: gpapi retrieves the current compliance verification status.
   - From: `continuumGpapiService`
   - To: `continuumVendorComplianceService`
   - Protocol: REST

8. **Return compliance status**: gpapi returns current compliance status to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 200 OK)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 upload failure | Return 503 with upload error | Documents not stored; submission blocked |
| Vendor Compliance Service unavailable | Return 503 or queue for retry | Compliance submission deferred |
| Invalid compliance data | Return 422 Unprocessable Entity | Submission rejected |
| Duplicate compliance submission | Return 422 with conflict message | Existing submission preserved |

## Sequence Diagram

```
VendorPortalUI -> continuumGpapiService: POST /api/v1/vendor_compliance (data + documents)
continuumGpapiService -> AmazonS3: upload compliance documents
AmazonS3 --> continuumGpapiService: S3 document URLs
continuumGpapiService -> continuumGpapiDb: INSERT compliance record (status: pending_review)
continuumGpapiService -> continuumVendorComplianceService: submit compliance data + document refs
continuumVendorComplianceService --> continuumGpapiService: 200 OK (compliance_id, status)
continuumGpapiService --> VendorPortalUI: 200 OK (compliance submission confirmation)
```

## Related

- Architecture dynamic view: `dynamic-vendorOnboardingFlow`
- Related flows: [Vendor Onboarding](vendor-onboarding.md), [Session Auth 2FA](session-auth-2fa.md)
