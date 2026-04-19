---
service: "orders-rails3"
title: "Account Redaction (GDPR)"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "account-redaction-gdpr"
flow_type: asynchronous
trigger: "POST /orders/v1/account/redaction from compliance or user-deletion pipeline"
participants:
  - "continuumOrdersService"
  - "continuumOrdersWorkers"
  - "continuumOrdersDaemons"
  - "continuumUsersService"
  - "continuumOrdersDb"
  - "continuumFraudDb"
  - "continuumOrdersMsgDb"
  - "continuumRedis"
  - "messageBus"
architecture_ref: "dynamic-continuum-orders-redaction"
---

# Account Redaction (GDPR)

## Summary

The account redaction flow anonymizes all personally identifiable information (PII) associated with a Groupon user account across order records, billing records, and inventory units. It is triggered by a compliance or user-deletion pipeline via the Account Redaction API and executed asynchronously by the Account Redaction Workers. The flow covers PCI deactivation of billing records, PII scrubbing from order data, and retry handling for partially failed redaction jobs. This flow is SOX and GDPR-relevant.

## Trigger

- **Type**: api-call
- **Source**: Internal compliance pipeline or GDPR user deletion service calling `POST /orders/v1/account/redaction`; retries via `continuumOrdersDaemons_retrySchedulers` (account_redaction_retry)
- **Frequency**: On-demand (per user deletion request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Account Redaction API | Receives redaction request; validates user; enqueues redaction job | `continuumOrdersApi_accountRedactionApi` |
| External Service Clients | Fetches user account data for validation | `continuumOrdersApi_serviceClientsGateway` |
| Account Redaction Workers | Executes PII anonymization across all order-related records | `continuumOrdersWorkers_accountRedactionWorkers` |
| Users Service | Provides current account state for validation | `continuumUsersService` |
| Orders DB | Source of all order PII; anonymized in place | `continuumOrdersDb` |
| Fraud DB | Contains fraud review records with user PII; anonymized | `continuumFraudDb` |
| Orders Messaging DB | Outbox records referencing user PII; anonymized | `continuumOrdersMsgDb` |
| Redis Cache/Queue | Hosts Resque queues for redaction jobs | `continuumRedis` |
| Retry Schedulers | Re-enqueues failed or stalled redaction jobs | `continuumOrdersDaemons_retrySchedulers` |

## Steps

1. **Receives redaction request**: Compliance pipeline submits `POST /orders/v1/account/redaction` with user identifier.
   - From: `compliance pipeline`
   - To: `continuumOrdersApi_accountRedactionApi`
   - Protocol: REST

2. **Validates user account**: Fetches current account details from Users Service to confirm the redaction target.
   - From: `continuumOrdersApi_serviceClientsGateway`
   - To: `continuumUsersService`
   - Protocol: REST

3. **Enqueues redaction job**: Places `account_redaction_worker` job onto Resque queue.
   - From: `continuumOrdersApi_accountRedactionApi`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque enqueue)

4. **Returns accepted response**: API responds with job ID and status accepted.
   - From: `continuumOrdersApi_accountRedactionApi`
   - To: `compliance pipeline`
   - Protocol: REST (HTTP 202)

5. **Dequeues redaction job**: Account Redaction Workers pull the job from Resque.
   - From: `continuumOrdersWorkers_accountRedactionWorkers`
   - To: `continuumRedis`
   - Protocol: Redis client (Resque)

6. **Anonymizes order records**: Workers scrub PII fields (name, address, email, phone) from all order and line item records in Orders DB for the target user.
   - From: `continuumOrdersWorkers_accountRedactionWorkers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

7. **Deactivates billing records (PCI)**: `pci_billing_record_deactivation_worker` marks all billing records for the user as deactivated, removing stored payment method data.
   - From: `continuumOrdersWorkers_accountRedactionWorkers`
   - To: `continuumOrdersDb`
   - Protocol: ActiveRecord

8. **Publishes BillingRecordUpdate event**: Notifies downstream systems of billing record deactivation.
   - From: `continuumOrdersApi_messageBusPublishers`
   - To: `messageBus`
   - Protocol: Message Bus

9. **Anonymizes fraud records**: Scrubs user PII from Fraud DB records associated with the user's orders.
   - From: `continuumOrdersWorkers_accountRedactionWorkers`
   - To: `continuumFraudDb`
   - Protocol: ActiveRecord

10. **Anonymizes message outbox records**: Scrubs any user PII from `continuumOrdersMsgDb` outbox records referencing the user.
    - From: `continuumOrdersWorkers_accountRedactionWorkers`
    - To: `continuumOrdersMsgDb`
    - Protocol: ActiveRecord

11. **Processes account updater batch** (if applicable): `account_updater_batch_worker` handles bulk account update scenarios (e.g., payment network account updates that triggered redaction).
    - From: `continuumOrdersWorkers_accountRedactionWorkers`
    - To: `continuumOrdersDb`
    - Protocol: ActiveRecord

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Users Service unavailable at validation | Request rejected with HTTP 503 | Client retries the redaction request |
| Partial redaction failure (one DB fails) | Worker records partial completion; job enters retry queue | `continuumOrdersDaemons_retrySchedulers` re-triggers via `account_redaction_retry` |
| Duplicate redaction request (same user) | Worker detects already-redacted records; skips idempotently | No duplicate anonymization; logs idempotency event |
| Redaction job stalled | `continuumOrdersDaemons_retrySchedulers` triggers `account_redaction_retry` after timeout | Stalled job re-enqueued; compliance SLA monitoring required |

## Sequence Diagram

```
compliancePipeline -> continuumOrdersApi_accountRedactionApi: POST /orders/v1/account/redaction
continuumOrdersApi_accountRedactionApi -> continuumUsersService: GET user account validation
continuumUsersService --> continuumOrdersApi_accountRedactionApi: user confirmed
continuumOrdersApi_accountRedactionApi -> continuumRedis: ENQUEUE account_redaction_worker job
continuumOrdersApi_accountRedactionApi --> compliancePipeline: HTTP 202 accepted
continuumOrdersWorkers_accountRedactionWorkers -> continuumRedis: DEQUEUE account_redaction_worker job
continuumOrdersWorkers_accountRedactionWorkers -> continuumOrdersDb: UPDATE orders SET pii_fields = anonymized WHERE user_id = X
continuumOrdersWorkers_accountRedactionWorkers -> continuumOrdersDb: UPDATE billing_records SET status = deactivated WHERE user_id = X
continuumOrdersWorkers_accountRedactionWorkers -> messageBus: PUBLISH BillingRecordUpdate
continuumOrdersWorkers_accountRedactionWorkers -> continuumFraudDb: UPDATE fraud_reviews SET pii_fields = anonymized WHERE user_id = X
continuumOrdersWorkers_accountRedactionWorkers -> continuumOrdersMsgDb: UPDATE order_messages SET pii_fields = anonymized WHERE user_id = X
```

## Related

- Architecture dynamic view: `dynamic-continuum-orders-redaction`
- Related flows: [Daemon Retry and Maintenance](daemon-retry-maintenance.md)
