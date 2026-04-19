---
service: "webbus"
title: "Salesforce to Message Bus Publish"
generated: "2026-03-03"
type: flow
flow_name: "salesforce-to-message-bus-publish"
flow_type: synchronous
trigger: "HTTP POST from Salesforce to POST /v2/messages/"
participants:
  - "salesForce"
  - "continuumWebbusService"
  - "webbusHttpApi"
  - "clientIdValidator"
  - "messageValidator"
  - "webbus_messagePublisher"
  - "messageBus"
architecture_ref: "dynamic-salesforce-to-message-bus-publish-flow"
---

# Salesforce to Message Bus Publish

## Summary

This is the core flow of the Webbus service. Salesforce detects CRM object changes, batches the resulting messages, and POSTs them to `POST /v2/messages/` on the Webbus external VIP. Webbus authenticates the caller, validates each message payload, and synchronously publishes each valid message to the appropriate JMS topic on the Groupon Message Bus. Any messages that fail to publish are returned in the response body for Salesforce to redeliver.

The flow is fully synchronous: Salesforce blocks on the HTTP response before determining which messages succeeded and which need redelivery. This design makes Webbus a stateless bridge — it holds no message state between requests.

## Trigger

- **Type**: api-call
- **Source**: Salesforce (external CRM system) — a continuous process runs in Salesforce to deliver pending messages
- **Frequency**: On demand, whenever Salesforce has pending messages to deliver (continuous polling; alert if pending count exceeds threshold)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Salesforce | Initiates the publish request with a batch of CRM change events | `salesForce` |
| Webbus Service | Receives, validates, and forwards messages | `continuumWebbusService` |
| HTTP API (Grape) | Accepts the POST request, orchestrates validation and publishing | `webbusHttpApi` |
| Client Validator | Authenticates the caller via `client_id` allowlist check | `clientIdValidator` |
| Message Validator | Validates `topic` and `body` fields for each message | `messageValidator` |
| Message Publisher | Publishes each validated message to the Message Bus via STOMP | `webbus_messagePublisher` |
| Message Bus | Receives published events and delivers them to downstream topic subscribers | `messageBus` |

## Steps

1. **Salesforce sends batch publish request**: Salesforce POSTs a JSON payload to the Webbus external VIP.
   - From: `salesForce`
   - To: `continuumWebbusService` (`webbusHttpApi`)
   - Protocol: REST (HTTPS POST to `webbus.groupon.com/v2/messages/?client_id=<id>`)
   - Body: `{ "messages": [{ "topic": "<jms-topic>", "body": "<payload>" }, ...] }`

2. **Validates client identity**: The Grape framework invokes the client validator before processing the request body.
   - From: `webbusHttpApi`
   - To: `clientIdValidator`
   - Protocol: In-process Grape validation
   - Outcome: If `client_id` is not in the environment allowlist (`config/clients.yml`), the request is rejected with HTTP `404` and processing stops.

3. **Validates each message payload**: The message validator checks every message object in the array.
   - From: `webbusHttpApi`
   - To: `messageValidator`
   - Protocol: In-process Grape validation
   - Outcome: If any message has an empty or missing `topic` or `body`, the request is rejected with HTTP `400`.

4. **Publishes each validated message to the Message Bus**: The `V2::Messages` handler iterates the message array, calling `safe_publish` for each.
   - From: `webbusHttpApi`
   - To: `webbus_messagePublisher`
   - Protocol: In-process method call

5. **STOMP publish to Message Bus cluster**: The `messagebus` client sends each message to the target JMS topic via STOMP.
   - From: `webbus_messagePublisher`
   - To: `messageBus`
   - Protocol: STOMP over TCP port 61613
   - Target: `mbus-prod-na.us-central1.mbus.prod.gcp.groupondev.com:61613` (production)

6. **Returns result to Salesforce**: Webbus returns HTTP `200` if all messages were published, or HTTP `400` with a JSON array of failed messages.
   - From: `continuumWebbusService`
   - To: `salesForce`
   - Protocol: HTTP response
   - Success body: empty (HTTP 200)
   - Failure body: JSON array of unprocessed `{ topic, body }` objects

7. **Salesforce redelivers failed messages**: If the response contains unprocessed messages, Salesforce retains them and includes them in the next delivery batch.
   - From: `salesForce` (internal Salesforce process)
   - Protocol: Salesforce-internal retry queue

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or missing `client_id` | Grape client validator throws HTTP `404` | Request rejected; Salesforce does not receive an unprocessed-message list — the entire request is treated as an authentication failure |
| Missing or empty `topic`/`body` on any message | Grape message validator throws HTTP `400` | Entire batch rejected before any publish attempts |
| STOMP publish failure for individual message | `safe_publish` rescues `StandardError`, logs the error, returns `false` | The failed message is added to the `unprocessed` list returned in the HTTP `400` response body |
| Message Bus cluster unreachable (all publishes fail) | All messages added to `unprocessed` list | HTTP `400` returned with full batch; Salesforce redelivers all messages |
| Hung or failed HTTP response | Salesforce treats the entire batch as undelivered | Salesforce redelivers all messages in the next cycle |
| Unhandled Ruby exception | `Middleware::Exception` catches it, logs it, returns HTTP `500` | Salesforce treats as a delivery failure and redelivers |

## Sequence Diagram

```
Salesforce -> webbusHttpApi: POST /v2/messages/?client_id=<id> { messages: [...] }
webbusHttpApi -> clientIdValidator: validate client_id against config/clients.yml allowlist
clientIdValidator --> webbusHttpApi: valid | 404 error (stops flow)
webbusHttpApi -> messageValidator: validate each message { topic, body } non-empty
messageValidator --> webbusHttpApi: valid | 400 error (stops flow)
webbusHttpApi -> webbus_messagePublisher: safe_publish(message) for each message
webbus_messagePublisher -> messageBus: STOMP publish to jms.topic.<entity>.<action>
messageBus --> webbus_messagePublisher: receipt acknowledgement | error
webbus_messagePublisher --> webbusHttpApi: success=true | success=false (logged)
webbusHttpApi --> Salesforce: HTTP 200 (all success) | HTTP 400 { unprocessed: [...] }
Salesforce -> Salesforce: redeliver unprocessed messages in next cycle
```

## Related

- Architecture dynamic view: `dynamic-salesforce-to-message-bus-publish-flow`
- Related flows: [Client Authentication](client-authentication.md), [Message Validation and Topic Whitelisting](message-validation-and-topic-whitelisting.md)
- Events published: see [Events](../events.md) for the full topic whitelist
- Integrations: see [Integrations](../integrations.md) for Message Bus connection details
