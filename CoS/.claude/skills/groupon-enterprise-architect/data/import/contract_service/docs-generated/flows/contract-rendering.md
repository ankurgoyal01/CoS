---
service: "contract_service"
title: "Contract Rendering"
generated: "2026-03-03"
type: flow
flow_name: "contract-rendering"
flow_type: synchronous
trigger: "GET /v1/contracts/{id} with format extension (.html, .pdf, or .txt)"
participants:
  - "continuumMerchantSelfService"
  - "continuumContractService"
  - "contractSvc_contractsApi"
  - "contractSvc_contractStore"
  - "contractSvc_definitionStore"
  - "contractSvc_documentRenderer"
  - "continuumContractMysql"
architecture_ref: "dynamic-continuumContractService"
---

# Contract Rendering

## Summary

This flow describes how a stored contract is rendered into a human-readable output format — HTML, PDF, or plain text. The caller requests a specific contract by UUID with a format extension. Contract Service loads the contract and its associated definition, retrieves the matching XSLT/XSL template, merges the contract's `user_data` with signature and metadata fields, and produces the rendered output. PDF rendering uses PDFKit (wkhtmltopdf) and falls back to the HTML template if no dedicated PDF template exists.

## Trigger

- **Type**: api-call
- **Source**: Any authorized caller (merchant self-service engine, CLO campaign service, or Deal Builder) requesting a rendered contract document
- **Frequency**: On-demand; typically during deal review or when a merchant needs to view or download their contract

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Caller (Merchant Self-Service Engine or similar) | Requests the rendered contract | `continuumMerchantSelfService` |
| Contract Service (Cicero) | Orchestrates retrieval and rendering | `continuumContractService` |
| Contracts API | Rails controller; dispatches format-specific rendering | `contractSvc_contractsApi` |
| Contract Models | Loads the contract and version records from MySQL | `contractSvc_contractStore` |
| Definition Models | Supplies the XSLT/XSL template for the requested format | `contractSvc_definitionStore` |
| Document Renderer | Applies the template to `user_data` + metadata + signature | `contractSvc_documentRenderer` |
| Contract Service MySQL | Source of contract data and template content | `continuumContractMysql` |

## Steps

1. **Send GET request with format**: Caller sends `GET /v1/contracts/{uuid}.html` (or `.pdf` or `.txt`).
   - From: `continuumMerchantSelfService`
   - To: `continuumContractService`
   - Protocol: REST / HTTP

2. **Route to controller**: Nginx proxies to Unicorn; Rails routes to `V1::ContractsController#show` with the format detected from the file extension.
   - From: Nginx (in-pod)
   - To: `contractSvc_contractsApi`
   - Protocol: HTTP (in-pod)

3. **Load contract**: Controller calls `Contract.find_by_uuid!(params[:id])` to retrieve the contract record including its current version and signature.
   - From: `contractSvc_contractsApi`
   - To: `contractSvc_contractStore`
   - Protocol: In-process

4. **Dispatch to format renderer**: The `render_contract` helper inspects the request format and calls `contract.to_html`, `contract.to_pdf`, or `contract.to_text`.
   - From: `contractSvc_contractsApi`
   - To: `contractSvc_contractStore`
   - Protocol: In-process

5. **Load template**: The contract model queries `contract_definition.templates.for(:html)` (or `:pdf`, `:txt`) to retrieve the matching `DefinitionTemplate` record from MySQL.
   - From: `contractSvc_contractStore`
   - To: `contractSvc_definitionStore`
   - Protocol: In-process (via association)

6. **Assemble template data**: The contract builds `template_data` by combining `user_data` with signature fields (`date`, `ip_address`) and metadata (`current-time`, `uuid`).
   - From: `contractSvc_contractStore`
   - To: `contractSvc_documentRenderer`
   - Protocol: In-process

7. **Render output**:
   - **HTML**: `DocumentRenderer` applies the XSLT template to `template_data` and returns an HTML string.
   - **PDF**: HTML is rendered first; PDFKit converts it to PDF (Letter size) with UUID footer and page numbers via wkhtmltopdf. If no PDF template exists, the HTML template is used.
   - **TXT**: The txt template is applied if available; otherwise HTML is rendered and Nokogiri strips script/link tags and extracts body text.
   - From: `contractSvc_documentRenderer`
   - To: Caller (via Rails response)
   - Protocol: HTTP response body

8. **Return rendered document**: Rails sends the formatted response with the appropriate `Content-Type` (`text/html`, `application/pdf`, or `text/plain`).
   - From: `contractSvc_contractsApi`
   - To: `continuumMerchantSelfService`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Contract UUID not found | `find_by_uuid!` raises `ActiveRecord::RecordNotFound` | `404 Not Found` |
| No HTML template defined for definition | `definition_template_restrictions` prevents this at creation time | Should not occur in production |
| PDF template absent | Falls back to HTML template for PDF rendering | PDF generated from HTML template |
| TXT template absent | Falls back to HTML rendering stripped by Nokogiri | Plain-text extracted from HTML |
| wkhtmltopdf binary failure | Unhandled exception from PDFKit | `500 Internal Server Error` |

## Sequence Diagram

```
Caller -> ContractsAPI: GET /v1/contracts/{uuid}.pdf
ContractsAPI -> ContractModels: Contract.find_by_uuid!(uuid)
ContractModels -> MySQL: SELECT * FROM contracts WHERE uuid = ?
MySQL --> ContractModels: contract row
ContractModels -> MySQL: SELECT * FROM contract_versions WHERE contract_id = ?
MySQL --> ContractModels: version rows
ContractModels -> MySQL: SELECT * FROM identities WHERE id = signature_id
MySQL --> ContractModels: identity/signature row
ContractModels --> ContractsAPI: Contract object
ContractsAPI -> ContractModels: contract.to_pdf
ContractModels -> DefinitionModels: templates.for(:pdf) or .for(:html)
DefinitionModels -> MySQL: SELECT * FROM definition_templates WHERE contract_definition_id = ? AND format = ?
MySQL --> DefinitionModels: DefinitionTemplate
DefinitionModels --> ContractModels: template content
ContractModels -> DocumentRenderer: render(template_data, template)
DocumentRenderer --> ContractModels: HTML string
ContractModels -> PDFKit: convert HTML to PDF (wkhtmltopdf)
PDFKit --> ContractModels: PDF binary
ContractModels --> ContractsAPI: PDF bytes
ContractsAPI --> Caller: 200 OK (application/pdf)
```

## Related

- Architecture dynamic view: `dynamic-continuumContractService`
- Related flows: [Contract Creation](contract-creation.md), [Contract Signing](contract-signing.md)
