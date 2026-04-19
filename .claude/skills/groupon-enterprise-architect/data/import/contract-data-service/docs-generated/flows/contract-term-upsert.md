---
service: "contract-data-service"
title: "Contract Term Upsert"
generated: "2026-03-03"
type: flow
flow_name: "contract-term-upsert"
flow_type: synchronous
trigger: "API call to POST /v1/contractTerm"
participants:
  - "cds_contractTermResource"
  - "cds_contractTermReadOnlyDao"
  - "cds_paymentInvoicingConfigReadOnlyDao"
  - "cds_contractTermDao"
  - "continuumContractDataServicePostgresRo"
  - "continuumContractDataServicePostgresRw"
architecture_ref: "components-continuum-contract-data-service-components"
---

# Contract Term Upsert

## Summary

A caller submits a contract term via `POST /v1/contractTerm`. The service computes a deterministic hash of the term payload and checks whether an identical term already exists. If the term is new, it validates that the linked payment invoicing configuration exists, then persists the full term record. If an identical term exists, the existing record is returned without writing. This deduplication pattern ensures idempotent writes and avoids duplicate contract term storage.

## Trigger

- **Type**: api-call
- **Source**: Any authorized service sending `POST /v1/contractTerm` with a `ContractTermParam` JSON body
- **Frequency**: On demand (per contract term write)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Contract Term Resource | Receives request, drives hash calculation and routing logic | `cds_contractTermResource` |
| Contract Term Read-Only DAO | Checks for existing term by hash; fetches full term details by UUID | `cds_contractTermReadOnlyDao` |
| Payment Invoicing Config Read-Only DAO | Verifies the referenced payment invoicing configuration exists | `cds_paymentInvoicingConfigReadOnlyDao` |
| Contract Term DAO | Inserts new contract term and all child entities in a transaction | `cds_contractTermDao` |
| Contract Data Service DB (RO) | Read-only Postgres replica | `continuumContractDataServicePostgresRo` |
| Contract Data Service DB (RW) | Primary Postgres for writes | `continuumContractDataServicePostgresRw` |

## Steps

1. **Receive request**: Client sends `POST /v1/contractTerm` with `ContractTermParam` JSON body including `externalIds`, `paymentTerm`, `pricing`, and `source`.
   - From: caller
   - To: `cds_contractTermResource`
   - Protocol: REST/HTTP

2. **Validate CLIENT-ID header**: `cds_clientIdRequestFilter` intercepts the request and validates the `CLIENT-ID` header value against the `client_id` table on the read replica.
   - From: `cds_clientIdRequestFilter`
   - To: `cds_clientIdReadOnlyDao` → `continuumContractDataServicePostgresRo`
   - Protocol: JDBI

3. **Calculate hash**: `cds_contractTermResource` serializes the `ContractTermParam` to JSON and computes a `hashCode()` of the JSON node as the deduplication key.
   - From: `cds_contractTermResource`
   - To: in-process (Jackson ObjectMapper)
   - Protocol: direct

4. **Check for existing term by hash**: Queries the read-only replica for a contract term matching the computed hash.
   - From: `cds_contractTermResource`
   - To: `cds_contractTermReadOnlyDao` → `continuumContractDataServicePostgresRo`
   - Protocol: JDBI

5a. **Hash match — return existing**: If a term with the same hash is found, fetches the full term (external IDs, event actions, adjustments, amounts) and returns it as a `ContractTermResponse`.
   - From: `cds_contractTermReadOnlyDao`
   - To: `continuumContractDataServicePostgresRo` (multiple reads for child entities)
   - Protocol: JDBI

5b. **No match — validate PIC reference**: If no existing term, checks that the payment invoicing configuration referenced by the term's `paymentInvoicingConfigurationExternalKeyIdType` exists.
   - From: `cds_contractTermResource`
   - To: `cds_paymentInvoicingConfigReadOnlyDao` → `continuumContractDataServicePostgresRo`
   - Protocol: JDBI

6. **Insert new term**: If PIC exists, inserts the contract term and all child entities (external IDs, amounts, adjustments, event actions) transactionally.
   - From: `cds_contractTermResource`
   - To: `cds_contractTermDao` → `continuumContractDataServicePostgresRw`
   - Protocol: JDBI (transactional)

7. **Return response**: Returns `ContractTermResponse` with HTTP 200.
   - From: `cds_contractTermResource`
   - To: caller
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PIC reference not found | Throws `NoSuchElementException` | Mapped to HTTP 404 by `NoSuchElementExceptionMapper` |
| Invalid request body | Bean validation (`@Valid`, `@NotNull`) | Mapped to HTTP 400 by `IllegalArgumentExceptionMapper` |
| Database write failure | Exception propagates | Mapped to HTTP 500 by `CodsExceptionMapper` |

## Sequence Diagram

```
Caller -> ContractTermResource: POST /v1/contractTerm {contractTermParam}
ContractTermResource -> ContractTermReadOnlyDao: findContractTermByHash(hash)
ContractTermReadOnlyDao -> PostgresRO: SELECT by hash
alt hash found
  ContractTermReadOnlyDao --> ContractTermResource: existingContractTermBuilder
  ContractTermResource -> ContractTermReadOnlyDao: findContractTermUUIDByHash(hash)
  ContractTermResource -> ContractTermReadOnlyDao: findContractTermExternalId, EventAction, Adjustment, Amount
  ContractTermResource --> Caller: 200 ContractTermResponse (existing)
else hash not found
  ContractTermResource -> PaymentInvoicingConfigReadOnlyDao: findPic(externalId)
  PaymentInvoicingConfigReadOnlyDao -> PostgresRO: SELECT by externalReferenceId
  alt PIC exists
    ContractTermResource -> ContractTermDao: insertInTransaction(contractTerm)
    ContractTermDao -> PostgresRW: INSERT contract_term + children
    ContractTermResource --> Caller: 200 ContractTermResponse (new)
  else PIC not found
    ContractTermResource --> Caller: 404 NoSuchElementException
  end
end
```

## Related

- Architecture dynamic view: Not applicable (single-service internal flow)
- Related flows: [Aggregate Contract Creation](aggregate-contract-creation.md), [Payment Invoicing Configuration Upsert](payment-invoicing-config-upsert.md)
