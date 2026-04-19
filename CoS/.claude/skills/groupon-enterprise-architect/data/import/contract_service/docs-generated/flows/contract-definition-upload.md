---
service: "contract_service"
title: "Contract Definition Upload"
generated: "2026-03-03"
type: flow
flow_name: "contract-definition-upload"
flow_type: synchronous
trigger: "POST /v1/contract_definitions called by merchant-self-service-engine"
participants:
  - "continuumMerchantSelfService"
  - "continuumContractService"
  - "contractSvc_definitionsApi"
  - "contractSvc_definitionStore"
  - "continuumContractMysql"
architecture_ref: "dynamic-continuumContractService"
---

# Contract Definition Upload

## Summary

This flow describes how a new contract definition — consisting of a locale, name, XSD schema, sample data, and one or more XSLT/XSL render templates — is uploaded to Contract Service and persisted as a versioned record. The flow is triggered by the merchant-self-service-engine using a Rake task (`contract_definitions:upload`) and results in a new `ContractDefinition` record with an auto-assigned version number. If a definition with the same name already exists, the new record receives the next sequential version number.

## Trigger

- **Type**: api-call
- **Source**: Merchant Self-Service Engine (`continuumMerchantSelfService`) via `rake contract_definitions:upload[doc/contract_definitions/<name>]`
- **Frequency**: On-demand; whenever a new contract type is introduced or an existing template is updated

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Self-Service Engine | Initiator; calls the API with definition payload | `continuumMerchantSelfService` |
| Contract Service (Cicero) | Receives request, validates, and persists the definition | `continuumContractService` |
| Contract Definitions API | Rails controller handling the POST request | `contractSvc_definitionsApi` |
| Definition Models | ActiveRecord layer that persists the definition and templates | `contractSvc_definitionStore` |
| Contract Service MySQL | Durable store for the new definition record and template rows | `continuumContractMysql` |

## Steps

1. **Send POST request**: Merchant Self-Service Engine sends `POST /v1/contract_definitions` with JSON body containing `locale`, `name`, `schema` (XSD), `sample_data`, and `templates_attributes` (array of format+template pairs).
   - From: `continuumMerchantSelfService`
   - To: `continuumContractService`
   - Protocol: REST / HTTP

2. **Route to controller**: Nginx sidecar receives request on port 80 and proxies to Unicorn (port 8080); Rails router dispatches to `V1::ContractDefinitionsController#create`.
   - From: Nginx (in-pod)
   - To: `contractSvc_definitionsApi`
   - Protocol: HTTP (in-pod)

3. **Validate definition**: Controller instantiates a `ContractDefinition` model with the supplied attributes. ActiveRecord validations run: locale format (`^[a-zA-Z]{2}(-[a-zA-Z]{2})?$`), name format and length (4–64 chars, alphanumeric/dash/underscore), schema presence, and at least one `html` format template must be present.
   - From: `contractSvc_definitionsApi`
   - To: `contractSvc_definitionStore`
   - Protocol: In-process

4. **Validate schema coherence**: Before saving, the `DocumentRenderer` validates that `sample_data` passes the XSD schema. If validation fails, `sample_data` errors are added and the request returns `422`.
   - From: `contractSvc_definitionStore`
   - To: `contractSvc_documentRenderer`
   - Protocol: In-process

5. **Assign version**: A `before_create` callback queries the current highest version for the given `name` and assigns `version = current_version + 1` (or 1 if none exists).
   - From: `contractSvc_definitionStore`
   - To: `continuumContractMysql`
   - Protocol: MySQL

6. **Persist definition and templates**: `ContractDefinition` and associated `DefinitionTemplate` records (one per format: html, optionally pdf and txt) are saved to MySQL in a single transaction via `accepts_nested_attributes_for :templates`.
   - From: `contractSvc_definitionStore`
   - To: `continuumContractMysql`
   - Protocol: MySQL

7. **Return created definition**: Controller renders the new `ContractDefinition` as JSON with status `201 Created`, including its UUID, name, locale, version, schema, sample_data, and templates.
   - From: `contractSvc_definitionsApi`
   - To: `continuumMerchantSelfService`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Locale format invalid | ActiveRecord validation fails | `422 Unprocessable Entity` with `locale` errors |
| Name format or length invalid | ActiveRecord validation fails | `422 Unprocessable Entity` with `name` errors |
| Schema absent | ActiveRecord validation fails | `422 Unprocessable Entity` with `schema` errors |
| No HTML template provided | `definition_template_restrictions` validation fails | `422 Unprocessable Entity` with `template_attributes` errors |
| Duplicate template format (e.g., two html entries) | `definition_template_restrictions` validation fails | `422 Unprocessable Entity` |
| `sample_data` fails XSD schema validation | `schema_and_templates_are_coherent_with_data` validation fails | `422 Unprocessable Entity` with `sample_data` errors |

## Sequence Diagram

```
MerchantSelfService -> ContractDefinitionsAPI: POST /v1/contract_definitions (locale, name, schema, sample_data, templates)
ContractDefinitionsAPI -> DefinitionModels: ContractDefinition.new(params)
DefinitionModels -> DocumentRenderer: valid_data?(sample_data)
DocumentRenderer --> DefinitionModels: validation result
DefinitionModels -> MySQL: SELECT MAX(version) WHERE name = ?
MySQL --> DefinitionModels: current_version
DefinitionModels -> MySQL: INSERT contract_definitions + definition_templates
MySQL --> DefinitionModels: saved record
DefinitionModels --> ContractDefinitionsAPI: ContractDefinition object
ContractDefinitionsAPI --> MerchantSelfService: 201 Created (JSON definition)
```

## Related

- Architecture dynamic view: `dynamic-continuumContractService`
- Related flows: [Contract Creation](contract-creation.md), [Contract Rendering](contract-rendering.md)
