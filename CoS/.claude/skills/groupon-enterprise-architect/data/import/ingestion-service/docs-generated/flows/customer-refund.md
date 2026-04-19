---
service: "ingestion-service"
title: "Customer Refund Request"
generated: "2026-03-03"
type: flow
flow_name: "customer-refund"
flow_type: synchronous
trigger: "POST /odis/api/v1/refund from GSO agent tooling"
participants:
  - "continuumIngestionService"
  - "extCaapApi_85f2db0d"
  - "continuumIngestionServiceMysql"
architecture_ref: "dynamic-ticketEscalationFlow"
---

# Customer Refund Request

## Summary

This flow processes a customer order refund request submitted by a Customer Support agent (or automated tool) through the ingestion-service REST API. The service validates the caller's identity, accepts refund context (inventory unit ID, refund reason, destination), and delegates the actual refund execution to the CAAP API. The response reports the refund status for each inventory unit, including any failures.

## Trigger

- **Type**: API call
- **Source**: GSO agent tooling or internal Customer Support automation
- **Frequency**: On demand — each customer refund request
- **Endpoint**: `POST /odis/api/v1/refund`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GSO caller (agent tooling) | Initiates the refund request with order and reason context | External caller |
| Ingestion Service | Authenticates caller; delegates to CAAP; returns result | `continuumIngestionService` |
| CAAP API | Executes the order refund against Groupon's order/payment systems | `extCaapApi_85f2db0d` |
| Ingestion Service MySQL | Validates caller credentials | `continuumIngestionServiceMysql` |

## Steps

1. **Receives refund request**: The caller posts to `POST /odis/api/v1/refund` with form parameters including `domain`, `blockIfRedeemed` flag, and refund context (inventory unit ID, refund reason, destination — `bucks` or `original`).
   - From: GSO agent tooling
   - To: `continuumIngestionService` (`ingestionService_apiResources`)
   - Protocol: HTTPS/REST (form-encoded)

2. **Authenticates caller**: The auth filter validates the `X-API-KEY` header and `client_id` query parameter against the MySQL credential store.
   - From: `ingestionService_apiResources`
   - To: `authAndJwt` → `continuumIngestionServiceMysql`
   - Protocol: JDBI/MySQL

3. **Validates domain**: Checks that the `domain` parameter matches an entry in the `availableDomains` list from service configuration.
   - From: `coreServices`
   - To: (in-memory configuration)
   - Protocol: In-process

4. **Checks blockIfRedeemed (conditional)**: If `blockIfRedeemed=true`, the service optionally checks the voucher redemption status before proceeding with the refund.

5. **Submits refund request to CAAP API**: Sends a `RefundOrdersRequestBody` to the CAAP API containing inventory unit IDs, refund reason, and destination.
   - From: `continuumIngestionService` (`ingestionService_integrationClients`)
   - To: `extCaapApi_85f2db0d`
   - Protocol: HTTPS/REST

6. **Returns refund result**: CAAP returns a response containing `refundStatus`, `refundDestination`, `succeededInventoryUnitIds`, `failedInventoryUnitIds`, `reversalId`, and `extraCreditStatus`. The ingestion-service maps this into a `RefundOrdersResponseEntity` and returns it.
   - From: `continuumIngestionService`
   - To: GSO caller
   - Protocol: HTTPS/REST (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or missing API credentials | Auth filter rejection | `401 Unauthorized` returned |
| Invalid or missing domain | Validation rejection | `400 Bad Request` with "Invalid/Missing Domain Id" |
| CAAP API refund failure (partial) | `failedInventoryUnitIds` populated in `RefundOrdersResponseEntity` | `200` returned with mixed success/failure details |
| CAAP API completely unavailable | HTTP error propagated | `500` or appropriate HTTP error returned to caller |

## Sequence Diagram

```
Caller -> IngestionService: POST /odis/api/v1/refund (domain, blockIfRedeemed, inventory_unit_id, reason, destination)
IngestionService -> MySQL: Validate client_id credentials
MySQL --> IngestionService: Valid
IngestionService -> IngestionService: Validate domain
IngestionService -> CAAP API: RefundOrdersRequestBody (inventory_unit_ids, reason, destination)
CAAP API --> IngestionService: RefundOrdersResponseBody (status, succeeded/failed IDs, reversalId)
IngestionService --> Caller: RefundOrdersResponseEntity (200 with refund status details)
```

## Related

- Related flows: [Merchant-Approved Refund Processing](merchant-approved-refund.md)
- See also: [API Surface](../api-surface.md) — `POST /odis/api/v1/refund`
- See also: [Integrations](../integrations.md) — CAAP API
