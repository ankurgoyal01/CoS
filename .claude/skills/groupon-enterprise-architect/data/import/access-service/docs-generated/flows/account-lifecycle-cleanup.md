---
service: "mx-merchant-access"
title: "Account Lifecycle Cleanup"
generated: "2026-03-03"
type: flow
flow_name: "account-lifecycle-cleanup"
flow_type: event-driven
trigger: "MBus event on account_deactivated, account_erased, or account_merged topic"
participants:
  - "messageBus"
  - "accessSvc_mbusConsumers"
  - "accessSvc_domainServices"
  - "accessSvc_persistence"
  - "continuumAccessPostgres"
architecture_ref: "components-continuumAccessService"
---

# Account Lifecycle Cleanup

## Summary

When a user account is deactivated, erased, or merged (lose side) in the Groupon users-service, MAS receives a corresponding MBus event and removes all merchant contact and primary contact associations for the affected account. This keeps the MAS access graph consistent with the canonical account lifecycle state. All three event types share the same cleanup logic via the `AbstractAccountDeletedMessageHandler` base class.

## Trigger

- **Type**: event
- **Source**: Groupon users-service publishes to MBus topics (`account_deactivated`, `account_erased`, `account_merged`)
- **Frequency**: On-demand (triggered by account lifecycle changes in the users-service)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Users-service (publisher) | Emits account lifecycle events to MBus | External to this service |
| MBus | Routes events to subscribed consumers | `messageBus` |
| MBus Consumers | Receives and dispatches events to the appropriate handler | `accessSvc_mbusConsumers` |
| Domain Services | Fetches all contacts for the account and issues delete/deactivate operations | `accessSvc_domainServices` |
| Persistence Layer | Reads contacts and writes deactivation + audit records | `accessSvc_persistence` |
| PostgreSQL | Stores all updated records | `continuumAccessPostgres` |

## Steps

1. **Publish lifecycle event**: Users-service publishes an event to the appropriate MBus topic. The payload contains the account UUID (as `accountId` or `mergeLoserAccountId`) and a timestamp.
   - From: `users-service`
   - To: `messageBus`
   - Protocol: MBus publish

2. **Deliver event to consumer**: MBus delivers the message to the durable subscriber registered by MAS for the respective topic.
   - From: `messageBus`
   - To: `accessSvc_mbusConsumers`
   - Protocol: MBus consume

3. **Parse message payload**: The handler (`AccountDeactivatedMessageHandler`, `AccountErasedMessageHandler`, or `AccountMergedMessageHandler`) deserializes the JSON payload using GSON to extract the target account UUID. If parsing fails, the message is ACK'd without processing to avoid redelivery.
   - From: `accessSvc_mbusConsumers`
   - To: `accessSvc_mbusConsumers` (internal)
   - Protocol: Direct

4. **Fetch all contacts for account**: Domain contact service retrieves all active `merchant_contact` records for the deleted/deactivated account UUID.
   - From: `accessSvc_mbusConsumers` (via `accessSvc_domainServices`)
   - To: `accessSvc_persistence`
   - Protocol: Direct (Spring bean)

5. **Remove primary contact if applicable**: For each contact found, the handler checks whether this account is the primary contact for that merchant. If so, the primary contact designation is removed (deactivated).
   - From: `accessSvc_domainServices`
   - To: `accessSvc_persistence`
   - Protocol: Direct

6. **Delete each merchant contact**: For each `merchant_contact` record found, the domain service deactivates the contact and its associated `merchant_access` records, and writes an `audit` row.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

7. **ACK the message**: After processing all contacts (or if the account UUID could not be parsed), the handler returns `MessageHandlingResult.ACK` to confirm receipt.
   - From: `accessSvc_mbusConsumers`
   - To: `messageBus`
   - Protocol: MBus ACK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Payload parsing failure | Logs warning, ACKs message immediately | No contacts deleted; message not redelivered |
| No contacts found for account | No-op; ACKs message | Clean outcome; no writes |
| Exception during contact deletion | Caught and logged via ops log; message is still ACK'd | Partial cleanup possible; alert via operations log failure |
| MBus connectivity loss | Consumer fails to start or reconnect; health check reflects status | Events not processed until connectivity is restored |

## Sequence Diagram

```
UsersService -> messageBus: publish account_deactivated/erased/merged (accountId, timestamp)
messageBus -> accessSvc_mbusConsumers: deliver message
accessSvc_mbusConsumers -> accessSvc_mbusConsumers: deserialize JSON payload, extract accountUuid
accessSvc_mbusConsumers -> accessSvc_domainServices: getContactsByAccountUuid(accountUuid)
accessSvc_domainServices -> accessSvc_persistence: findContactsByAccountUuid(accountUuid)
accessSvc_persistence -> continuumAccessPostgres: SELECT merchant_contact WHERE account_uuid=accountUuid AND active=true
continuumAccessPostgres --> accessSvc_persistence: list of contacts
loop for each contact
  accessSvc_domainServices -> accessSvc_persistence: getPrimaryContact(contact.merchantUuid)
  accessSvc_persistence -> continuumAccessPostgres: SELECT primary_contact WHERE merchant_uuid AND active=true
  continuumAccessPostgres --> accessSvc_persistence: primaryContact
  accessSvc_domainServices -> accessSvc_persistence: removePrimaryContact(merchantUuid) [if account is primary]
  accessSvc_persistence -> continuumAccessPostgres: UPDATE primary_contact SET active=false; INSERT audit
  accessSvc_domainServices -> accessSvc_persistence: deleteContact(accountUuid, merchantUuid, auditData)
  accessSvc_persistence -> continuumAccessPostgres: UPDATE merchant_contact SET active=false; UPDATE merchant_access; INSERT audit
end
accessSvc_mbusConsumers -> messageBus: ACK
```

## Related

- Architecture dynamic view: `components-continuumAccessService`
- Related flows: [Delete Merchant Contact](delete-merchant-contact.md), [Set Primary Contact](set-primary-contact.md)
