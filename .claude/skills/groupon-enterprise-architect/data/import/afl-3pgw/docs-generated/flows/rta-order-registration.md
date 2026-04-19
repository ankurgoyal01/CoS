---
service: "afl-3pgw"
title: "Real-Time Order Registration"
generated: "2026-03-03"
type: flow
flow_name: "rta-order-registration"
flow_type: event-driven
trigger: "MBUS message published to jms.topic.afl_rta.attribution.orders by afl-rta"
participants:
  - "messageBus"
  - "continuumAfl3pgwService"
  - "continuumOrdersService"
  - "continuumMarketingDealService"
  - "continuumIncentiveService"
  - "cjAffiliate"
  - "awinAffiliate"
  - "continuumAfl3pgwDatabase"
architecture_ref: "dynamic-rta-order-registration-flow"
---

# Real-Time Order Registration

## Summary

When a Groupon customer purchase is attributed to an affiliate network by the upstream `afl-rta` service, an order attribution event is published onto the MBUS topic `jms.topic.afl_rta.attribution.orders`. AFL-3PGW consumes this event, enriches the payload by calling the Orders Service, Marketing Deal Service, and Incentive Service, and then submits the transaction to the appropriate affiliate network (Commission Junction or Awin) in real time. The submission result and audit data are persisted to the service's MySQL database.

## Trigger

- **Type**: event (async message)
- **Source**: `messageBus` topic `jms.topic.afl_rta.attribution.orders` (published by `afl-rta`)
- **Frequency**: Per-order — triggered for every order attribution event that arrives on the topic; volume tracks Groupon's affiliate-attributed purchase rate

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MBUS Message Bus | Source of attributed order events | `messageBus` |
| AFL 3PGW Service | Orchestrator — consumes, enriches, submits, persists | `continuumAfl3pgwService` |
| Orders Service | Provides order line-item details and payment data | `continuumOrdersService` |
| Marketing Deal Service (MDS) | Provides deal taxonomy and category metadata | `continuumMarketingDealService` |
| Incentive Service | Provides discount and gBucks incentive data | `continuumIncentiveService` |
| Commission Junction | Receives CJ affiliate sale registration | `cjAffiliate` |
| Awin | Receives Awin affiliate transaction event | `awinAffiliate` |
| AFL 3PGW MySQL | Stores submission state and audit record | `continuumAfl3pgwDatabase` |

## Steps

1. **Receive attribution event**: The MBUS consumer (`OrdersMessageHandler`, component `orderIngestionComponent`) receives an order attribution event from topic `jms.topic.afl_rta.attribution.orders`.
   - From: `messageBus`
   - To: `continuumAfl3pgwService` (`orderIngestionComponent`)
   - Protocol: JMS/MBUS

2. **Parse and route event**: `OrdersMessageHandler` passes the parsed event to `OrderMessageProcessor` (`orderRegistrationComponent`) for enrichment coordination.
   - From: `orderIngestionComponent`
   - To: `orderRegistrationComponent`
   - Protocol: direct (in-process)

3. **Fetch order details**: `orderRegistrationComponent` calls the Orders Service to retrieve line-item details, quantities, prices, and payment transaction data.
   - From: `continuumAfl3pgwService`
   - To: `continuumOrdersService`
   - Protocol: REST/HTTP (Retrofit `orderServiceClient`)

4. **Resolve deal taxonomy**: `orderRegistrationComponent` calls MDS to fetch the `topCategory` and deal taxonomy hierarchy required by CJ and Awin payloads.
   - From: `continuumAfl3pgwService`
   - To: `continuumMarketingDealService`
   - Protocol: REST/HTTP (Retrofit `mdsClient`)

5. **Resolve incentive adjustments**: `orderRegistrationComponent` calls the Incentive Service to retrieve discount amounts, gBucks, and lifestage values used to compute the net commission amount.
   - From: `continuumAfl3pgwService`
   - To: `continuumIncentiveService`
   - Protocol: REST/HTTP (Retrofit `incentiveServiceClient`)

6. **Build and submit affiliate payload**: `affiliateNetworkGatewayComponent` determines the target network based on the attribution data, builds the network-specific payload, and submits it:
   - For CJ: calls `CJHttpClient.registerSale()` via GET `/u` with query parameters (CID, TYPE, OID, AMT1, ITEM1, CURRENCY, discount, coupon, cjEvent, signature, etc.)
   - For Awin: calls `AwinConversionClient` with the Awin transaction payload
   - From: `continuumAfl3pgwService` (`affiliateNetworkGatewayComponent`)
   - To: `cjAffiliate` or `awinAffiliate`
   - Protocol: REST/HTTP (Retrofit `cjClient` or `awinConversionClient`)

7. **Persist audit record**: After submission, `persistenceComponent` writes an audit record to `continuumAfl3pgwDatabase` (e.g., `audit_cj_submitted_orders` table) capturing the order ID, CJ event token, submission timestamp, and response status.
   - From: `continuumAfl3pgwService` (`persistenceComponent`)
   - To: `continuumAfl3pgwDatabase`
   - Protocol: JDBC/MySQL

8. **Acknowledge message**: On successful processing and persistence, the MBUS message is acknowledged and removed from the topic.
   - From: `continuumAfl3pgwService`
   - To: `messageBus`
   - Protocol: JMS/MBUS ACK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `topCategory` from MDS | Event is NOT acknowledged; message expires from topic per MBUS retention | Deal not submitted to affiliate; alert fires if many events fail; contact MDS team |
| CJ submission HTTP error | Failsafe retry with configured retry policy | Retried up to the retry limit; if still failing, submission failure is logged and the event is eventually expired; `CjSubmitNewOrdersJob` may recover it in reconciliation |
| Awin submission HTTP error | Failsafe retry with configured retry policy | Similar to CJ; correction jobs may recover missed submissions |
| Orders Service unavailable | Exception thrown; event not acknowledged | Message expires from topic; no affiliate submission; no audit record written |
| Event missing required attribution fields | Exception in `OrderMessageProcessor`; event not acknowledged | Message expires from topic; `3PGW Exceptions Alert` may fire |

## Sequence Diagram

```
messageBus          -> afl-3pgw:                  Order attribution event (jms.topic.afl_rta.attribution.orders)
afl-3pgw            -> continuumOrdersService:    GET order details (order ID, line items, payment)
continuumOrdersService --> afl-3pgw:              Order payload response
afl-3pgw            -> continuumMarketingDealService: GET deal taxonomy / topCategory
continuumMarketingDealService --> afl-3pgw:       Deal taxonomy response
afl-3pgw            -> continuumIncentiveService: GET incentive and discount data
continuumIncentiveService --> afl-3pgw:           Incentive response
afl-3pgw            -> cjAffiliate:               GET /u (CJ S2S sale registration)  [if CJ-attributed]
cjAffiliate         --> afl-3pgw:                 HTTP 200 / success response
afl-3pgw            -> awinAffiliate:             POST transaction event              [if Awin-attributed]
awinAffiliate       --> afl-3pgw:                 HTTP 200 / success response
afl-3pgw            -> continuumAfl3pgwDatabase:  INSERT audit record
messageBus          <-- afl-3pgw:                 JMS ACK
```

## Related

- Architecture dynamic view: `dynamic-rta-order-registration-flow`
- Related flows: [CJ Reconciliation and Correction Submission](cj-reconciliation-correction.md), [Awin Transaction Processing](awin-transaction-processing.md)
