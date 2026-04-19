---
service: "deal-management-api"
title: "Contract Party Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "contract-party-management"
flow_type: synchronous
trigger: "HTTP POST/PUT/DELETE /v2/contract_data_service/contract_parties"
participants:
  - "continuumDealManagementApi"
  - "continuumDealManagementMysql"
  - "continuumContractDataService"
architecture_ref: "dynamic-contractPartyManagement"
---

# Contract Party Management

## Summary

The contract party management flow handles creation, update, and removal of contract parties associated with deals. DMAPI acts as a gateway: it validates the request, persists contract party metadata locally in MySQL, and propagates the change to the upstream Contract Data Service which holds the authoritative contract records. This flow covers both the `/v2/contract_data_service/contracts` read path and the `/v2/contract_data_service/contract_parties` write path.

## Trigger

- **Type**: api-call
- **Source**: Deal setup tooling managing legal/contract party assignments on deals
- **Frequency**: On demand (per contract party operation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Management API | Orchestrates contract party CRUD | `continuumDealManagementApi` |
| Deal Management MySQL | Stores local contract party records | `continuumDealManagementMysql` |
| Contract Data Service | Authoritative contract and party store | `continuumContractDataService` |

## Steps

1. **Receive contract party request**: API Controllers accept POST, PUT, or DELETE on `/v2/contract_data_service/contract_parties` (or GET on `/v2/contract_data_service/contracts`).
   - From: Calling client
   - To: `continuumDealManagementApi` (`apiControllers`)
   - Protocol: REST/HTTPS

2. **Validate request payload**: Validators check party type, required identifiers, and association constraints.
   - From: `apiControllers`
   - To: `validationLayer` (internal)
   - Protocol: in-process

3. **Fetch contract context (reads)**: For GET requests, Repositories query MySQL for local contract records, then Remote Clients fetch authoritative data from Contract Data Service if needed.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: `continuumContractDataService`
   - Protocol: REST/HTTPS

4. **Persist contract party record locally**: Repositories write the contract party record to MySQL.
   - From: `continuumDealManagementApi` (`repositories`)
   - To: `continuumDealManagementMysql`
   - Protocol: SQL

5. **Propagate to Contract Data Service**: Remote Clients call Contract Data Service to create, update, or delete the contract party in the authoritative store.
   - From: `continuumDealManagementApi` (`remoteClients`)
   - To: `continuumContractDataService`
   - Protocol: REST/HTTPS

6. **Return result**: API Controllers return HTTP 200/201/204 to the caller.
   - From: `continuumDealManagementApi`
   - To: Calling client
   - Protocol: REST/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure | Return HTTP 422 | Contract party not created/updated |
| Contract not found | Return HTTP 404 | Operation not performed |
| MySQL write failure | Return HTTP 500; transaction rolled back | Local record not persisted |
| Contract Data Service unavailable | Return HTTP 503 | Operation rolled back if local write was transactional; sync may be out of step |
| Contract Data Service returns error | Return HTTP 500 with upstream error context | Caller receives error; local state may diverge |

## Sequence Diagram

```
Client -> continuumDealManagementApi: POST /v2/contract_data_service/contract_parties {party data}
continuumDealManagementApi -> validationLayer: validate(payload)
validationLayer --> continuumDealManagementApi: valid
continuumDealManagementApi -> continuumDealManagementMysql: INSERT contract_party
continuumDealManagementMysql --> continuumDealManagementApi: party_id
continuumDealManagementApi -> continuumContractDataService: POST contract party
continuumContractDataService --> continuumDealManagementApi: 201 Created
continuumDealManagementApi --> Client: 201 Created {contract_party}
```

## Related

- Architecture dynamic view: `dynamic-contractPartyManagement`
- Related flows: [Deal Create (Sync)](deal-create-sync.md), [Deal Publish Workflow](deal-publish-workflow.md)
