---
service: "webbus"
title: "Message Validation and Topic Whitelisting"
generated: "2026-03-03"
type: flow
flow_name: "message-validation-and-topic-whitelisting"
flow_type: synchronous
trigger: "Each authenticated POST /v2/messages/ request after client_id validation passes"
participants:
  - "webbusHttpApi"
  - "messageValidator"
  - "webbus_messagePublisher"
  - "messageBus"
architecture_ref: "components-webbus-service"
---

# Message Validation and Topic Whitelisting

## Summary

After a request passes client authentication, Webbus validates every message object in the `messages` array before any publish operations begin. Validation enforces that both `topic` and `body` are non-empty strings. The `topic` value must also correspond to an entry in the `config/messagebus.yml` whitelist; messages targeting non-whitelisted topics will fail at the STOMP publish step and be returned to Salesforce as unprocessed.

This flow is a sub-flow of the main [Salesforce to Message Bus Publish](salesforce-to-message-bus-publish.md) flow.

## Trigger

- **Type**: api-call (Grape parameter validation hook, then message-level iteration)
- **Source**: Grape parameter validation, triggered automatically after `client_id` validation succeeds
- **Frequency**: Per-request; runs against every element in the `messages` array

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API (Grape) | Orchestrates validation and publish; collects failure results | `webbusHttpApi` |
| Message Validator | Validates structure of each message (`topic` and `body` non-empty) | `messageValidator` |
| Message Publisher | Attempts STOMP publish per validated message; catches and logs per-message errors | `webbus_messagePublisher` |
| Message Bus | Accepts or rejects the publish attempt per message | `messageBus` |

## Steps

1. **Grape coerces the messages parameter**: Grape uses Virtus to coerce each element of the `messages` JSON array into a `Webbus::V2::Message` object with typed `topic` (String) and `body` (String) attributes.
   - From: `webbusHttpApi`
   - To: `Webbus::V2::Message` Virtus model
   - Protocol: In-process parameter coercion

2. **Runs Message Validator on the full array**: The `Message` Grape validator iterates each coerced message and calls `message.valid?`.
   - From: `webbusHttpApi`
   - To: `messageValidator`
   - Protocol: In-process Grape validation hook (declared via `requires :messages, message: true`)

3. **Validates each message**: `Message#valid?` checks that both `@topic` and `@body` are neither `nil` nor empty string.
   - From: `messageValidator`
   - To: Each `Webbus::V2::Message` instance
   - Outcome on failure: Throws `400 "messages: must be a valid message"` — entire batch is rejected before any publish occurs

4. **Iterates messages for publish**: If all messages pass validation, the `post "/messages"` handler calls `Messages.safe_publish(m)` for each message in order.
   - From: `webbusHttpApi`
   - To: `webbus_messagePublisher`
   - Protocol: In-process iteration with `select`

5. **Sanitises and publishes each message**: `safe_publish` coerces the body (Hash to plain Hash, or leaves String as-is), then calls `Webbus.messagebus.publish(topic, body)`.
   - From: `webbus_messagePublisher`
   - To: `messageBus`
   - Protocol: STOMP over TCP port 61613
   - The `topic` must match one of the destinations listed in `config/messagebus.yml`; non-whitelisted topics will be rejected by the Message Bus

6. **Collects unprocessed messages**: Messages for which `safe_publish` returns `false` (publish error or exception) are accumulated in the `unprocessed` array.
   - From: `webbus_messagePublisher`
   - To: `webbusHttpApi` (return value of `safe_publish`)

7. **Returns result**: If `unprocessed` is empty, HTTP `200` is returned. Otherwise, HTTP `400` is returned with a JSON array of unprocessed `{ topic, body }` objects.
   - From: `webbusHttpApi`
   - To: Caller (Salesforce)
   - Protocol: HTTP response

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Any message has nil or empty `topic` | `Message#valid?` returns false; `messageValidator` throws `400` | Entire batch rejected before any publish; HTTP `400 "messages: must be a valid message"` |
| Any message has nil or empty `body` | `Message#valid?` returns false; `messageValidator` throws `400` | Entire batch rejected before any publish; HTTP `400 "messages: must be a valid message"` |
| Topic is not in `messagebus.yml` whitelist | STOMP client rejects the publish; `safe_publish` rescues `StandardError` | Failed message added to `unprocessed` list; returned to caller in HTTP `400` |
| STOMP connection error during publish | `safe_publish` rescues `StandardError`, logs error with `Webbus.logger.error` | Failed message added to `unprocessed` list; other messages in the batch continue |
| Body is a Hash (not String) | `sanitize_message_body` converts `Hashie::Map` to plain `Hash` via `to_hash` | Transparent to the Message Bus client |

## Sequence Diagram

```
webbusHttpApi -> messageValidator: validate each message in params[:messages]
messageValidator -> Message: valid? (topic.present? && body.present?)
Message --> messageValidator: true | false
messageValidator --> webbusHttpApi: pass | throw :error status:400 (stops flow)

webbusHttpApi -> webbus_messagePublisher: safe_publish(message) [for each message]
webbus_messagePublisher -> webbus_messagePublisher: sanitize_message_body(body)
webbus_messagePublisher -> messageBus: publish(topic, body) via STOMP
messageBus --> webbus_messagePublisher: receipt | error
webbus_messagePublisher --> webbusHttpApi: true (success) | false (failure, error logged)

webbusHttpApi -> webbusHttpApi: collect unprocessed messages (where safe_publish=false)
webbusHttpApi --> Salesforce: HTTP 200 | HTTP 400 { unprocessed messages JSON }
```

## Related

- Architecture component view: `components-webbus-service`
- Parent flow: [Salesforce to Message Bus Publish](salesforce-to-message-bus-publish.md)
- Pre-requisite flow: [Client Authentication](client-authentication.md)
- Topic whitelist: `config/messagebus.yml` — see [Events](../events.md) for the complete list
- Published events: [Events](../events.md)
