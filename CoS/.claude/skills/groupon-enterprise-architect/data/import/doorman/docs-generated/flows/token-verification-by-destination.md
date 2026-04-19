---
service: "doorman"
title: "Token Verification by Destination Tool"
generated: "2026-03-03"
type: flow
flow_name: "token-verification-by-destination"
flow_type: synchronous
trigger: "Destination tool receives browser form POST with Doorman-issued token"
participants:
  - "continuumDoormanService"
  - "destinationTool"
architecture_ref: "components-doorman_components"
---

# Token Verification by Destination Tool

## Summary

After Doorman delivers a signed token via browser form POST, the destination tool must verify the token's authenticity before granting access. Doorman provides the `Token` class (available as a shared library pattern) that implements Base64url decoding, JSON parsing, and cryptographic signature verification using RSA or DSA keys. The `TestDestinationController` in Doorman itself demonstrates this flow by parsing and displaying the received token data.

## Trigger

- **Type**: api-call (browser form POST from Doorman's SSO postback)
- **Source**: User's browser auto-submitting the HTML form rendered by Doorman after successful authentication
- **Frequency**: On-demand — one verification per completed SSO flow

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Doorman (SSO postback) | Delivers the signed token via browser form POST | `continuumDoormanService` |
| Internal user (browser) | Browser carries the form POST to the destination | — |
| Destination tool | Receives `token` (and/or `error`) POST params; verifies and consumes the token | registered destination |
| `Token` class | Parses and cryptographically verifies the token structure | `continuumDoormanService` (shared pattern) |

## Steps

1. **Receives browser form POST**: The destination tool receives an HTTP POST at its configured `destination_path` (e.g., `/doorman-auth`) with `token` and/or `error` as form parameters.
   - From: Internal user (browser)
   - To: Destination tool
   - Protocol: HTTPS form POST

2. **Checks for error field**: If the `error` param is present and non-empty, the authentication failed upstream. The destination tool surfaces the error to the user and denies access.
   - From: Destination tool
   - To: internal logic
   - Protocol: direct

3. **Decodes and parses token**: If `token` is present, the destination tool (using the `Token` class pattern) Base64url-decodes the token string and parses the inner JSON. The token structure is:
   ```json
   {
     "version": 1,
     "data": {
       "uuid": "<uuid>",
       "methods": { "<auth_method>": <timestamp> }
     },
     "key": "<key_id>",
     "signature": "<Base64-encoded signature>"
   }
   ```
   - From: Destination tool
   - To: `Token` (Ruby class)
   - Protocol: direct

4. **Verifies cryptographic signature**: The destination tool calls `token.signature_verifies_data?(verification_keys)` with its set of trusted public keys (RSA or DSA). The `Token` class computes the canonical string representation of the token data and verifies the signature using the key identified by `token.key`.
   - From: Destination tool
   - To: `Token` (Ruby class)
   - Protocol: direct

5. **Extracts identity and method**: If verification passes, the destination tool reads `token.data[:uuid]` (the user's UUID from Users Service) and `token.authentication_method` to determine how the user authenticated.
   - From: Destination tool
   - To: internal session/auth logic
   - Protocol: direct

6. **Grants or denies access**: The destination tool creates a session, issues its own session cookie, and redirects the user to the intended page. If token verification fails, the user is denied access.
   - From: Destination tool
   - To: Internal user (browser)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `error` param present in POST | Destination tool reads error message and denies access | User sees authentication error |
| Neither `token` nor `error` present | Destination tool handles as unexpected state | Destination-specific behavior |
| Token Base64url decode failure | `Token::ParseError` raised | Destination denies access; invalid token |
| Token JSON parse failure | `Token::ParseError` raised | Destination denies access; invalid token |
| Signature verification fails | `signature_verifies_data?` returns `false` | Destination denies access; tampered or forged token |
| Unknown key ID in token | `verification_keys[key_id]` is `nil`; returns `false` | Destination denies access |

## Sequence Diagram

```
continuumDoormanService -> User Browser: HTML form with token (auto-submit)
User Browser -> destinationTool: POST /doorman-auth {token: <Base64url_token>}
destinationTool -> Token: Token.from_encoded_string(<token>)
Token --> destinationTool: Parsed Token object
destinationTool -> Token: token.signature_verifies_data?(verification_keys)
Token --> destinationTool: true / false
destinationTool --> User Browser: Session created (redirect to app) OR 401/error page
```

## Related

- Related flows: [Okta SSO Callback and Token Delivery](okta-sso-callback-token-delivery.md)
- Architecture component view: `components-doorman_components`
