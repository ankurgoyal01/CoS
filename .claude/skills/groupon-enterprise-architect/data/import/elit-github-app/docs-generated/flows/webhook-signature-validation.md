---
service: "elit-github-app"
title: "Webhook Signature Validation"
generated: "2026-03-03"
type: flow
flow_name: "webhook-signature-validation"
flow_type: synchronous
trigger: "Every inbound POST request to /elit-github-app/webhook from GitHub Enterprise"
participants:
  - "githubEnterprise"
  - "continuumElitGithubAppService"
  - "messageAuthFilter"
  - "webhookResource"
architecture_ref: "components-elitGithubAppService"
---

# Webhook Signature Validation

## Summary

Every webhook POST sent by GitHub Enterprise to `/elit-github-app/webhook` must carry a valid HMAC-SHA256 signature in the `X-Hub-Signature-256` header. The `MessageAuthenticationFilter` intercepts the request before it reaches the webhook resource, recomputes the expected digest from the raw request body and the configured `github.secret`, and rejects any request whose signature does not match. This ensures that only genuine payloads from the configured GitHub App installation are processed.

## Trigger

- **Type**: api-call
- **Source**: GitHub Enterprise webhook delivery system
- **Frequency**: On every pull request event (check suite or check run) in any repository where the app is installed

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Sends the signed webhook POST request | `githubEnterprise` |
| Webhook Signature Filter | Validates the HMAC-SHA256 signature | `messageAuthFilter` |
| GitHub Webhook Resource | Receives the request after successful validation | `webhookResource` |

## Steps

1. **Receive webhook POST**: GitHub Enterprise delivers a POST to `/elit-github-app/webhook` with a JSON body and the `X-Hub-Signature-256: sha256=<hex-digest>` header.
   - From: `githubEnterprise`
   - To: `continuumElitGithubAppService` (Kubernetes service / port 8080)
   - Protocol: HTTPS

2. **Buffer request body**: `MessageAuthenticationFilter` reads the entire request body into a byte array before processing, so the body can be re-used after digest computation.
   - From: `messageAuthFilter`
   - To: (internal — request context)
   - Protocol: JAX-RS filter chain

3. **Compute HMAC-SHA256 digest**: The filter computes an HMAC-SHA256 digest of the raw body bytes using the configured `github.secret` key. The digest is hex-encoded in lowercase.
   - From: `messageAuthFilter`
   - To: `MessageDigester` (in-process)
   - Protocol: direct

4. **Extract signature from header**: The filter reads the `X-Hub-Signature-256` header via `SignatureFunction<Headers>` and extracts the hex signature value. If the header is absent, HTTP 401 is returned immediately.
   - From: `messageAuthFilter`
   - To: request headers
   - Protocol: direct

5. **Compare signature and digest**: The computed digest is compared to the extracted signature. If they match, the request proceeds. If not, HTTP 401 is returned.
   - From: `messageAuthFilter`
   - To: `webhookResource`
   - Protocol: JAX-RS filter chain

6. **Restore body stream**: After validation, the buffered body bytes are set back on the request context as a new `ByteArrayInputStream` so downstream deserialisation can read the body.
   - From: `messageAuthFilter`
   - To: `webhookResource`
   - Protocol: JAX-RS filter chain

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `X-Hub-Signature-256` header absent | `WebApplicationException` thrown with HTTP 401 | Request rejected; no processing occurs |
| Signature does not match computed digest | `WebApplicationException` thrown with HTTP 401 | Request rejected; no processing occurs |
| Development mode with `x-override-auth: true` header | Signature check bypassed (only when `github.development: true`) | Request proceeds — for local testing only |

## Sequence Diagram

```
GitHub Enterprise -> MessageAuthenticationFilter: POST /elit-github-app/webhook (X-Hub-Signature-256: sha256=<hex>)
MessageAuthenticationFilter -> MessageAuthenticationFilter: Read body bytes; compute HMAC-SHA256
MessageAuthenticationFilter -> MessageAuthenticationFilter: Extract signature from X-Hub-Signature-256 header
MessageAuthenticationFilter -> MessageAuthenticationFilter: Compare digest == signature
alt signature valid
  MessageAuthenticationFilter -> GitHubAppResource: Forward request with buffered body
else signature invalid or header absent
  MessageAuthenticationFilter --> GitHub Enterprise: HTTP 401 Unauthorized
end
```

## Related

- Architecture dynamic view: `components-elitGithubAppService`
- Related flows: [Check Suite Requested — Create Check Run](check-suite-requested.md), [PR Diff ELIT Scan](pr-diff-elit-scan.md)
