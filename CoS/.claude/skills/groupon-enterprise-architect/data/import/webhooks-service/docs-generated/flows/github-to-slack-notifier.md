---
service: "webhooks-service"
title: "GitHub to Slack Notifier"
generated: "2026-03-03"
type: flow
flow_name: "github-to-slack-notifier"
flow_type: synchronous
trigger: "issue_comment, commit_comment, or pull_request_review_comment event"
participants:
  - "continuumWebhooksService"
  - "webhookSvc_hookExecutor"
  - "webhookSvc_githubClient"
  - "webhookSvc_slackClient"
architecture_ref: "components-continuum-webhooks-service-components"
---

# GitHub to Slack Notifier

## Summary

The `github_to_slack_notifier` hook bridges GitHub @mentions to Slack direct messages and channel notifications. When a comment containing `@username` or `@org/team` is posted on a PR, issue, or commit, the hook resolves each GitHub mention to a Slack user ID (via email lookup) or a Slack channel ID (via team description or config mapping) and delivers the notification. This removes the need for engineers to manually check GitHub for mentions.

## Trigger

- **Type**: event
- **Source**: GitHub Enterprise `issue_comment`, `commit_comment`, or `pull_request_review_comment` events. Also handles `issues` events for assignment notifications.
- **Frequency**: On every comment posted in repositories with `github_to_slack_notifier` enabled in `.webhooks.yml`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GitHub Enterprise | Delivers comment events; stores team membership data | External |
| Hook Executor | Runs `GithubToSlackNotifierHook` | `webhookSvc_hookExecutor` |
| GitHub Client | Resolves @mention strings to user objects and team membership lists | `webhookSvc_githubClient` |
| Slack Client | Resolves GitHub usernames/emails to Slack user IDs; sends DMs and channel messages | `webhookSvc_slackClient` |

## Steps

1. **Receive comment event**: The Webhook Router dispatches `issue_comment`, `commit_comment`, or `pull_request_review_comment` to `GithubToSlackNotifierHook`.
   - From: `webhookSvc_router`
   - To: `webhookSvc_hookExecutor` (`GithubToSlackNotifierHook`)
   - Protocol: Direct TypeScript async call

2. **Extract comment body**: Reads the comment body from the event payload.
   - From: `webhookSvc_hookExecutor`
   - To: in-process (payload)
   - Protocol: Direct TypeScript object access

3. **Find all @mentions in comment**: Uses `Github.allMentionsInMessage(commentBody)` which applies the regex `(?:\W{1}|^)@([\w/_-]+)` to extract all mention strings. Individual user mentions and team mentions (`org/team`) are separated.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` (in-process)
   - Protocol: Direct TypeScript call

4. **Resolve user mentions to Slack IDs**: For each individual user mention, calls `Slack.resolveUserLikeString(username)` which attempts email lookup in order: `{username}@groupon.com`, then variants with dashes/underscores swapped.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_slackClient` -> Slack Web API (`users.lookupByEmail`)
   - Protocol: HTTPS

5. **Resolve team mentions to Slack channels**: For each `org/team` mention, first checks the `.webhooks.yml` config for an explicit team-to-channel mapping. If not found, calls `Github.getTeamSlackRoom(teamName)` which reads the Slack channel ID from the team's GitHub description field using the pattern `slack:CHANNEL_ID`.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_githubClient` -> GitHub Enterprise REST API (`teams.getByName`)
   - Protocol: HTTPS

6. **Send direct message to each user**: For each resolved Slack user ID, opens a Slack conversation and sends the notification message containing the comment content and a link to the GitHub comment.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_slackClient` -> Slack Web API (`conversations.open`, `chat.postMessage`)
   - Protocol: HTTPS

7. **Send channel message for team mentions**: For each resolved Slack channel ID, sends a message to the channel notifying the team of the mention.
   - From: `webhookSvc_hookExecutor`
   - To: `webhookSvc_slackClient` -> Slack Web API (`chat.postMessage`)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Comment body contains no @mentions | Exits early | No-op |
| GitHub username not resolvable to Slack user | Logs error; posts error to `#webhook-errors` channel | User not notified |
| Slack API unavailable | Logs error | Notification not delivered |
| Team not found in GitHub | `getTeam` returns null; team mention skipped | No channel notification |
| Ignored users (`ci`, `svc-github-webhook`) | Skipped before any API call | Not notified (intentional) |
| HTML in comment body | Automatically stripped to plain text by Slack client `filterMessage` | Plain text message sent |

## Sequence Diagram

```
GitHub Enterprise -> Webhook Router: issue_comment (body contains @dbeard @mobile/ios-core)
Webhook Router -> GithubToSlackNotifierHook: do(event, config, github, slack)
GithubToSlackNotifierHook -> GitHub Client: allMentionsInMessage(commentBody)
GithubToSlackNotifierHook -> Slack Client: resolveUserLikeString('<username>')
Slack Client -> Slack Web API: users.lookupByEmail('<user>@groupon.com')
Slack Web API --> Slack Client: { user: { id: 'U123' } }
GithubToSlackNotifierHook -> GitHub Client: getTeamSlackRoom('mobile/ios-core')
GitHub Client -> GitHub Enterprise API: GET /teams/{id} (via teams.getByName)
GitHub Enterprise API --> GitHub Client: team { description: 'slack:CF7MWGCNM' }
GithubToSlackNotifierHook -> Slack Client: sendDirectMessage('dbeard', message)
Slack Client -> Slack Web API: conversations.open({ users: 'U123' })
Slack Client -> Slack Web API: chat.postMessage({ channel, text })
GithubToSlackNotifierHook -> Slack Client: sendMessageToRoom('CF7MWGCNM', message)
Slack Client -> Slack Web API: chat.postMessage({ channel: 'CF7MWGCNM', text })
```

## Related

- Architecture dynamic view: `components-continuum-webhooks-service-components`
- Related flows: [Webhook Ingestion and Dispatch](webhook-ingestion-dispatch.md), [Build Status Notifier](build-status-notifier.md)
