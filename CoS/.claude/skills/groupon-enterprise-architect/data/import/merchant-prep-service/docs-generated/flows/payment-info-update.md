---
service: "merchant-prep-service"
title: "Payment Information Update"
generated: "2026-03-03"
type: flow
flow_name: "payment-info-update"
flow_type: synchronous
trigger: "Merchant submits new banking or payment information"
participants:
  - "continuumMerchantPrepService"
  - "continuumMerchantPrepPrimaryDb"
  - "salesForce"
  - "continuumAccountingService"
  - "messageBus"
architecture_ref: "components-merchant-prep-service"
---

# Payment Information Update

## Summary

The payment information update flow handles the most regulated part of the merchant self-prep workflow — collecting and validating merchant banking details (routing number, account number, IBAN, payable name, etc.). The service receives the submission, applies payment hold validation rules (`PaymentHoldConstants`), writes updated fields to Salesforce, persists change state to the primary database, checks accounting hold status, and publishes a merchant setting update event to the message bus. Multiple API versions exist (v1, v2, v3) reflecting evolving validation requirements.

## Trigger

- **Type**: user-action
- **Source**: Merchant Center front-end sends a PUT request to the payment info endpoint via UMAPI
- **Frequency**: On-demand, per merchant payment submission

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center / UMAPI | Initiates payment info submission on behalf of merchant | — |
| Merchant Prep API | Routes request to domain service | `continuumMerchantPrepService` / `mps_merchantPrepApi` |
| Onboarding Domain Services | Applies payment hold validation and orchestrates updates | `continuumMerchantPrepService` / `mps_onboardingDomain` |
| Persistence Layer (Primary DB) | Persists payment change state and audit entry | `continuumMerchantPrepPrimaryDb` / `mps_persistenceLayer` |
| Salesforce | System-of-record for payment hold fields and banking data | `salesForce` |
| Accounting Service | Provides payment hold status information | `continuumAccountingService` |
| Message Bus (MBUS) | Receives merchant setting update event | `messageBus` |

## Steps

1. **Receives payment info submission**: Merchant Center sends `PUT /merchant-self-prep/v1/accounts/{salesforceId}/paymentInfo` (or v2 equivalent) with banking payload.
   - From: `Merchant Center / UMAPI`
   - To: `continuumMerchantPrepService` (`mps_merchantPrepApi`)
   - Protocol: REST (HTTP/JSON)

2. **Validates payment hold rules**: The domain service applies `PaymentHoldConstants.getPaymentStatusAndAddReasonCodes()` — checking TIN validity for US merchants, payment hold risk flags, IBAN checksum, routing number format, and billing address completeness.
   - From: `mps_onboardingDomain`
   - To: in-process validation logic
   - Protocol: direct

3. **Queries accounting hold status**: The integration client calls the Accounting Service to retrieve current payment hold status for the account.
   - From: `mps_onboardingDomain` via `mps_integrationClients`
   - To: `continuumAccountingService`
   - Protocol: REST (HTTP/JSON)

4. **Updates Salesforce banking fields**: The integration client writes the validated payment information fields to the Salesforce account record.
   - From: `mps_onboardingDomain` via `mps_integrationClients`
   - To: `salesForce`
   - Protocol: REST (HTTP/JSON with OAuth2)

5. **Persists change payment state**: The `ChangePaymentDao` records the in-progress or completed payment change in the primary database.
   - From: `mps_onboardingDomain` via `mps_persistenceLayer`
   - To: `continuumMerchantPrepPrimaryDb`
   - Protocol: JDBC

6. **Appends audit entry**: The `AuditEntryService` writes an audit record for the payment field change.
   - From: `mps_onboardingDomain` via `mps_persistenceLayer`
   - To: `continuumMerchantPrepPrimaryDb`
   - Protocol: JDBC

7. **Publishes merchant setting update event**: The domain service publishes an event to the MBUS topic indicating the merchant's payment settings changed.
   - From: `mps_onboardingDomain` (via `jtier-messagebus-client`)
   - To: `messageBus`
   - Protocol: JMS topic

8. **Returns response**: Updated payment info or payment hold status code list returned to the caller.
   - From: `continuumMerchantPrepService`
   - To: `Merchant Center / UMAPI`
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| IBAN checksum fails | `PaymentHoldStatusCodes.BANK_IBAN_VALIDATION_FAILED` (code 104) returned | HTTP response includes reason code; no SF update |
| Routing number invalid | `PaymentHoldStatusCodes.BANK_ROUTING_NUMBER_INVALID` (code 105) returned | Reason code included in response |
| Accounting Service unavailable | RxJava 3 error propagation | HTTP 5xx returned; payment info not updated |
| Salesforce write failure | RxJava 3 error propagation | HTTP 5xx returned; state rolled back |
| MBUS publish failure | Logged; does not block response | Payment update persisted but downstream consumers may miss event |

## Sequence Diagram

```
MerchantCenter -> MerchantPrepAPI: PUT /merchant-self-prep/v1/accounts/{sfId}/paymentInfo
MerchantPrepAPI -> OnboardingDomain: validatePaymentHoldRules(paymentInfo)
OnboardingDomain -> AccountingService: GET payment hold status
AccountingService --> OnboardingDomain: holdStatus
OnboardingDomain -> Salesforce: PATCH banking fields
Salesforce --> OnboardingDomain: 200 OK
OnboardingDomain -> PrimaryDB: upsert ChangePayment record
OnboardingDomain -> PrimaryDB: insert audit entry
OnboardingDomain -> MessageBus: publish merchant-setting-update event
OnboardingDomain --> MerchantPrepAPI: success (with reason codes if hold)
MerchantPrepAPI --> MerchantCenter: 200 OK
```

## Related

- Architecture dynamic view: `components-merchant-prep-service`
- Related flows: [Merchant Self-Prep Step Completion](merchant-self-prep-step-completion.md)
