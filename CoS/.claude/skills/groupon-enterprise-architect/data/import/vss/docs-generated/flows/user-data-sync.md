---
service: "vss"
title: "User Data Sync"
generated: "2026-03-03"
type: flow
flow_name: "user-data-sync"
flow_type: event-driven
trigger: "JMS events on user account update, email change, and GDPR erasure topics"
participants:
  - "mbus"
  - "continuumVssService"
  - "usersUpdatedProcessor"
  - "usersEmailUpdatedProcessor"
  - "usersDeletionProcessor"
  - "usersUpdateProcessorHelper"
  - "voucherUserDataService"
  - "voucherUsersDataDbi"
  - "continuumVssMySql"
architecture_ref: "components-vss-searchService-components"
---

# User Data Sync

## Summary

VSS maintains a local copy of user identity data (name, email) for purchasers and consumers of vouchers. This data is kept current by consuming three user-related JMS event topics: account updates, email changes, and GDPR erasures. Each event type is handled by a dedicated processor component, with update processors sharing logic through a common helper. GDPR erasures result in deletion or obfuscation of PII in VSS MySQL records.

## Trigger

- **Type**: event
- **Source**: Users Service and GDPR platform publish user lifecycle events to mbus
- **Frequency**: Continuous, event-driven; correlated with user account activity and GDPR requests

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| mbus | Delivers user JMS events to VSS subscribers | `mbus` |
| VSS Service | Hosts the JMS consumers | `continuumVssService` |
| UsersUpdatedProcessor | Handles `users.account.v1.updated` events | `usersUpdatedProcessor` |
| UsersEmailUpdatedProcessor | Handles `users.email_change.v1.completed` events | `usersEmailUpdatedProcessor` |
| UsersDeletionProcessor | Handles `gdpr.account.v1.erased` events | `usersDeletionProcessor` |
| UsersUpdateProcessorHelper | Shared logic for user update and email change processors | `usersUpdateProcessorHelper` |
| VoucherUserDataService | Applies user data changes to MySQL | `voucherUserDataService` |
| VoucherUsersDataDbi | JDBI DAO — executes update/delete SQL | `voucherUsersDataDbi` |
| VSS MySQL | Persists user data changes | `continuumVssMySql` |

## Steps — User Account Updated

1. **Receives user account update event**: mbus delivers message on topic `jms.topic.users.account.v1.updated_vss_user.vss_user`.
   - From: `mbus`
   - To: `usersUpdatedProcessor`
   - Protocol: JMS

2. **Delegates to update helper**: `usersUpdatedProcessor` passes the parsed user account data to `usersUpdateProcessorHelper`.
   - From: `usersUpdatedProcessor`
   - To: `usersUpdateProcessorHelper`
   - Protocol: direct

3. **Updates voucher user data**: `usersUpdateProcessorHelper` calls `voucherUserDataService` to update the purchaser and consumer name/email fields for all voucher records associated with the user's account ID. Tracks `purchaserUpdateCount` and `recipientUpdateCount` metrics.
   - From: `usersUpdateProcessorHelper`
   - To: `voucherUserDataService` → `voucherUsersDataDbi` → `continuumVssMySql`
   - Protocol: JDBI / MySQL

## Steps — User Email Changed

1. **Receives email change event**: mbus delivers message on topic `jms.topic.users.email_change.v1.completed_vss_user.vss_user`.
   - From: `mbus`
   - To: `usersEmailUpdatedProcessor`
   - Protocol: JMS

2. **Delegates to update helper**: `usersEmailUpdatedProcessor` passes the new email data to `usersUpdateProcessorHelper`.
   - From: `usersEmailUpdatedProcessor`
   - To: `usersUpdateProcessorHelper`
   - Protocol: direct

3. **Updates email fields**: `usersUpdateProcessorHelper` calls `voucherUserDataService` to update email fields in affected voucher-user records.
   - From: `usersUpdateProcessorHelper`
   - To: `voucherUserDataService` → `voucherUsersDataDbi` → `continuumVssMySql`
   - Protocol: JDBI / MySQL

## Steps — GDPR User Erasure

1. **Receives GDPR erasure event**: mbus delivers message on topic `jms.topic.gdpr.account.v1.erased_vss_user_deletion_dev.vss_user_deletion_dev`.
   - From: `mbus`
   - To: `usersDeletionProcessor`
   - Protocol: JMS

2. **Processes erasure**: `usersDeletionProcessor` extracts the list of account IDs to erase and calls `voucherUserDataService` to delete or obfuscate PII (first name, last name, masked email) for all voucher records associated with those IDs.
   - From: `usersDeletionProcessor`
   - To: `voucherUserDataService` → `voucherUsersDataDbi` → `continuumVssMySql`
   - Protocol: JDBI / MySQL

3. **Acknowledges event**: On success, the JMS message is acknowledged.
   - From: `usersDeletionProcessor`
   - To: `mbus`
   - Protocol: JMS acknowledgement

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL write failure during user update | Exception thrown; message not acknowledged → redelivery | `userUpdateErrorCount` metric incremented; alert at WARN (5) / SEVERE (10) |
| Processor hard failure | `jmsUserFailCount` metric incremented | Alert at WARN (1) / SEVERE (100) |
| User ID not found in VSS MySQL | Update applies to zero rows; logged as no-op | No error; metric may reflect zero update counts |
| mbus delivery failure | Consumer subscription managed by platform | New events queued until connection restored |

## Sequence Diagram

```
mbus -> UsersUpdatedProcessor: JMS (users.account.v1.updated, accountId, name, email)
UsersUpdatedProcessor -> UsersUpdateProcessorHelper: processUserUpdate(accountId, userData)
UsersUpdateProcessorHelper -> VoucherUserDataService: updateUserData(accountId, name, email)
VoucherUserDataService -> VoucherUsersDataDbi: UPDATE voucher_users SET ... WHERE accountId=X
VoucherUsersDataDbi -> VSSMySQL: SQL UPDATE
VSSMySQL --> VoucherUsersDataDbi: rows affected
VoucherUsersDataDbi --> VoucherUserDataService: success
VoucherUserDataService --> UsersUpdateProcessorHelper: success
UsersUpdateProcessorHelper --> UsersUpdatedProcessor: success
UsersUpdatedProcessor -> mbus: ACK
```

## Related

- Architecture dynamic view: `components-vss-searchService-components`
- Related flows: [GDPR User Obfuscation](gdpr-user-obfuscation.md), [Inventory Unit Ingestion](inventory-unit-ingestion.md)
- Events documentation: [Events](../events.md)
