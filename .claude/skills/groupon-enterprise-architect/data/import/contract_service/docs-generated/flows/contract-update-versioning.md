---
service: "contract_service"
title: "Contract Update and Versioning"
generated: "2026-03-03"
type: flow
flow_name: "contract-update-versioning"
flow_type: synchronous
trigger: "PUT /v1/contracts/{id} called by merchant-self-service-engine"
participants:
  - "continuumMerchantSelfService"
  - "continuumContractService"
  - "contractSvc_contractsApi"
  - "contractSvc_contractStore"
  - "continuumContractMysql"
architecture_ref: "dynamic-continuumContractService"
---

# Contract Update and Versioning

## Summary

This flow describes how an existing unsigned contract's merchant data is updated and how Contract Service automatically maintains a complete version history. When `user_data` changes, the `bump_version` callback creates a new `ContractVersion` snapshot before the update is applied, preserving the prior state. This ensures full audit history of all data revisions. Signed contracts are rejected from any update attempt. The contract's `updated_at` timestamp is also refreshed on meaningful changes.

## Trigger

- **Type**: api-call
- **Source**: Merchant Self-Service Engine (`continuumMerchantSelfService`) when merchant deal data changes after initial contract creation
- **Frequency**: On-demand; one call per merchant data revision before contract signing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Self-Service Engine | Initiates the update with new `user_data` | `continuumMerchantSelfService` |
| Contract Service (Cicero) | Validates the update, creates a version snapshot, persists changes | `continuumContractService` |
| Contracts API | Rails controller handling the PUT request | `contractSvc_contractsApi` |
| Contract Models | Enforces immutability, runs version bump, delegates to ActiveRecord | `contractSvc_contractStore` |
| Contract Service MySQL | Persists the new version snapshot and updated contract record | `continuumContractMysql` |

## Steps

1. **Send PUT request**: Merchant Self-Service Engine sends `PUT /v1/contracts/{uuid}` with a JSON body containing the updated `user_data` object.
   - From: `continuumMerchantSelfService`
   - To: `continuumContractService`
   - Protocol: REST / HTTP

2. **Route to controller**: Nginx proxies to Unicorn; Rails routes to `V1::ContractsController#update`.
   - From: Nginx (in-pod)
   - To: `contractSvc_contractsApi`
   - Protocol: HTTP (in-pod)

3. **Load contract**: Controller calls `Contract.find_by_uuid!(params[:id])` to retrieve the target contract.
   - From: `contractSvc_contractsApi`
   - To: `contractSvc_contractStore`
   - Protocol: In-process

4. **Check signature (immutability guard)**: The `before_update` callback `check_signature` checks whether the contract has a signature attached. If signed, it adds an error and the update is aborted.
   - From: `contractSvc_contractStore`
   - To: `contractSvc_contractStore`
   - Protocol: In-process

5. **Compare user_data for change**: The `bump_version` `before_update` callback reloads the current `ContractVersion` from MySQL and compares its `user_data` to the incoming update. If the data has not changed, no new version is created and the update proceeds without incrementing.
   - From: `contractSvc_contractStore`
   - To: `continuumContractMysql`
   - Protocol: MySQL (reload current version)

6. **Create version snapshot**: If `user_data` has changed, `versions.create(user_data: current_user_data)` inserts a new `ContractVersion` row with the next sequential version number (set by the `set_version_number` before_create callback) and the prior data. The contract's `updated_at` is refreshed.
   - From: `contractSvc_contractStore`
   - To: `continuumContractMysql`
   - Protocol: MySQL (INSERT contract_versions)

7. **Persist updated contract**: `update_attributes(params.slice(:user_data))` applies the new `user_data` to the contract's current version via the delegated setter.
   - From: `contractSvc_contractStore`
   - To: `continuumContractMysql`
   - Protocol: MySQL (UPDATE contracts)

8. **Return success**: Controller renders `204 No Content` on success.
   - From: `contractSvc_contractsApi`
   - To: `continuumMerchantSelfService`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Contract UUID not found | `find_by_uuid!` raises `ActiveRecord::RecordNotFound` | `404 Not Found` |
| Contract is signed | `check_signature` before_update callback adds error | `422 Unprocessable Entity` — "cannot modify or delete a signed contract" |
| `user_data` validation fails | ActiveRecord validations fail on update | `422 Unprocessable Entity` with `user_data` errors |
| `user_data` unchanged | `bump_version` detects no diff; no new version created | `204 No Content` (idempotent) |

## Sequence Diagram

```
MerchantSelfService -> ContractsAPI: PUT /v1/contracts/{uuid} (user_data)
ContractsAPI -> ContractModels: Contract.find_by_uuid!(uuid)
ContractModels -> MySQL: SELECT * FROM contracts WHERE uuid = ?
MySQL --> ContractModels: Contract row
ContractModels --> ContractsAPI: Contract object
ContractsAPI -> ContractModels: contract.update_attributes(user_data)
ContractModels -> ContractModels: check_signature (before_update)
ContractModels -> MySQL: SELECT * FROM contract_versions WHERE contract_id = ? ORDER BY version (reload)
MySQL --> ContractModels: current ContractVersion
ContractModels -> ContractModels: compare user_data (bump_version)
ContractModels -> MySQL: INSERT INTO contract_versions (contract_id, version, user_data) [if changed]
MySQL --> ContractModels: new version saved
ContractModels -> MySQL: UPDATE contracts SET updated_at = ?
MySQL --> ContractModels: success
ContractModels --> ContractsAPI: true
ContractsAPI --> MerchantSelfService: 204 No Content
```

## Related

- Architecture dynamic view: `dynamic-continuumContractService`
- Related flows: [Contract Creation](contract-creation.md), [Contract Signing](contract-signing.md), [Contract Rendering](contract-rendering.md)
