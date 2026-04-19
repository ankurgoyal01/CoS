---
service: "sub_center"
title: "SMS Unsubscribe"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "sms-unsubscribe"
flow_type: synchronous
trigger: "User submits the SMS unsubscribe form on the subscription center"
participants:
  - "continuumSubCenterWebApp"
  - "subscriptionsService_ext_9a41"
  - "twilioSms_ext_3a95"
architecture_ref: "dynamic-subCenter-smsUnsubscribe"
---

# SMS Unsubscribe

## Summary

The SMS unsubscribe flow handles a user's request to stop receiving Groupon SMS messages, specifically for the weekly digest SMS channel. The service updates subscription state in the Subscriptions Service and then uses the Twilio SDK (via the SMS Helper component) to send a confirmation SMS back to the user's phone number. The flow renders a confirmation page upon completion.

## Trigger

- **Type**: user-action
- **Source**: User submitting the SMS unsubscribe form, typically accessed via a link in a Groupon SMS message or from the subscription center page
- **Frequency**: On-demand, per user action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Subscription Center Web App | Orchestrates SMS opt-out and confirmation dispatch | `continuumSubCenterWebApp` |
| Subscriptions Service | Records the SMS unsubscribe action | `subscriptionsService_ext_9a41` |
| Twilio SMS | Delivers the SMS confirmation message to the user's phone | `twilioSms_ext_3a95` |

## Steps

1. **Receives SMS unsubscribe form submission**: Browser sends POST request with phone number and unsubscribe parameters.
   - From: End User (browser)
   - To: `httpRouter` in `continuumSubCenterWebApp`
   - Protocol: HTTP POST

2. **Routes to controller**: HTTP Router dispatches to the Controller Layer's SMS unsubscribe action.
   - From: `httpRouter`
   - To: `subCenter_controllerLayer`
   - Protocol: Internal

3. **Invokes SMS unsubscribe handler**: Controller invokes Subscription Handlers with the phone number and channel parameters.
   - From: `subCenter_controllerLayer`
   - To: `subscriptionHandlers`
   - Protocol: Internal

4. **Updates subscription state**: Subscription Handlers use External API Clients to POST the SMS unsubscribe to the Subscriptions Service.
   - From: `subscriptionHandlers` via `subCenter_externalApiClients`
   - To: `subscriptionsService_ext_9a41`
   - Protocol: HTTP/REST (stub only)

5. **Sends SMS confirmation**: Subscription Handlers invoke the SMS Helper, which uses the Twilio SDK to dispatch a confirmation SMS to the user's phone.
   - From: `subscriptionHandlers`
   - To: `smsHelper`
   - Protocol: Internal

6. **Dispatches via Twilio**: SMS Helper sends the confirmation message via Twilio API.
   - From: `smsHelper`
   - To: `twilioSms_ext_3a95`
   - Protocol: Twilio SDK / HTTP (stub only)

7. **Builds confirmation view model**: Subscription Presenters assemble the confirmation page data.
   - From: `subscriptionHandlers`
   - To: `presenters`
   - Protocol: Internal

8. **Renders confirmation page**: Page Renderer produces the HTML confirmation and returns it to the browser.
   - From: `subscriptionHandlers`
   - To: `pageRenderer` → end user browser
   - Protocol: HTTP response (HTML)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Subscriptions Service unavailable | HTTP error from External API Clients | Render error page; SMS opt-out not recorded |
| Twilio SDK error (e.g., invalid phone, account issue) | Log error from SMS Helper | Subscription state is updated but confirmation SMS is not sent; render page with notice |
| Invalid phone number format | Validate on receipt | Render form error; no downstream calls made |

## Sequence Diagram

```
User Browser -> continuumSubCenterWebApp (httpRouter): POST /subscription-center/sms-unsubscribe
httpRouter -> subCenter_controllerLayer: route to sms-unsubscribe action
subCenter_controllerLayer -> subscriptionHandlers: invoke SMS unsubscribe handler
subscriptionHandlers -> subCenter_externalApiClients: POST SMS opt-out
subCenter_externalApiClients -> subscriptionsService_ext_9a41: POST /subscriptions/sms/unsubscribe
subscriptionsService_ext_9a41 --> subCenter_externalApiClients: 200 OK
subscriptionHandlers -> smsHelper: send confirmation SMS
smsHelper -> twilioSms_ext_3a95: Twilio SDK sendMessage(phone, confirmationText)
twilioSms_ext_3a95 --> smsHelper: message SID / success
subscriptionHandlers -> presenters: build confirmation view model
subscriptionHandlers -> pageRenderer: render confirmation HTML
pageRenderer --> User Browser: 200 OK (confirmation page)
```

## Related

- Architecture dynamic view: `dynamic-subCenter-smsUnsubscribe` (not yet defined)
- Related flows: [Email Unsubscribe](email-unsubscribe.md), [Channel Management](channel-management.md)
