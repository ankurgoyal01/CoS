---
service: "gpapi"
title: "Contract Lifecycle"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "contract-lifecycle"
flow_type: synchronous
trigger: "Vendor or Groupon initiates contract creation or amendment via Vendor Portal"
participants:
  - "continuumGpapiService"
  - "continuumGpapiDb"
  - "Commerce Interface"
  - "Accounting Service"
architecture_ref: "dynamic-vendorOnboardingFlow"
---

# Contract Lifecycle

## Summary

The contract lifecycle flow manages the creation, amendment, and status transitions of vendor contracts within the Goods Vendor Portal. gpapi owns the canonical contract record and orchestrates downstream notifications to Commerce Interface for commerce workflow integration and to the Accounting Service for financial tracking. Contracts progress through states (draft, pending signature, active, expired, terminated).

## Trigger

- **Type**: api-call
- **Source**: Vendor or Groupon admin initiating a contract action via Vendor Portal UI
- **Frequency**: On demand (per contract create/update action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Vendor Portal UI | Initiates contract actions | — |
| Goods Product API | Owns contract record; orchestrates downstream coordination | `continuumGpapiService` |
| gpapi Database | Stores canonical contract records | `continuumGpapiDb` |
| Commerce Interface | Receives contract state changes for commerce workflow | — |
| Accounting Service | Receives contract data for financial tracking | — |

## Steps

### Create Contract

1. **Receive create request**: Vendor Portal UI submits new contract payload.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v1/contracts`
   - Protocol: REST

2. **Validate contract data**: gpapi validates vendor existence and contract terms.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb` (validate vendor_id)
   - Protocol: PostgreSQL

3. **Persist contract record**: gpapi writes the contract record with status `draft`.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

4. **Notify Commerce Interface**: gpapi sends the draft contract to Commerce Interface for commerce workflow registration.
   - From: `continuumGpapiService`
   - To: Commerce Interface
   - Protocol: REST

5. **Return created contract**: gpapi returns the contract record to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 201 Created)

### Activate Contract (status transition to active)

6. **Receive activation**: Vendor or admin confirms contract (e.g., both parties sign).
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `PATCH /api/v1/contracts/:id` (status: active)
   - Protocol: REST

7. **Update contract status**: gpapi transitions the contract to `active`.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

8. **Notify Accounting Service**: gpapi notifies Accounting Service of the active contract for financial tracking.
   - From: `continuumGpapiService`
   - To: Accounting Service
   - Protocol: REST

9. **Return updated contract**: gpapi returns the active contract to the requestor.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 200 OK)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Vendor not found | Return 404 Not Found | Contract not created |
| Missing required contract terms | Return 422 Unprocessable Entity | Contract not created |
| Commerce Interface unavailable | Return 503 or error | Contract created locally but not registered for commerce |
| Accounting Service unavailable | Return 503 or error | Contract active but not tracked in accounting |

## Sequence Diagram

```
VendorPortalUI -> continuumGpapiService: POST /api/v1/contracts (contract data)
continuumGpapiService -> continuumGpapiDb: SELECT vendor (validate)
continuumGpapiDb --> continuumGpapiService: vendor found
continuumGpapiService -> continuumGpapiDb: INSERT contract (status: draft)
continuumGpapiService -> CommerceInterface: register draft contract
CommerceInterface --> continuumGpapiService: 200 OK
continuumGpapiService --> VendorPortalUI: 201 Created (contract record)
```

## Related

- Architecture dynamic view: `dynamic-vendorOnboardingFlow`
- Related flows: [Vendor Onboarding](vendor-onboarding.md), [Promotion Management](promotion-management.md)
