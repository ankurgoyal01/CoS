---
service: "gpapi"
title: "Vendor Onboarding"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "vendor-onboarding"
flow_type: synchronous
trigger: "New vendor registration request submitted via Goods Vendor Portal"
participants:
  - "continuumGpapiService"
  - "continuumGpapiDb"
  - "continuumVendorComplianceService"
  - "Users Service"
  - "DMAPI"
  - "Goods Product Catalog"
architecture_ref: "dynamic-vendorOnboardingFlow"
---

# Vendor Onboarding

## Summary

Vendor onboarding is the process by which a new goods vendor is registered in the Groupon Vendor Portal and provisioned across the necessary downstream Continuum services. gpapi orchestrates the full sequence: creating vendor and user records, initiating compliance verification, registering the merchant in DMAPI, and setting up the vendor's product catalog presence. This flow is the starting point for all subsequent vendor operations.

## Trigger

- **Type**: api-call
- **Source**: Goods Vendor Portal UI submitting a new vendor registration form
- **Frequency**: On demand (per new vendor registration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Goods Vendor Portal UI | Initiates registration; collects vendor details | — |
| Goods Product API | Orchestrates onboarding sequence; owns vendor and user records | `continuumGpapiService` |
| gpapi Database | Persists vendor and user records | `continuumGpapiDb` |
| Users Service | Creates and links portal user account | — |
| DMAPI | Registers merchant entity | — |
| Goods Product Catalog | Provisions vendor's catalog presence | — |
| Vendor Compliance Service | Initiates compliance verification workflow | `continuumVendorComplianceService` |

## Steps

1. **Receive registration request**: Vendor Portal UI submits vendor registration payload.
   - From: Goods Vendor Portal UI
   - To: `continuumGpapiService` `POST /api/v1/vendors`
   - Protocol: REST

2. **Validate vendor data**: gpapi validates the incoming vendor payload against required fields and business rules.
   - From: `continuumGpapiService`
   - To: `continuumGpapiService` (internal validation)
   - Protocol: direct

3. **Create vendor record**: gpapi persists the new vendor record in the database.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

4. **Create portal user account**: gpapi calls Users Service to provision the vendor's admin user.
   - From: `continuumGpapiService`
   - To: Users Service `POST /users`
   - Protocol: REST

5. **Link user to vendor**: gpapi persists the user-vendor association record.
   - From: `continuumGpapiService`
   - To: `continuumGpapiDb`
   - Protocol: PostgreSQL

6. **Register merchant in DMAPI**: gpapi calls DMAPI to create the corresponding merchant entity.
   - From: `continuumGpapiService`
   - To: DMAPI `POST /merchants`
   - Protocol: REST

7. **Provision catalog presence**: gpapi calls Goods Product Catalog to initialize the vendor's catalog entry.
   - From: `continuumGpapiService`
   - To: Goods Product Catalog
   - Protocol: REST

8. **Initiate compliance verification**: gpapi calls Vendor Compliance Service to start the compliance onboarding workflow.
   - From: `continuumGpapiService`
   - To: `continuumVendorComplianceService`
   - Protocol: REST

9. **Return onboarding result**: gpapi returns the created vendor record and initial status to the Vendor Portal UI.
   - From: `continuumGpapiService`
   - To: Goods Vendor Portal UI
   - Protocol: REST (HTTP 201 Created)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Vendor data validation failure | Return 422 Unprocessable Entity with field-level errors | Vendor not created; user shown validation errors |
| Users Service unavailable | Return 503 / propagate error | Onboarding blocked; vendor record may be partially created |
| DMAPI registration failure | Return error to portal | Vendor record created in gpapi but merchant not registered in DMAPI |
| Vendor Compliance Service failure | Return error or continue with deferred compliance | Compliance initiation deferred; vendor marked as pending compliance |
| Database write failure | Return 500 Internal Server Error | Onboarding fails; no partial state committed |

## Sequence Diagram

```
VendorPortalUI -> continuumGpapiService: POST /api/v1/vendors (vendor details)
continuumGpapiService -> continuumGpapiDb: INSERT vendor record
continuumGpapiService -> UsersService: POST /users (create admin user)
UsersService --> continuumGpapiService: 201 Created (user_id)
continuumGpapiService -> continuumGpapiDb: INSERT user-vendor link
continuumGpapiService -> DMAPI: POST /merchants (register merchant)
DMAPI --> continuumGpapiService: 201 Created (merchant_id)
continuumGpapiService -> GoodsProductCatalog: provision catalog entry
GoodsProductCatalog --> continuumGpapiService: 200 OK
continuumGpapiService -> continuumVendorComplianceService: initiate compliance workflow
continuumVendorComplianceService --> continuumGpapiService: 200 OK (compliance_id)
continuumGpapiService --> VendorPortalUI: 201 Created (vendor record)
```

## Related

- Architecture dynamic view: `dynamic-vendorOnboardingFlow`
- Related flows: [User-Vendor Linking](user-vendor-linking.md), [Vendor Compliance Onboarding](vendor-compliance-onboarding.md), [Session Auth 2FA](session-auth-2fa.md)
