---
service: "clo-service"
title: "Claim Processing and Statement Credit"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "claim-processing-statement-credit"
flow_type: event-driven
trigger: "Card network transaction callback to POST /clo/api/v1/visa or /clo/api/v1/mastercard"
participants:
  - "continuumCloServiceApi"
  - "continuumCloServiceWorker"
  - "cloApiControllers"
  - "cloApiClaimDomain"
  - "cloApiEventPublisher"
  - "cloWorkerMessageConsumers"
  - "cloWorkerAsyncJobs"
  - "continuumCloServicePostgres"
  - "continuumCloServiceRedis"
  - "messageBus"
  - "continuumOrdersService"
architecture_ref: "dynamic-clo-claim-processing"
---

# Claim Processing and Statement Credit

## Summary

This flow describes how a qualifying card purchase triggers a CLO claim and ultimately results in a statement credit to the consumer. The card network delivers a transaction callback to CLO Service, which matches the transaction to an enrolled offer, creates a claim record, and enqueues async follow-up work. The worker then processes the billing confirmation and issues the statement credit back through the card network. This is the core financial flow of the service and is SOX in-scope.

## Trigger

- **Type**: api-call (inbound webhook from card network)
- **Source**: Visa (`POST /clo/api/v1/visa`) or Mastercard (`POST /clo/api/v1/mastercard`) transaction notification
- **Frequency**: Per qualifying consumer purchase transaction

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO Service API | Receives card network callback; creates claim | `continuumCloServiceApi` |
| API Controllers | Routes card network callback to claim domain | `cloApiControllers` |
| Claim Domain Services | Matches transaction to enrollment; orchestrates claim creation | `cloApiClaimDomain` |
| Event Publisher | Publishes claim event to Message Bus | `cloApiEventPublisher` |
| CLO Service Worker | Processes async follow-up; triggers statement credit | `continuumCloServiceWorker` |
| Message Consumers | Consumes BillingRecordUpdate event to confirm billing | `cloWorkerMessageConsumers` |
| Async Job Processors | Processes statement credit job | `cloWorkerAsyncJobs` |
| CLO Service PostgreSQL | Persists claim state throughout lifecycle | `continuumCloServicePostgres` |
| CLO Service Redis | Job queue for async processing steps | `continuumCloServiceRedis` |
| Message Bus | Carries claim events and billing record updates | `messageBus` |
| Orders Service | Provides billing record confirmation | `continuumOrdersService` |

## Steps

1. **Receives transaction callback**: `cloApiControllers` receives a signed `POST /clo/api/v1/visa` or `/clo/api/v1/mastercard` request containing transaction details (card token, merchant, amount, timestamp).
   - From: Card network (Visa or Mastercard)
   - To: `cloApiControllers`
   - Protocol: REST

2. **Validates callback authenticity**: `cloApiControllers` verifies the network-specific request signature or credentials before processing.
   - From: `cloApiControllers`
   - To: (internal validation)
   - Protocol: Direct

3. **Matches transaction to enrollment**: `cloApiClaimDomain` queries `continuumCloServicePostgres` to find an active enrollment matching the card token and offer associated with the merchant.
   - From: `cloApiClaimDomain`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

4. **Creates claim record**: `cloApiClaimDomain` persists a new claim record in `continuumCloServicePostgres` with status `pending` using AASM state machine.
   - From: `cloApiClaimDomain`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

5. **Publishes claim event**: `cloApiEventPublisher` publishes a `clo.claims` event to Message Bus with claim details.
   - From: `cloApiEventPublisher`
   - To: `messageBus`
   - Protocol: Message Bus

6. **Enqueues async follow-up job**: `continuumCloServiceApi` enqueues a statement credit processing job via Redis/Sidekiq.
   - From: `continuumCloServiceApi`
   - To: `continuumCloServiceWorker` (via `continuumCloServiceRedis`)
   - Protocol: Sidekiq / Redis

7. **Returns acknowledgement to card network**: `cloApiControllers` returns HTTP 200 to the card network to acknowledge receipt.
   - From: `cloApiControllers`
   - To: Card network
   - Protocol: REST

8. **Consumes billing record update**: When Orders Service confirms the billing record, `cloWorkerMessageConsumers` receives a `BillingRecordUpdate` event from Message Bus.
   - From: `messageBus`
   - To: `cloWorkerMessageConsumers`
   - Protocol: Message Bus

9. **Processes statement credit**: `cloWorkerAsyncJobs` reads the claim from `continuumCloServicePostgres`, transitions it to `approved`, and calls the card network API to issue the statement credit.
   - From: `cloWorkerAsyncJobs`
   - To: `continuumCloServicePostgres`, card network API
   - Protocol: ActiveRecord / SQL, REST

10. **Updates claim to credited**: `cloWorkerAsyncJobs` writes the final claim state (`credited`) to `continuumCloServicePostgres` and publishes a final `clo.claims` status update.
    - From: `cloWorkerAsyncJobs`
    - To: `continuumCloServicePostgres`, `messageBus`
    - Protocol: ActiveRecord / SQL, Message Bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No matching enrollment found | Log and discard transaction | No claim created; callback acknowledged |
| Duplicate transaction callback | Idempotency check in database | Existing claim returned; no duplicate created |
| Database write failure on claim creation | Transaction rollback | Claim not persisted; card network should retry |
| BillingRecordUpdate not received | Claim remains in pending state; Sidekiq job retries | Statement credit delayed; alert on prolonged pending |
| Card network statement credit API failure | Sidekiq retry with backoff | Statement credit retried; dead job queue on exhaustion |
| AASM invalid state transition | Exception raised; Sidekiq retry | Claim state protected from invalid transitions |

## Sequence Diagram

```
CardNetwork -> cloApiControllers: POST /clo/api/v1/visa (transaction callback)
cloApiControllers -> cloApiClaimDomain: match transaction to enrollment
cloApiClaimDomain -> continuumCloServicePostgres: lookup enrollment by card token + merchant
continuumCloServicePostgres --> cloApiClaimDomain: enrollment found
cloApiClaimDomain -> continuumCloServicePostgres: persist claim (status: pending)
cloApiEventPublisher -> messageBus: publish clo.claims event
continuumCloServiceApi -> continuumCloServiceRedis: enqueue statement credit job
cloApiControllers --> CardNetwork: 200 OK
messageBus -> cloWorkerMessageConsumers: BillingRecordUpdate event
cloWorkerMessageConsumers -> cloWorkerAsyncJobs: dispatch statement credit processing
cloWorkerAsyncJobs -> continuumCloServicePostgres: read claim; transition to approved
cloWorkerAsyncJobs -> CardNetworkAPI: issue statement credit
CardNetworkAPI --> cloWorkerAsyncJobs: credit confirmed
cloWorkerAsyncJobs -> continuumCloServicePostgres: update claim (status: credited)
cloWorkerAsyncJobs -> messageBus: publish clo.claims (credited)
```

## Related

- Architecture dynamic view: `dynamic-clo-claim-processing`
- Related flows: [Card Enrollment and CLO Activation](card-enrollment-clo-activation.md), [Card Network File Transfer and Settlement](card-network-file-transfer-settlement.md)
