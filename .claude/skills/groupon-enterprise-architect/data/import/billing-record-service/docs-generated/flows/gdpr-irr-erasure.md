---
service: "billing-record-service"
title: "GDPR Individual Rights Request Erasure"
generated: "2026-03-03"
type: flow
flow_name: "gdpr-irr-erasure"
flow_type: event-driven
trigger: "IndividualRightsRequestPayload message consumed from Groupon Message Bus"
participants:
  - "messageBus"
  - "brs_integrationAdapters"
  - "brs_coreService"
  - "brs_persistence"
  - "brs_cacheAdapter"
  - "continuumBillingRecordPostgres"
  - "continuumBillingRecordRedis"
  - "paymentGateways"
architecture_ref: "dynamic-billing-record-create"
---

# GDPR Individual Rights Request Erasure

## Summary

When a Groupon user exercises their right to be forgotten under GDPR, the Regulatory Consent Log Service publishes an `IndividualRightsRequestPayload` message to the Groupon Message Bus. Billing Record Service consumes this event via the `IndividualRightsRequestHandlerScheduler`, scrubs all personally identifiable information (PII) from the purchaser's billing records, marks all records with status `IRR_FORGOTTEN`, conditionally deletes PCI tokens, and publishes an IRR completion event back to the Message Bus. This flow implements the requirements of GDPR and Groupon's Bast compliance framework.

## Trigger

- **Type**: event
- **Source**: Regulatory Consent Log Service (`https://services.groupondev.com/services/regulatory-consent-log`) publishing to the Groupon Message Bus (mbus qualifier: `erasure`)
- **Frequency**: On-demand (per GDPR erasure request; relatively infrequent)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon Message Bus | Delivers the IRR erasure event and receives the completion acknowledgement | `messageBus` |
| External Integration Adapters | Polls the mbus consumer (qualifier: `erasure`); publishes completion event | `brs_integrationAdapters` |
| Billing Record Service Layer | Orchestrates PII scrubbing, status update, and token deletion check | `brs_coreService` |
| Persistence Layer | Reads all billing records for the purchaser; writes scrubbed records back | `brs_persistence` |
| Cache Adapter | Evicts stale cache entries for the purchaser after erasure | `brs_cacheAdapter` |
| PostgreSQL | Source and destination for billing record erasure | `continuumBillingRecordPostgres` |
| Redis | Cache evicted after erasure | `continuumBillingRecordRedis` |
| PCI-API | Deletes payment tokens that are no longer shared with other purchasers | `paymentGateways` |

## Steps

1. **Poll erasure queue**: `IndividualRightsRequestHandlerScheduler` polls the mbus consumer (qualifier: `erasure`) using `receiveImmediate()`.
   - From: `brs_integrationAdapters`
   - To: `messageBus`
   - Protocol: STOMP/JMS (mbus)

2. **Deserialize IRR payload**: The scheduler deserializes the JSON message into an `IndividualRightsRequestPayload` containing `accountId` (UUID), `erasedAt`, and `publishedAt`.
   - From: `messageBus`
   - To: `brs_integrationAdapters`
   - Protocol: JSON (mbus message payload)

3. **Load all billing records**: Service Layer reads all billing records for the purchaser (`accountId`) from PostgreSQL.
   - From: `brs_coreService`
   - To: `brs_persistence`
   - Protocol: in-process (JDBC to `continuumBillingRecordPostgres`)

4. **Scrub PII fields**: For each billing record, the Service Layer replaces all PII fields with a GDPR replacement string. Scrubbed fields include: `BillingAddress.addressLine1/2`, `title`, `street`, `streetNumber`, `phoneNumber`, `personalIdNumber`, `additionalInfo`, `taxIdNumber`, `companyName`, `firstName`, `lastName`; and `PaymentData.name`, `bin`, `cryptogram`, `eci`.
   - From: `brs_coreService`
   - To: `brs_persistence`
   - Protocol: in-process (JDBC write)

5. **Set status to IRR_FORGOTTEN**: All billing records for the purchaser are transitioned to `IRR_FORGOTTEN` status.
   - From: `brs_coreService`
   - To: `brs_persistence`
   - Protocol: in-process

6. **Check and delete PCI tokens**: For each token associated with the purchaser's billing records, the Service Layer checks (`isTokenRequired()`) whether the token is shared with any other active purchaser. If the token is unique to this purchaser, it calls PCI-API to delete it.
   - From: `brs_coreService`
   - To: `brs_integrationAdapters`
   - Protocol: in-process (adapter calls PCI-API via HTTPS)

7. **Evict Redis cache**: Cache Adapter evicts all cache entries for the purchaser.
   - From: `brs_coreService`
   - To: `brs_cacheAdapter`
   - Protocol: in-process (Redis protocol)

8. **Publish IRR completion event**: After successful erasure, the scheduler publishes a completion message to the mbus erasure completion topic. Payload: `{"accountId": "<uuid>", "erasedAt": "<iso8601>", "publishedAt": "<iso8601>", "serviceId": "billing-record-service"}`.
   - From: `brs_integrationAdapters`
   - To: `messageBus`
   - Protocol: STOMP/JMS (mbus)

9. **Acknowledge message**: The original IRR message is acknowledged (`ackSafe`) on the mbus consumer to prevent redelivery.
   - From: `brs_integrationAdapters`
   - To: `messageBus`
   - Protocol: STOMP/JMS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deserialization failure | Exception logged; message not acknowledged | Message redelivered by mbus |
| PostgreSQL write failure | Transaction rolled back; message not acknowledged | Message redelivered; retry on next poll cycle |
| PCI-API token deletion failure | Error logged; Hystrix may open circuit; erasure DB writes still committed | Token deletion deferred; IRR status applied regardless |
| Completion event publish failure | Error logged; mbus redelivery of original may cause re-processing | Re-processing is guarded by `IRR_FORGOTTEN` status check |

## Sequence Diagram

```
mbus -> brs_integrationAdapters: IndividualRightsRequestPayload {accountId, erasedAt, publishedAt}
brs_integrationAdapters -> brs_coreService: handle(message)
brs_coreService -> brs_persistence: findAllBillingRecordsByPurchaser(accountId)
brs_persistence --> brs_coreService: List<BillingRecord>
brs_coreService -> brs_persistence: scrubbedPII + status=IRR_FORGOTTEN for each record
brs_persistence --> brs_coreService: updated records
brs_coreService -> brs_persistence: isTokenRequired(tokenId)?
brs_persistence --> brs_coreService: false
brs_coreService -> brs_integrationAdapters: call PCI-API to delete token
brs_integrationAdapters --> brs_coreService: token deleted
brs_coreService -> brs_cacheAdapter: evict purchaser cache
brs_cacheAdapter --> brs_coreService: evicted
brs_integrationAdapters -> mbus: publish completion event {accountId, erasedAt, publishedAt, serviceId}
brs_integrationAdapters -> mbus: ackSafe(messageId)
```

## Related

- Architecture dynamic view: `dynamic-billing-record-create`
- Related flows: [Deactivate Billing Record](deactivate-billing-record.md)
- GDPR reference: `README.md` — GDPR and Individual Right to be Forgotten Requests section; GPP-1144, GPP-1255
