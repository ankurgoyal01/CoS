---
service: "calcom"
title: "Booking Request and Confirmation Flow"
generated: "2026-03-03"
type: flow
flow_name: "booking-confirmation"
flow_type: synchronous
trigger: "User selects a time slot and submits booking details via the Booking UI"
participants:
  - "calcom_bookingUi"
  - "calcom_schedulingApi"
  - "calcom_authSessionManager"
  - "calcom_notificationOrchestrator"
  - "continuumCalcomPostgres"
  - "gmailSmtpService"
architecture_ref: "dynamic-calcom-booking-confirmation"
---

# Booking Request and Confirmation Flow

## Summary

This flow describes the end-to-end process of a user booking a meeting through the Cal.com Booking UI. The user selects a time slot from the public scheduling page, submits their attendee details, and the service validates the request, persists the booking, and dispatches a confirmation notification. The flow is modeled as a Structurizr dynamic view (`dynamic-calcom-booking-confirmation`) within `continuumCalcomService`.

## Trigger

- **Type**: user-action
- **Source**: `calcomClientBrowser` — end user submits a booking form at `https://meet.groupon.com/:username/:eventType`
- **Frequency**: on-demand (per booking request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Booking UI | Renders the scheduling page; collects selected time slot and attendee details; submits booking request | `calcom_bookingUi` |
| Scheduling API | Receives the booking submission; validates availability; persists the booking record; triggers notifications | `calcom_schedulingApi` |
| Auth and Session Manager | Validates the user session and access permissions for the booking request | `calcom_authSessionManager` |
| Notification Orchestrator | Orchestrates the dispatch of confirmation email/notification after successful booking | `calcom_notificationOrchestrator` |
| Cal.com PostgreSQL | Stores the persisted booking record | `continuumCalcomPostgres` |
| Gmail SMTP | Delivers the booking confirmation email to attendees and organizer | `gmailSmtpService` |

## Steps

1. **Renders booking page**: The Booking UI renders the scheduling page for a specific host and event type, displaying available time slots.
   - From: `calcomClientBrowser`
   - To: `calcom_bookingUi`
   - Protocol: HTTPS

2. **Submits selected time and attendee details**: The user selects a time slot and enters attendee information; the Booking UI submits the booking request to the Scheduling API.
   - From: `calcom_bookingUi`
   - To: `calcom_schedulingApi`
   - Protocol: Internal (Next.js API route)

3. **Validates user/session permissions**: The Scheduling API asks the Auth and Session Manager to validate the session identity and access controls for the booking request.
   - From: `calcom_schedulingApi`
   - To: `calcom_authSessionManager`
   - Protocol: Internal

4. **Persists booking record**: The Scheduling API writes the new booking record (time, attendees, event type) to the PostgreSQL database.
   - From: `calcom_schedulingApi`
   - To: `continuumCalcomPostgres`
   - Protocol: PostgreSQL

5. **Triggers confirmation workflow**: The Scheduling API notifies the Notification Orchestrator to dispatch booking confirmation communications.
   - From: `calcom_schedulingApi`
   - To: `calcom_notificationOrchestrator`
   - Protocol: Internal

6. **Dispatches confirmation email**: The Notification Orchestrator sends the booking confirmation email to the attendee(s) and organizer via Gmail SMTP.
   - From: `calcom_notificationOrchestrator`
   - To: `gmailSmtpService`
   - Protocol: SMTP/TLS (smtp.gmail.com:465)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session validation failure | Auth and Session Manager rejects the request | Booking is not persisted; user receives authentication error |
| Time slot no longer available (conflict) | Scheduling API detects conflict against PostgreSQL | Booking is rejected; user is prompted to select another slot |
| Database write failure | PostgreSQL error propagates to Scheduling API | Booking is not confirmed; user receives error response |
| SMTP delivery failure | Email delivery error from Gmail SMTP | Booking is persisted in database; confirmation email not delivered; no automatic retry at Groupon layer |

## Sequence Diagram

```
calcomClientBrowser -> calcom_bookingUi: Browse available time slots (HTTPS GET)
calcomClientBrowser -> calcom_bookingUi: Submit selected time and attendee details
calcom_bookingUi -> calcom_schedulingApi: Submit scheduling request
calcom_schedulingApi -> calcom_authSessionManager: Validate user/session permissions
calcom_authSessionManager --> calcom_schedulingApi: Session valid
calcom_schedulingApi -> continuumCalcomPostgres: Write booking record (PostgreSQL)
continuumCalcomPostgres --> calcom_schedulingApi: Booking persisted
calcom_schedulingApi -> calcom_notificationOrchestrator: Trigger confirmation workflow
calcom_notificationOrchestrator -> gmailSmtpService: Send confirmation email (SMTP/TLS)
gmailSmtpService --> calcom_notificationOrchestrator: Email delivered
calcom_schedulingApi --> calcom_bookingUi: Booking confirmed response
calcom_bookingUi --> calcomClientBrowser: Display booking confirmation page
```

## Related

- Architecture dynamic view: `dynamic-calcom-booking-confirmation`
- Related flows: [Reminder Dispatch Flow](reminder-dispatch.md)
