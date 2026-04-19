---
service: "webhooks-service"
title: "Webhook Ingestion and Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "webhook-ingestion-dispatch"
flow_type: synchronous
trigger: "GitHub Enterprise delivers an HTTP POST to the /uber endpoint for any repository event"
participants:
  - "continuumWebhooksService"
  - "webhookSvc_httpEndpoint"
  - "webhookSvc_router"
  - "webhookSvc_configLoader"
  - "webhookSvc_githubClient"
  - "webhookSvc_hookExecutor"
architecture_ref: "components-continuum-webhooks-service-components"
---

# Webhook Ingestion and Dispatch

## Summary

This is the core entry point flow for all automation in the Webhooks Service. GitHub Enterprise delivers every repository event to the `/uber` HTTP endpoint. The service verifies the payload signature, extracts event metadata, resolves the per-repository `.webhooks.yml` configuration, and dispatches all enabled hook implementations concurrently. This flow is the prerequisite to all other hook-specific flows.

## Trigger

- **Type**: api-call (inbound HTTP POST from GitHub Enterprise)
- **Source**: GitHub Enterprise webhook delivery engine; configured as the "uber webhook" on a GitHub organization or repository with the payload URL `http://webhook-vip.snc1/uber`
- **Frequency**: On every GitHub repository event (push, pull request, status, issue comment, commit comment, review comment)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Delivers signed HTTP POST payloads | External |
| HTTP Listener | Accepts request, reads body, initiates async processing | `webhookSvc_httpEndpoint` |
| Webhook Router | Maps event type to hook implementations; runs matched hooks concurrently | `webhookSvc_router` |
| Config Resolver | Fetches and parses `.webhooks.yml` from GitHub for the triggering repository | `webhookSvc_configLoader` |
| GitHub Client | Called by Config Resolver to retrieve `.webhooks.yml` file content | `webhookSvc_githubClient` |
| Hook Executor | Each hook implementation runs as an independent async task | `webhookSvc_hookExecutor` |

## Steps

1. **Receive HTTP POST**: GitHub Enterprise delivers a signed payload to `POST /uber`.
   - From: GitHub Enterprise
   - To: `webhookSvc_httpEndpoint`
   - Protocol: HTTP POST with `X-GitHub-Event`, `X-GitHub-Delivery`, and `X-Hub-Signature` headers

2. **Buffer and parse body**: The HTTP Listener accumulates the request body chunks, then parses the JSON payload.
   - From: `webhookSvc_httpEndpoint` (internal)
   - To: `webhookSvc_httpEndpoint` (internal)
   - Protocol: Node.js `data` / `end` stream events

3. **Verify HMAC signature**: The `@octokit/webhooks` library verifies the `X-Hub-Signature` HMAC-SHA1 against the shared webhook secret. If verification fails, the request is silently dropped.
   - From: `webhookSvc_httpEndpoint`
   - To: `@octokit/webhooks` (in-process)
   - Protocol: In-process call

4. **Resolve repository URL**: The Router extracts `repository.html_url` from the payload to configure the GitHub client. Throws an error if the field is absent.
   - From: `webhookSvc_router`
   - To: payload (in-process)
   - Protocol: Direct TypeScript object access

5. **Set logging context**: AsyncLocalStorage context is populated with event ID, event name, GitHub action, owner, repo, and PR/issue number for structured log correlation.
   - From: `webhookSvc_router`
   - To: `req-ctx` (in-process)
   - Protocol: Direct TypeScript call

6. **Load `.webhooks.yml` configuration**: The Config Resolver attempts to fetch `.webhooks.yml` from GitHub in priority order: (1) triggering ref/SHA, (2) default branch of the repository, (3) org-level `{org}/.webhooks` repository.
   - From: `webhookSvc_configLoader`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API
   - Protocol: HTTPS (`repos.getContent`)

7. **Parse and validate configuration**: The Config Resolver uses `js-yaml` and `io-ts` to parse the YAML and validate hook names against the known list. Unknown hook names are ignored (non-strict mode).
   - From: `webhookSvc_configLoader`
   - To: in-process
   - Protocol: Direct TypeScript call

8. **Match event to hooks**: The Router looks up the event type in the event-to-hook map built at startup. Hooks not listening to this event type are skipped.
   - From: `webhookSvc_router`
   - To: in-process `eventHookMap`
   - Protocol: Direct TypeScript Map lookup

9. **Dispatch enabled hooks concurrently**: For each hook that has a matching enabled configuration entry in `.webhooks.yml`, the Router invokes `hook.do(...)` and collects the promise. All matching hooks run concurrently via `Promise.allSettled`.
   - From: `webhookSvc_router`
   - To: `webhookSvc_hookExecutor` (each hook implementation)
   - Protocol: Direct TypeScript async call

10. **Aggregate results and respond**: After all hooks complete (success or failure), errors are logged. If any hooks failed, the service responds HTTP 500; otherwise HTTP 200.
    - From: `webhookSvc_httpEndpoint`
    - To: GitHub Enterprise (HTTP response)
    - Protocol: HTTP `200` or `500` plain text

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid HMAC signature | Request silently dropped (no response written with error body) | GitHub may retry delivery |
| Missing `repository.html_url` in payload | Error thrown, HTTP 500 returned | Logged; GitHub may retry |
| `.webhooks.yml` not found | Logged as info; returns early with no hook execution | HTTP 200 returned |
| Config parse errors | Error thrown, HTTP 500 returned | Logged; GitHub may retry |
| Single hook execution failure | Isolated via `Promise.allSettled`; error logged; other hooks continue | HTTP 500 returned after all hooks complete |
| All hooks succeed | Normal path | HTTP 200 returned |

## Sequence Diagram

```
GitHub Enterprise -> HTTP Listener: POST /uber (X-GitHub-Event, X-Hub-Signature, body)
HTTP Listener -> HTTP Listener: Buffer body chunks, parse JSON
HTTP Listener -> @octokit/webhooks: verifyAndReceive(id, name, payload, signature)
@octokit/webhooks -> Webhook Router: onAny({ id, name, payload })
Webhook Router -> Config Resolver: findConfigFile(ref, github)
Config Resolver -> GitHub Client: getFileContents('.webhooks.yml', ref)
GitHub Client -> GitHub Enterprise API: GET /repos/{owner}/{repo}/contents/.webhooks.yml
GitHub Enterprise API --> GitHub Client: file content (base64)
GitHub Client --> Config Resolver: decoded YAML string
Config Resolver -> Config Resolver: parseConfig(yaml)
Config Resolver --> Webhook Router: { hooks: [...] }
Webhook Router -> Hook Executor A: hook.do(event, config, github, slack)
Webhook Router -> Hook Executor B: hook.do(event, config, github, slack)
Hook Executor A --> Webhook Router: resolved
Hook Executor B --> Webhook Router: resolved
Webhook Router --> HTTP Listener: all settled
HTTP Listener --> GitHub Enterprise: HTTP 200 (or 500 on failure)
```

## Related

- Architecture dynamic view: `components-continuum-webhooks-service-components`
- Related flows: [PR Jira Integration](pr-jira-integration.md), [PR Auto-Merge](pr-auto-merge.md), [GitHub to Slack Notifier](github-to-slack-notifier.md), [Build Status Notifier](build-status-notifier.md)
