---
service: "mobile-flutter-merchant"
title: "Inbox and Notifications Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "inbox-and-notifications-management"
flow_type: event-driven
trigger: "FCM push notification received by device, or merchant opens the inbox screen"
participants:
  - "continuumMobileFlutterMerchantApp"
  - "mmaMerchantEngagementModule"
  - "mmaPresentationLayer"
  - "mmaApiOrchestrator"
  - "notsService"
  - "salesForce"
architecture_ref: "dynamic-inbox-and-notifications-management"
---

# Inbox and Notifications Management

## Summary

The Inbox and Notifications Management flow covers two related paths: push notification delivery via Firebase Cloud Messaging (FCM), and merchant inbox message browsing powered by Salesforce and the NOTS Service. When a push notification arrives, the `mmaMerchantEngagementModule` handles the FCM message, displays a local notification via `flutter_local_notifications`, and optionally deep-links into the app. When the merchant opens the inbox, `mmaApiOrchestrator` fetches messages and onboarding todos, which `mmaMerchantEngagementModule` renders through `mmaPresentationLayer`.

## Trigger

- **Type**: event (push notification path) or user-action (inbox path)
- **Source**: FCM push payload dispatched by `notsService` or Salesforce backend; or merchant taps the Inbox navigation item
- **Frequency**: Event-driven for push notifications; on-demand for inbox screen open

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Engagement Module | Handles FCM messages, renders inbox and notification UX flows | `mmaMerchantEngagementModule` |
| Presentation Layer | Navigates to inbox/notification screens and deep-link targets | `mmaPresentationLayer` |
| API Orchestrator | Fetches inbox messages and onboarding todos from backend services | `mmaApiOrchestrator` |
| NOTS Service | Provides onboarding todo items and processes dismiss actions | `notsService` |
| Salesforce | Provides inbox messages and support communication threads | `salesForce` |

## Steps

### Path A: Push Notification Received

1. **FCM Message Arrives**: Firebase Cloud Messaging delivers a push notification payload to the device while the app is in foreground, background, or terminated state.
   - From: Firebase Cloud Messaging (dispatched by `notsService` or Salesforce backend)
   - To: `mmaMerchantEngagementModule` (via `firebase_messaging` handler)
   - Protocol: FCM (push)

2. **Handle Notification Payload**: `mmaMerchantEngagementModule` processes the FCM message, extracts notification title, body, and deep-link routing data.
   - From: `firebase_messaging` callback
   - To: `mmaMerchantEngagementModule`
   - Protocol: Direct

3. **Display Local Notification**: `mmaMerchantEngagementModule` uses `flutter_local_notifications` to render the notification in the device notification tray.
   - From: `mmaMerchantEngagementModule`
   - To: Device notification tray (OS)
   - Protocol: Direct

4. **Merchant Taps Notification**: Merchant taps the notification; the app foregrounds and `mmaPresentationLayer` deep-links to the relevant screen (inbox, deal, or advisor).
   - From: Merchant (user tap)
   - To: `mmaPresentationLayer`
   - Protocol: Direct

### Path B: Merchant Opens Inbox

5. **Navigate to Inbox**: Merchant taps the Inbox icon; `mmaPresentationLayer` delegates to `mmaMerchantEngagementModule` to load inbox content.
   - From: Merchant (user action)
   - To: `mmaPresentationLayer` → `mmaMerchantEngagementModule`
   - Protocol: Direct

6. **Fetch Onboarding Todos**: `mmaApiOrchestrator` calls `notsService` to retrieve the merchant's onboarding todo list.
   - From: `mmaApiOrchestrator`
   - To: `notsService`
   - Protocol: REST/HTTP

7. **Fetch Inbox Messages**: `mmaApiOrchestrator` calls the Salesforce integration to retrieve merchant inbox messages and support threads.
   - From: `mmaApiOrchestrator`
   - To: `salesForce`
   - Protocol: SDK/REST

8. **Render Inbox**: `mmaMerchantEngagementModule` passes combined content to `mmaPresentationLayer`, which renders the inbox list with todos, messages, and badges.
   - From: `mmaMerchantEngagementModule`
   - To: `mmaPresentationLayer`
   - Protocol: Direct

9. **Dismiss Todo**: Merchant taps to dismiss an onboarding todo; `mmaApiOrchestrator` sends a dismiss action to `notsService`.
   - From: `mmaApiOrchestrator`
   - To: `notsService`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| FCM delivery failure | FCM at-most-once delivery; no retry at app level | Notification not shown; merchant is unaware |
| NOTS Service unavailable | HTTP error in `mmaApiOrchestrator` | Onboarding todos section shows error/empty state |
| Salesforce unavailable | SDK/REST error | Inbox messages section shows error state; support chat unavailable |
| Notification permission denied | OS-level permission check at app start | Push notifications not shown; in-app inbox still accessible |

## Sequence Diagram

```
// Path A: Push Notification
notsService -> FCM: Dispatch push notification
FCM -> mmaMerchantEngagementModule: Deliver FCM message (background/foreground handler)
mmaMerchantEngagementModule -> flutter_local_notifications: Show system notification
Merchant -> mmaPresentationLayer: Taps notification
mmaPresentationLayer -> mmaPresentationLayer: Deep-link to target screen

// Path B: Inbox
Merchant -> mmaPresentationLayer: Opens Inbox
mmaPresentationLayer -> mmaMerchantEngagementModule: loadInbox()
mmaMerchantEngagementModule -> mmaApiOrchestrator: fetchTodos()
mmaApiOrchestrator -> notsService: GET /merchant/todos
notsService --> mmaApiOrchestrator: Todo list
mmaMerchantEngagementModule -> mmaApiOrchestrator: fetchMessages()
mmaApiOrchestrator -> salesForce: GET inbox messages
salesForce --> mmaApiOrchestrator: Message list
mmaMerchantEngagementModule --> mmaPresentationLayer: Combined inbox content
mmaPresentationLayer -> Merchant: Render inbox
Merchant -> mmaPresentationLayer: Dismisses todo
mmaPresentationLayer -> mmaApiOrchestrator: dismissTodo(todoId)
mmaApiOrchestrator -> notsService: POST /merchant/todos/{id}/dismiss
notsService --> mmaApiOrchestrator: Dismissed
```

## Related

- Architecture dynamic view: `dynamic-inbox-and-notifications-management`
- Related flows: [Merchant Login Flow](merchant-login-flow.md), [Offline and Sync Workflow](offline-and-sync-workflow.md)
