---
service: "gcp-aiaas-cloud-functions"
title: "AI Deal Structure Generation"
generated: "2026-03-03"
type: flow
flow_name: "ai-deal-structure-generation"
flow_type: synchronous
trigger: "HTTP GET request with pds_cat_id, city, area_tier, and account_id parameters"
participants:
  - "continuumAiaasAidgFunction"
  - "continuumAiaasPostgres"
  - "openAi"
architecture_ref: "components-continuumAiaasAidgFunction"
---

# AI Deal Structure Generation

## Summary

The AIDG (AI Deal Generator) flow produces a structured deal object for a given merchant account, PDS category, city, and area tier. It first retrieves previously scraped merchant context from PostgreSQL to ground the generated content, then calls OpenAI to produce deal options, pricing, and marketing copy. This flow is the downstream consumer of the InferPDS extraction flow — it relies on merchant context having been scraped and stored in `continuumAiaasPostgres` beforehand.

## Trigger

- **Type**: api-call
- **Source**: Internal merchant advisor tooling or Salesforce integration calling the AIDG Cloud Function HTTP endpoint
- **Frequency**: On-demand (per merchant deal generation request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AIDG Cloud Function | Entry point; validates request, coordinates generation | `continuumAiaasAidgFunction` |
| Postgres Adapter | Retrieves scraped merchant text for the given account | `continuumAiaasAidgFunction_aidgPostgresAdapter` |
| Deal Generation Engine | Builds deal structure from category, city, tier, and merchant context | `continuumAiaasAidgFunction_aidgDealGenerationEngine` |
| AIaaS PostgreSQL Database | Stores previously scraped merchant page text | `continuumAiaasPostgres` |
| OpenAI | Generates deal titles, options, pricing, and descriptions via Chat Completions | `openAi` |

## Steps

1. **Receive and validate request**: The AIDG Request Handler receives a GET request and extracts query parameters `pds_cat_id`, `city`, `area_tier`, and `account_id`.
   - From: Caller (merchant advisor tooling)
   - To: `continuumAiaasAidgFunction`
   - Protocol: REST/HTTPS

2. **Validate required parameters**: Checks that all four parameters are present and non-empty. Returns `400 VALIDATION_MISSING_FIELD` if any are missing.
   - From: `continuumAiaasAidgFunction_aidgRequestHandler`
   - To: `continuumAiaasAidgFunction_aidgRequestHandler` (internal)
   - Protocol: direct

3. **Load scraped merchant context**: The Postgres Adapter queries `aidg.inferpds_scraped_data` for the most recent `page_text` row matching `account_id`, ordered by `scraped_at DESC`.
   - From: `continuumAiaasAidgFunction_aidgPostgresAdapter`
   - To: `continuumAiaasPostgres`
   - Protocol: PostgreSQL (psycopg2)

4. **Dispatch deal generation**: The Deal Generation Engine receives the PDS category ID, city, area tier, and scraped text (or empty string if none found). It constructs a prompt incorporating all inputs and sends it to OpenAI.
   - From: `continuumAiaasAidgFunction_aidgDealGenerationEngine`
   - To: `openAi`
   - Protocol: HTTPS REST (OpenAI Chat Completions API)

5. **Parse and validate deal structure**: The Deal Generation Engine parses the OpenAI response into a structured deal object. Business rule validations (e.g., PDS allowed list check) are applied. Raises `422 PDS_NOT_ALLOWED` or `422 BUSINESS_RULE_VIOLATION` if constraints are violated.
   - From: `continuumAiaasAidgFunction_aidgDealGenerationEngine`
   - To: `continuumAiaasAidgFunction_aidgRequestHandler`
   - Protocol: direct

6. **Return deal structure**: The validated deal data object is serialized as JSON and returned to the caller with HTTP 200.
   - From: `continuumAiaasAidgFunction`
   - To: Caller
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required query parameter | Return `400 VALIDATION_MISSING_FIELD` immediately | Caller receives structured error JSON array |
| PDS category not in allowed list | Raise `PDSNotAllowedError` (422) | Caller receives `422 PDS_NOT_ALLOWED` error |
| PostgreSQL unavailable | Log warning; continue with empty `scraped_text` | Deal generated without merchant-specific context |
| OpenAI API failure | Raise unhandled exception caught by outer handler | Caller receives `500 INTERNAL_ERROR` |
| Deal options generation failure | Raise `DealOptionsGenerationError` (500) | Caller receives `500 INTERNAL_ERROR` |

## Sequence Diagram

```
Caller -> AIDG_Function: GET /?pds_cat_id=X&city=Y&area_tier=Z&account_id=A
AIDG_Function -> AIDG_Function: Validate required parameters
AIDG_Function -> PostgreSQL: SELECT page_text FROM aidg.inferpds_scraped_data WHERE account_id=A
PostgreSQL --> AIDG_Function: page_text (or None)
AIDG_Function -> OpenAI: Chat completion with pds_cat_id, city, area_tier, scraped_text
OpenAI --> AIDG_Function: Generated deal structure JSON
AIDG_Function -> AIDG_Function: Parse, validate business rules
AIDG_Function --> Caller: 200 JSON deal structure
```

## Related

- Architecture dynamic view: `components-continuumAiaasAidgFunction`
- Related flows: [InferPDS Service Extraction](inferpds-service-extraction.md) (prerequisite — populates PostgreSQL with scraped merchant context)
