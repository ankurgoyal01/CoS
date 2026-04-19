---
service: "webbus"
title: "Client Authentication"
generated: "2026-03-03"
type: flow
flow_name: "client-authentication"
flow_type: synchronous
trigger: "Every inbound HTTP request carrying a client_id query parameter"
participants:
  - "webbusHttpApi"
  - "clientIdValidator"
architecture_ref: "components-webbus-service"
---

# Client Authentication

## Summary

Every request to `POST /v2/messages/` must include a `client_id` query parameter. Webbus validates this value against an environment-specific allowlist loaded from `config/clients.yml` at startup. If the value is absent or not in the allowlist, the request is rejected with HTTP `404` rather than `401` or `403` — this deliberate obfuscation prevents callers from determining whether a given client ID exists, since the endpoint is publicly reachable.

This flow is a sub-flow of the main [Salesforce to Message Bus Publish](salesforce-to-message-bus-publish.md) flow and runs before any message validation or publishing occurs.

## Trigger

- **Type**: api-call (Grape parameter validation hook)
- **Source**: Triggered automatically by the Grape framework on every `POST /v2/messages/` request before any handler logic executes
- **Frequency**: Per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API (Grape) | Receives the request and delegates to Grape's parameter validator | `webbusHttpApi` |
| Client Validator | Checks `client_id` against the in-memory allowlist | `clientIdValidator` |

## Steps

1. **Receives inbound request**: Grape receives the HTTP POST request and begins parameter extraction.
   - From: `salesForce` (caller)
   - To: `webbusHttpApi`
   - Protocol: REST (HTTPS)

2. **Extracts client_id parameter**: Grape extracts the `client_id` query parameter from the request URL.
   - From: `webbusHttpApi`
   - To: `clientIdValidator` (via Grape's `requires :client_id, client: true` declaration)
   - Protocol: In-process Grape validation hook

3. **Checks allowlist**: The `Client` validator calls `Webbus.clients.include?(client_id)`, comparing the value against the list loaded from `config/clients.yml` for the current environment.
   - From: `clientIdValidator`
   - To: In-memory `Webbus.clients` array (loaded at startup from `config/clients.yml`)

4. **Passes or rejects**: If the ID is valid, the validator returns normally and the request proceeds to message validation. If invalid, the validator throws HTTP `404`.
   - On valid: flow continues to `messageValidator`
   - On invalid: Grape returns `404 Not Found` immediately; the request body is never read

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `client_id` query param missing | Grape treats absent required param as validation failure | HTTP `404` returned: `"client id is either missing or incorrect"` |
| `client_id` value not in allowlist | `valid_client?` returns false; validator throws `404` error | HTTP `404` returned: `"client id is either missing or incorrect :: Given client client_id :: Available [...]"` (Note: available list is included in the error message — only logged server-side in production) |

Note: The service is documented as intentionally returning `404` (rather than `401`/`403`) to prevent client ID enumeration since the endpoint is public-facing.

## Sequence Diagram

```
Caller -> webbusHttpApi: POST /v2/messages/?client_id=<value>
webbusHttpApi -> clientIdValidator: validate_param!(:client_id, params)
clientIdValidator -> Webbus.clients: include?(client_id)
Webbus.clients --> clientIdValidator: true | false
clientIdValidator --> webbusHttpApi: pass (valid) | throw :error status:404 (invalid)
webbusHttpApi --> Caller: continue to message validation | HTTP 404
```

## Related

- Architecture component view: `components-webbus-service`
- Parent flow: [Salesforce to Message Bus Publish](salesforce-to-message-bus-publish.md)
- Configuration: `config/clients.yml` — see [Configuration](../configuration.md)
