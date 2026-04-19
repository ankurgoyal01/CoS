---
service: "contract_service"
title: "Contract Creation"
generated: "2026-03-03"
type: flow
flow_name: "contract-creation"
flow_type: synchronous
trigger: "POST /v1/contracts called by merchant-self-service-engine"
participants:
  - "continuumMerchantSelfService"
  - "continuumContractService"
  - "contractSvc_contractsApi"
  - "contractSvc_contractStore"
  - "contractSvc_definitionStore"
  - "continuumContractMysql"
architecture_ref: "dynamic-continuumContractService"
---

# Contract Creation

## Summary

This flow describes how a new contract instance is created for a specific merchant opportunity. The merchant self-service engine submits merchant data (`user_data`) along with a reference to a contract definition UUID. Contract Service validates the data against the definition's XSD schema, persists the contract and its initial version, and returns the new contract's UUID. The Salesforce opportunity ID is extracted from `user_data` and stored as a secondary lookup key.

## Trigger

- **Type**: api-call
- **Source**: Merchant Self-Service Engine (`continuumMerchantSelfService`) during the deal creation workflow
- **Frequency**: On-demand; once per merchant deal submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Self-Service Engine | Initiator; submits merchant data and definition reference | `continuumMerchantSelfService` |
| Contract Service (Cicero) | Receives request, validates data, and persists contract | `continuumContractService` |
| Contracts API | Rails controller handling the POST request | `contractSvc_contractsApi` |
| Contract Models | ActiveRecord layer for contract and version persistence | `contractSvc_contractStore` |
| Definition Models | Looks up the referenced contract definition | `contractSvc_definitionStore` |
| Contract Service MySQL | Persists contract and initial version records | `continuumContractMysql` |

## Steps

1. **Send POST request**: Merchant Self-Service Engine sends `POST /v1/contracts` with a JSON body containing `user_data` (merchant-specific fields as an object) and `contract_definition` (UUID string of the definition to use).
   - From: `continuumMerchantSelfService`
   - To: `continuumContractService`
   - Protocol: REST / HTTP

2. **Route to controller**: Nginx proxies to Unicorn; Rails routes to `V1::ContractsController#create`.
   - From: Nginx (in-pod)
   - To: `contractSvc_contractsApi`
   - Protocol: HTTP (in-pod)

3. **Resolve contract definition**: Controller calls `ContractDefinition.find_by_uuid(params[:contract_definition])` to load the referenced definition record from MySQL.
   - From: `contractSvc_contractsApi`
   - To: `contractSvc_definitionStore`
   - Protocol: In-process

4. **Extract Salesforce ID**: Controller extracts `user_data['sf-opportunity-id']` and stores it as `salesforce_id` on the contract for secondary lookup support.
   - From: `contractSvc_contractsApi`
   - To: `contractSvc_contractStore`
   - Protocol: In-process

5. **Instantiate and validate contract**: A `Contract` model is built with `user_data`, `contract_definition`, and `salesforce_id`. Validations run: `user_data` presence, `contract_definition` presence, and `user_data_complies_with_schema` (XSD validation via `DocumentRenderer`).
   - From: `contractSvc_contractStore`
   - To: `contractSvc_documentRenderer`
   - Protocol: In-process

6. **Persist contract and initial version**: On valid save, an `INSERT` is issued for the `contracts` table. A `before_save` / `autosave` on `versions` creates the first `ContractVersion` record with `version = 1` and the supplied `user_data`.
   - From: `contractSvc_contractStore`
   - To: `continuumContractMysql`
   - Protocol: MySQL

7. **Return created contract**: Controller renders the persisted `Contract` as JSON with status `201 Created`, including the UUID, created_at, updated_at, user_data, version (1), and contract_definition UUID.
   - From: `contractSvc_contractsApi`
   - To: `continuumMerchantSelfService`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `user_data` missing | Presence validation fails | `422 Unprocessable Entity` with `user_data` errors |
| `contract_definition` UUID not found | `find_by_uuid` returns nil; presence validation fails | `422 Unprocessable Entity` with `contract_definition` errors |
| `user_data` fails XSD schema validation | `user_data_complies_with_schema` validation adds errors | `422 Unprocessable Entity` with per-field schema error messages |
| Database write failure | ActiveRecord raises exception | `500 Internal Server Error` (unhandled) |

## Sequence Diagram

```
MerchantSelfService -> ContractsAPI: POST /v1/contracts (user_data, contract_definition UUID)
ContractsAPI -> DefinitionModels: ContractDefinition.find_by_uuid(uuid)
DefinitionModels -> MySQL: SELECT * FROM contract_definitions WHERE uuid = ?
MySQL --> DefinitionModels: ContractDefinition record
DefinitionModels --> ContractsAPI: definition object
ContractsAPI -> ContractModels: Contract.new(user_data, contract_definition, salesforce_id)
ContractModels -> DocumentRenderer: valid_data?(user_data)
DocumentRenderer --> ContractModels: validation result
ContractModels -> MySQL: INSERT contracts
ContractModels -> MySQL: INSERT contract_versions (version=1)
MySQL --> ContractModels: saved records
ContractModels --> ContractsAPI: Contract object
ContractsAPI --> MerchantSelfService: 201 Created (JSON contract with UUID)
```

## Related

- Architecture dynamic view: `dynamic-continuumContractService`
- Related flows: [Contract Definition Upload](contract-definition-upload.md), [Contract Rendering](contract-rendering.md), [Contract Signing](contract-signing.md), [Contract Update and Versioning](contract-update-versioning.md)
