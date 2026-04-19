---
service: "contract_service"
title: "Contract Signing"
generated: "2026-03-03"
type: flow
flow_name: "contract-signing"
flow_type: synchronous
trigger: "POST /v1/contracts/{id}/sign called by merchant-self-service-engine"
participants:
  - "continuumMerchantSelfService"
  - "continuumContractService"
  - "contractSvc_contractsApi"
  - "contractSvc_contractStore"
  - "continuumContractMysql"
architecture_ref: "dynamic-continuumContractService"
---

# Contract Signing

## Summary

This flow records a merchant's agreement to a contract by attaching a cryptographically or acceptance-traceable identity record. The merchant self-service engine calls the sign endpoint with identity information (type, name, and optional extra fields such as electronic signature and certificate). Contract Service captures the caller's IP address, builds the appropriate `Identity` subclass (Acceptance or Electronic), and associates it with the contract. Once signed, the contract becomes immutable — no further updates or deletions are permitted. Signing is idempotent in one direction only: a contract can be signed exactly once.

## Trigger

- **Type**: api-call
- **Source**: Merchant Self-Service Engine (`continuumMerchantSelfService`) after the merchant accepts the contract terms in the deal builder UI
- **Frequency**: Once per contract; a contract can only be signed once

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Self-Service Engine | Submits identity information on behalf of the merchant | `continuumMerchantSelfService` |
| Contract Service (Cicero) | Validates and persists the signature; locks the contract | `continuumContractService` |
| Contracts API | Rails controller handling the POST /sign request | `contractSvc_contractsApi` |
| Contract Models | Applies the signature and enforces immutability rules | `contractSvc_contractStore` |
| Contract Service MySQL | Persists the Identity record and updates the contract | `continuumContractMysql` |

## Steps

1. **Send POST /sign request**: Merchant Self-Service Engine sends `POST /v1/contracts/{uuid}/sign` with a JSON body containing `type` (e.g., `acceptance` or `electronic`), `name`, and optionally `extra_information` (for electronic type: `signature` and `certificate` fields are required).
   - From: `continuumMerchantSelfService`
   - To: `continuumContractService`
   - Protocol: REST / HTTP

2. **Route to controller**: Nginx proxies to Unicorn; Rails routes to `V1::ContractsController#sign`.
   - From: Nginx (in-pod)
   - To: `contractSvc_contractsApi`
   - Protocol: HTTP (in-pod)

3. **Load contract**: Controller calls `Contract.find_by_uuid!(params[:id])` to retrieve the target contract.
   - From: `contractSvc_contractsApi`
   - To: `contractSvc_contractStore`
   - Protocol: In-process

4. **Capture IP address**: The caller's IP address is captured from `request.remote_ip` and appended to the identity parameters.
   - From: `contractSvc_contractsApi`
   - To: `contractSvc_contractsApi`
   - Protocol: In-process (Rack request object)

5. **Build identity object**: `Identity.build_from_request` dynamically instantiates the correct subclass (`Identity::Acceptance` or `Identity::Electronic`) based on the `type` parameter.
   - From: `contractSvc_contractsApi`
   - To: `contractSvc_contractStore`
   - Protocol: In-process

6. **Validate identity**: For `Identity::Electronic`, extra_information must include `signature` and `certificate` fields. All identity types require `ip_address` presence. If the contract already has a signature, the `sign` method immediately returns false with "contract is already signed".
   - From: `contractSvc_contractStore`
   - To: `contractSvc_contractStore`
   - Protocol: In-process

7. **Enforce signature exclusivity**: The `signature_is_exclusive` validation confirms the identity object is not already used on another contract, preventing shared signatures.
   - From: `contractSvc_contractStore`
   - To: `continuumContractMysql`
   - Protocol: MySQL (SELECT count check)

8. **Persist signature**: The identity record is inserted into the `identities` table; the `contracts.signature_id` column is updated to reference the new identity.
   - From: `contractSvc_contractStore`
   - To: `continuumContractMysql`
   - Protocol: MySQL

9. **Return success**: Controller renders `204 No Content` on success.
   - From: `contractSvc_contractsApi`
   - To: `continuumMerchantSelfService`
   - Protocol: REST / HTTP

10. **Lock contract**: From this point forward, any `PUT` or `DELETE` on the contract returns `422 Unprocessable Entity` with "cannot modify or delete a signed contract" because the `check_signature` `before_update` / `before_destroy` callback detects the attached signature.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Contract UUID not found | `find_by_uuid!` raises `ActiveRecord::RecordNotFound` | `404 Not Found` |
| Contract already signed | `sign` method detects existing signature | `422 Unprocessable Entity` — "contract is already signed" |
| Electronic identity missing `signature` or `certificate` | `Identity::Electronic` validation fails | `422 Unprocessable Entity` with `extra_information` errors |
| `ip_address` absent (should not occur via Rails) | `Identity` base class validation | `422 Unprocessable Entity` |
| Identity object already used on another contract | `signature_is_exclusive` validation | `422 Unprocessable Entity` — "an identity object can only be used on one contract" |

## Sequence Diagram

```
MerchantSelfService -> ContractsAPI: POST /v1/contracts/{uuid}/sign (type, name, extra_information)
ContractsAPI -> ContractModels: Contract.find_by_uuid!(uuid)
ContractModels -> MySQL: SELECT * FROM contracts WHERE uuid = ?
MySQL --> ContractModels: Contract row
ContractModels --> ContractsAPI: Contract object
ContractsAPI -> ContractModels: Identity.build_from_request(type, name, ip_address, extra_information)
ContractModels --> ContractsAPI: Identity::Acceptance or Identity::Electronic object
ContractsAPI -> ContractModels: contract.sign(identity)
ContractModels -> ContractModels: check if already signed
ContractModels -> MySQL: SELECT COUNT(*) FROM contracts WHERE signature_id = ?
MySQL --> ContractModels: count (exclusivity check)
ContractModels -> MySQL: INSERT INTO identities (uuid, type, ip_address, name, extra_information)
ContractModels -> MySQL: UPDATE contracts SET signature_id = ? WHERE id = ?
MySQL --> ContractModels: success
ContractModels --> ContractsAPI: true
ContractsAPI --> MerchantSelfService: 204 No Content
```

## Related

- Architecture dynamic view: `dynamic-continuumContractService`
- Related flows: [Contract Creation](contract-creation.md), [Contract Rendering](contract-rendering.md), [Contract Update and Versioning](contract-update-versioning.md)
