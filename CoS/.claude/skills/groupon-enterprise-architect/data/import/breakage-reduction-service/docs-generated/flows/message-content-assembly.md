---
service: "breakage-reduction-service"
title: "Message Content Assembly"
generated: "2026-03-03"
type: flow
flow_name: "message-content-assembly"
flow_type: synchronous
trigger: "GET /message/v1/content or GET /brs/v1/message/v1/content"
participants:
  - "continuumBreakageReductionService"
architecture_ref: "components-continuum-breakage-reduction-service-components"
---

# Message Content Assembly

## Summary

The message content assembly flow renders the HTML body for push and in-app campaign notifications. A downstream messaging system (or the RISE scheduler after it fires a job) calls BRS's `/message/v1/content` endpoint with notification context parameters. BRS routes the request to the Message Content Handler, which uses brand, country, and notification-type parameters (`inapp`, `push`) to assemble and return the appropriate localized message content as rendered HTML.

## Trigger

- **Type**: api-call
- **Source**: Internal messaging or campaign delivery system (invoked by RISE or a notification dispatcher)
- **Frequency**: On demand, per notification delivery event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| BRS API Routes | Receives and routes message content requests | `brsApiRoutes` |
| Message Content Handler | Assembles and renders campaign message content for the given notification type, brand, and country | `messageContentHandler` |

## Steps

1. **Receive message content request**: Caller sends `GET /message/v1/content` with `inapp` and/or `push` query parameters identifying the notification type, and `x-brand` and `x-country` headers.
   - From: internal notification dispatcher or RISE callback
   - To: `brsApiRoutes`
   - Protocol: HTTPS

2. **Route to Message Content Handler**: API Routes dispatches the request to the Message Content Handler.
   - From: `brsApiRoutes`
   - To: `messageContentHandler`
   - Protocol: direct

3. **Resolve locale and brand context**: The handler uses the `x-brand` and `x-country` headers along with the I-Tier localization layer (`itier-localization`) to determine the correct locale, language, and brand identity for the message.

4. **Assemble message content**: The handler constructs the message content — subject, body, CTA link — for the requested notification type (`inapp` or `push`), applying localization from the `@grpn/l10n-vex` package.

5. **Return rendered HTML**: The handler returns the assembled message content as `text/html` (200 OK) to the caller.
   - From: `messageContentHandler`
   - To: notification dispatcher
   - Protocol: HTTPS (`text/html`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown notification type | Handler falls back to default content or returns empty | Caller receives 200 with empty/default content |
| Unsupported brand or country | Localization layer uses fallback locale | Content served in fallback language |
| Rendering error | I-Tier error middleware returns error page | Caller receives 5xx HTML error response |

## Sequence Diagram

```
NotificationDispatcher -> brsApiRoutes: GET /message/v1/content?inapp=...&push=...
brsApiRoutes -> messageContentHandler: dispatch
messageContentHandler -> itierLocalization: resolve locale (x-brand, x-country)
itierLocalization --> messageContentHandler: locale context
messageContentHandler -> l10nVex: assemble localized content
l10nVex --> messageContentHandler: rendered content
messageContentHandler --> NotificationDispatcher: 200 OK (text/html)
```

## Related

- Architecture dynamic view: `components-continuum-breakage-reduction-service-components`
- Related flows: [Voucher Next-Actions Computation](voucher-next-actions.md)
