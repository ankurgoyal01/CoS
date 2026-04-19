---
service: "users-service"
title: "Device Notification Batch Flow"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "device-notification-batch"
flow_type: batch
trigger: "Resque job enqueued after successful authentication or on schedule"
participants:
  - "continuumUsersResqueWorkers"
  - "continuumUsersDb"
  - "continuumUsersMailService"
architecture_ref: "components-continuumUsersResqueWorkers"
---

# Device Notification Batch Flow

## Summary

The device notification batch flow detects when a user authenticates from a previously unseen device and sends a security notification email to alert the account holder. This flow is handled entirely by the `continuumUsersResqueWorkers` Device Email Notification Job, which queries recent authentication events in MySQL, compares device fingerprints against known devices, and triggers notification emails via Mailman for any new device detections.

## Trigger

- **Type**: batch (Resque job)
- **Source**: Enqueued after successful authentication events or triggered on schedule by Resque Pool Runner
- **Frequency**: Per authentication event or scheduled interval

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Users Resque Workers | Executes Device Email Notification Job | `continuumUsersResqueWorkers` |
| Users DB | Source of authentication events and known device records | `continuumUsersDb` |
| Mail Delivery Service | Delivers new device notification emails | `continuumUsersMailService` |

## Steps

1. **Dequeue job**: Resque Pool Runner dequeues the Device Email Notification Job from the Redis-backed queue.
   - From: `continuumUsersResqueWorkers_resquePool`
   - To: `continuumUsersResqueWorkers_deviceEmailNotificationJob`
   - Protocol: Resque

2. **Query recent authentication events**: Device Email Notification Job reads recent authentication events from `continuumUsersDb` via Worker Repository.
   - From: `continuumUsersResqueWorkers_deviceEmailNotificationJob`
   - To: `continuumUsersDb` (via `continuumUsersResqueWorkers_repository`)
   - Protocol: MySQL / ActiveRecord

3. **Compare device fingerprints**: Job compares the device fingerprint from the authentication event against known devices for the account stored in `continuumUsersDb`.
   - From: `continuumUsersResqueWorkers_deviceEmailNotificationJob`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

4. **Identify new devices**: For each authentication event where the device fingerprint is not in the known-devices set for that account, the job marks the event as a new-device detection.
   - From: `continuumUsersResqueWorkers_deviceEmailNotificationJob`
   - To: internal logic
   - Protocol: Ruby (in-process)

5. **Send new device notification email**: For each new device detected, Worker Mailer sends a security notification email via Mailman.
   - From: `continuumUsersResqueWorkers_mailer`
   - To: `continuumUsersMailService`
   - Protocol: SMTP/Mailman

6. **Update authentication event record**: Job updates the authentication event or device record to mark the device as known, preventing duplicate notifications.
   - From: `continuumUsersResqueWorkers_deviceEmailNotificationJob`
   - To: `continuumUsersDb`
   - Protocol: MySQL / ActiveRecord

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Database query failure | Exception raised in job; Resque retries | Job retried; notification delayed |
| Email delivery failure | Mailman error; no retry in synchronous call | Notification not sent; device still marked as known |
| Duplicate job execution | Device record update is idempotent | Duplicate notification prevented |
| Account not found for event | Job skips the event | No notification sent for orphaned event |

## Sequence Diagram

```
ResquePool           -> DeviceNotificationJob  : dequeue + execute
DeviceNotificationJob -> WorkerRepository       : SELECT authentication_events WHERE unprocessed
WorkerRepository     --> DeviceNotificationJob  : auth event records
DeviceNotificationJob -> WorkerRepository       : SELECT known_devices WHERE account_id = ?
WorkerRepository     --> DeviceNotificationJob  : known device fingerprints
DeviceNotificationJob -> DeviceNotificationJob  : compare fingerprints -> new_devices list
loop [for each new device]
  DeviceNotificationJob -> WorkerMailer         : send_new_device_email(account, device_info)
  WorkerMailer          -> MailService          : SMTP deliver notification
  DeviceNotificationJob -> WorkerRepository     : UPDATE auth_event / mark device as known
end
```

## Related

- Related flows: [Authentication](authentication.md), [Forced Password Reset](forced-password-reset.md)
