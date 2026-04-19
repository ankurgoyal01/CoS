---
service: "contract-data-service"
title: "Contract Party Upsert"
generated: "2026-03-03"
type: flow
flow_name: "contract-party-upsert"
flow_type: synchronous
trigger: "API call to PUT /v1/contractParty"
participants:
  - "cds_contractPartyResource"
  - "cds_contractPartyReadOnlyDao"
  - "cds_contractPartyDao"
  - "continuumContractDataServicePostgresRo"
  - "continuumContractDataServicePostgresRw"
architecture_ref: "components-continuum-contract-data-service-components"
---

# Contract Party Upsert

## Summary

A caller submits a contract party record via `PUT /v1/contractParty`. The service checks whether a party with the given `contractPartyId` already exists in the read-only replica. If it does not exist, a new record is inserted. If it already exists, the record is updated with the new values. This upsert pattern ensures a single party record per merchant contract identifier without requiring the caller to know the prior state.

## Trigger

- **Type**: api-call
- **Source**: Any authorized service sending `PUT /v1/contractParty` with a `ContractPartyParam` JSON body
- **Frequency**: On demand (per party record write)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Contract Party Resource | Receives request, coordinates lookup and write | `cds_contractPartyResource` |
| Contract Party Read-Only DAO | Checks whether party already exists by contract party ID | `cds_contractPartyReadOnlyDao` |
| Contract Party DAO | Inserts new or updates existing contract party record | `cds_contractPartyDao` |
| Contract Data Service DB (RO) | Read-only Postgres replica | `continuumContractDataServicePostgresRo` |
| Contract Data Service DB (RW) | Primary Postgres for writes | `continuumContractDataServicePostgresRw` |

## Steps

1. **Receive request**: Client sends `PUT /v1/contractParty` with a `ContractPartyParam` JSON body containing `id`, `idType`, and optional payment schedule configuration.
   - From: caller
   - To: `cds_contractPartyResource`
   - Protocol: REST/HTTP

2. **Validate CLIENT-ID header**: `cds_clientIdRequestFilter` validates the `CLIENT-ID` header.
   - From: `cds_clientIdRequestFilter`
   - To: `cds_clientIdReadOnlyDao` → `continuumContractDataServicePostgresRo`
   - Protocol: JDBI

3. **Build domain object**: Converts `ContractPartyParam` to a `ContractParty` domain object.
   - From: `cds_contractPartyResource`
   - To: in-process
   - Protocol: direct

4. **Look up existing party**: Checks whether a contract party with the same `contractPartyId` exists on the read replica.
   - From: `cds_contractPartyResource`
   - To: `cds_contractPartyReadOnlyDao` → `continuumContractDataServicePostgresRo`
   - Protocol: JDBI

5a. **Not found — insert**: If no existing record, inserts the new contract party.
   - From: `cds_contractPartyResource`
   - To: `cds_contractPartyDao` (`insertContractParty`) → `continuumContractDataServicePostgresRw`
   - Protocol: JDBI

5b. **Found — update**: If record exists, updates the party with the new field values.
   - From: `cds_contractPartyResource`
   - To: `cds_contractPartyDao` (`updateContractParty`) → `continuumContractDataServicePostgresRw`
   - Protocol: JDBI

6. **Return response**: Returns `ContractPartyResponse` with HTTP 200.
   - From: `cds_contractPartyResource`
   - To: caller
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid request body | Bean validation (`@Valid`, `@NotNull`) | HTTP 400 via `IllegalArgumentExceptionMapper` |
| Database write failure | Exception propagates | HTTP 500 via `CodsExceptionMapper` |

## Sequence Diagram

```
Caller -> ContractPartyResource: PUT /v1/contractParty {contractPartyParam}
ContractPartyResource -> ContractPartyReadOnlyDao: findContractParty(contractPartyId)
ContractPartyReadOnlyDao -> PostgresRO: SELECT by contractPartyId
alt not found
  ContractPartyResource -> ContractPartyDao: insertContractParty(contractNew)
  ContractPartyDao -> PostgresRW: INSERT contract_party
else found
  ContractPartyResource -> ContractPartyDao: updateContractParty(contractNew)
  ContractPartyDao -> PostgresRW: UPDATE contract_party
end
ContractPartyResource --> Caller: 200 ContractPartyResponse
```

## Related

- Related flows: [Aggregate Contract Creation](aggregate-contract-creation.md)
- API reference: [API Surface](../api-surface.md)
