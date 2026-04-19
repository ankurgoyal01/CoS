---
service: "webhooks-service"
title: "Build Status Notifier"
generated: "2026-03-03"
type: flow
flow_name: "build-status-notifier"
flow_type: synchronous
trigger: "status event — a CI system posts a commit status (success, failure, error, pending)"
participants:
  - "continuumWebhooksService"
  - "webhookSvc_hookExecutor"
  - "webhookSvc_githubClient"
  - "webhookSvc_slackClient"
architecture_ref: "components-continuum-webhooks-service-components"
---

# Build Status Notifier

## Summary

The `build_status_notifier` hook notifies individual committers on Slack when a CI build for their commit completes. Rather than spamming an entire team channel, it sends targeted direct messages to the specific engineers whose commits triggered the build. This hook requires no additional configuration in `.webhooks.yml` beyond being enabled — `enabled: true` is sufficient.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise `status` event, fired by a CI system (DotCI, Jenkins, or other status reporters) when a commit's build state changes to `success`, `failure`, or `error`
- **Frequency**: On every CI status update in repositories with `build_status_notifier` enabled in `.webhooks.yml`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Delivers `status` event with commit SHA, state, and context | External |
| Hook Executor | Runs `BuildStatusHook` | `webhookSvc_hookExecutor` |
| GitHub Client | Resolves the SHA to PR/commit author data; fetches commit details | `webhookSvc_githubClient` |
| Slack Client | Resolves author GitHub username to Slack user ID; sends DM | `webhookSvc_slackClient` |

## Steps

1. **Receive `status` event**: The Webhook Router dispatches the `status` event to `BuildStatusHook`.
   - From: `webhookSvc_router`
   - To: `webhookSvc_hookExecutor` (`BuildStatusHook`)
   - Protocol: Direct TypeScript async call

2. **Extract status information**: Reads the commit SHA, build state (`success`, `failure`, `error`, `pending`), build context (CI job name), and target URL from the `status` event payload.
   - From: `webhookSvc_hookExecutor`
   - To: in-process (payload)
   - Protocol: Direct TypeScript object access

3. **Skip non-terminal states**: If the status state is `pending`, exits early — only terminal states (`success`, `failure`, `error`) trigger notifications.
   - From: `webhookSvc_hookExecutor`
   - To: in-process
   - Protocol: Direct TypeScript logic

4. **Resolve commit author**: Uses the `status` event payload's commit author information (name, email) to identify the engineer whose commit triggered the build.
   - From: `webhookSvc_hookExecutor`
   - To: in-process (payload)
   - Protocol: Direct TypeScript object access

5. **Resolve author to Slack user**: Calls `Slack.resolveUserLikeString(authorUsername)` to look up the engineer's Slack user ID via their Groupon email address.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_slackClient` -> Slack Web API (`users.lookupByEmail`)
   - Protocol: HTTPS

6. **Compose notification message**: Builds a Slack message containing the build state, build context (CI job), the commit SHA (shortened), repository name, and a link to the build via the `target_url` from the status event.
   - From: `webhookSvc_hookExecutor`
   - To: in-process
   - Protocol: Direct TypeScript string building

7. **Send Slack direct message**: Calls `Slack.sendDirectMessage(username, message, attachments)` to notify the engineer. The attachment includes a button linking to the CI build URL.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_slackClient` -> Slack Web API (`conversations.open`, `chat.postMessage`)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Status state is `pending` | Exits early | No notification sent |
| Author email not resolvable to Slack user | Logged; error posted to `#webhook-errors` channel | Committer not notified |
| Slack API unavailable | Error logged | Notification not delivered |
| `build_status_notifier` not in `.webhooks.yml` | Hook skipped by Router | No-op |

## Sequence Diagram

```
CI System -> GitHub Enterprise: POST commit status (sha, state=failure, context=DotCi/push, target_url)
GitHub Enterprise -> Webhook Router: status event (sha, state, commit.author)
Webhook Router -> BuildStatusHook: do(event, config, github, slack)
BuildStatusHook -> BuildStatusHook: extract sha, state, context, author
BuildStatusHook -> BuildStatusHook: check state != 'pending'
BuildStatusHook -> Slack Client: resolveUserLikeString(authorUsername)
Slack Client -> Slack Web API: users.lookupByEmail('author@groupon.com')
Slack Web API --> Slack Client: { user: { id: 'U456' } }
BuildStatusHook -> Slack Client: sendDirectMessage(author, message, [{text: 'Build Link', link: targetUrl}])
Slack Client -> Slack Web API: conversations.open({ users: 'U456' })
Slack Client -> Slack Web API: chat.postMessage({ channel, text, attachments })
Slack Web API --> Slack Client: { ok: true }
```

## Related

- Architecture dynamic view: `components-continuum-webhooks-service-components`
- Related flows: [Webhook Ingestion and Dispatch](webhook-ingestion-dispatch.md), [PR Auto-Merge](pr-auto-merge.md), [GitHub to Slack Notifier](github-to-slack-notifier.md)
