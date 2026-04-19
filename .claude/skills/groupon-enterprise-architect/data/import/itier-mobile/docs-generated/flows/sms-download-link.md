---
service: "itier-mobile"
title: "SMS Download Link"
generated: "2026-03-03"
type: flow
flow_name: "sms-download-link"
flow_type: synchronous
trigger: "User submits their phone number on the /mobile landing page"
participants:
  - "consumer"
  - "continuumItierMobileService"
  - "twilio"
architecture_ref: "dynamic-sms-download-flow"
---

# SMS Download Link

## Summary

When a user visits `/mobile` and submits their phone number, `itier-mobile` receives a `POST /mobile/send_sms_message` request, constructs an SMS body containing an app download link (or Kochava campaign deep-link if a `grpn_dl` parameter is present), and delegates delivery to the Twilio REST API. Twilio then sends the SMS directly to the user's phone. This flow enables Groupon to drive mobile app installs from web traffic and marketing campaigns.

## Trigger

- **Type**: user-action
- **Source**: User submits phone number form on the `/mobile` landing page (browser `POST` request)
- **Frequency**: On-demand (per user submission)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (browser) | Submits phone number; receives SMS | `consumer` |
| itier-mobile service — SMS Controller | Receives request, validates payload, constructs download link, calls Twilio | `continuumItierMobileService` |
| Twilio | Receives send request via REST API; delivers SMS to user's handset | `twilio` |

## Steps

1. **Receives SMS send request**: Browser submits `POST /mobile/send_sms_message` with the user's phone number in the JSON request body and optional `grpn_dl` query parameter.
   - From: `consumer`
   - To: `continuumItierMobileService`
   - Protocol: HTTPS

2. **Resolves download link**: SMS Controller selects the appropriate app download URL. If `grpn_dl` is present, resolves the corresponding Kochava campaign link from `modules/mobile/DownloadLinks.js`. Otherwise uses the default short-link for the user's country/market.
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

3. **Validates rate limit**: Checks the `rate_limiter` feature flag; if enabled, applies per-IP rate limiting to prevent SMS abuse.
   - From: `continuumItierMobileService` (internal)
   - To: `continuumItierMobileService` (internal)
   - Protocol: In-process

4. **Sends SMS via Twilio**: SMS Controller calls the Twilio REST API using the `twilio` npm SDK, passing the recipient phone number and the constructed message body (download link).
   - From: `continuumItierMobileService`
   - To: `twilio`
   - Protocol: HTTPS (Twilio REST API)

5. **Twilio delivers SMS**: Twilio routes and delivers the SMS message to the user's mobile handset.
   - From: `twilio`
   - To: `consumer`
   - Protocol: SMS (carrier network)

6. **Returns response**: `itier-mobile` returns a `200 application/json` response to the browser, indicating success or failure of the Twilio call.
   - From: `continuumItierMobileService`
   - To: `consumer`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid phone number format | Twilio API returns error; logged as `[TWILIO-ERRORS]` | `200` response with error indicator returned to browser; no SMS delivered |
| User opted out of SMS | Twilio rejects delivery; logged as `[TWILIO-ERRORS]` | Error logged; user does not receive SMS |
| Twilio sender number invalidated | Error logged; manual intervention needed | Swap sender number in code and redeploy |
| Rate limit exceeded | Request rejected before reaching Twilio | Error response returned; SMS not sent |
| Twilio service outage | REST call fails; error logged | `[TWILIO-ERRORS]` logged; no SMS delivered; no automatic retry |

## Sequence Diagram

```
Consumer -> continuumItierMobileService: POST /mobile/send_sms_message (phone number, grpn_dl?)
continuumItierMobileService -> continuumItierMobileService: Resolve download/deep-link URL
continuumItierMobileService -> continuumItierMobileService: Check rate_limiter feature flag
continuumItierMobileService -> twilio: Send SMS (recipient, message body with link)
twilio --> Consumer: SMS delivered to handset
twilio --> continuumItierMobileService: Twilio API response (success/error)
continuumItierMobileService --> Consumer: HTTP 200 JSON (success/error status)
```

## Related

- Architecture dynamic view: `dynamic-sms-download-flow`
- Related flows: [Mobile Landing and App Store Redirect](mobile-landing-redirect.md)
- Integrations: [Twilio](../integrations.md)
- Alert: `itier_mobile_twilio_sms_count` / `itier_mobile_twilio_sms_errors` — see [Runbook](../runbook.md)
