---
service: "garvis"
title: "Change Approval Workflow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "change-approval-workflow"
flow_type: event-driven
trigger: "Google Chat command (@Jarvis change) or inbound JIRA webhook"
participants:
  - "continuumJarvisBot"
  - "continuumJarvisWorker"
  - "continuumJarvisWebApp"
  - "continuumJarvisPostgres"
  - "continuumJarvisRedis"
  - "googlePubSub"
  - "googleChatApi"
  - "jiraApi"
architecture_ref: "dynamic-changeApproval"
---

# Change Approval Workflow

## Summary

The Change Approval Workflow allows engineers to submit, track, and close change requests entirely through Google Chat. When an engineer invokes the change command, Garvis creates a JIRA change ticket, records the request in PostgreSQL, notifies approvers via Google Chat, and listens for JIRA webhook callbacks to update the ticket status and inform the requester of approval or rejection.

## Trigger

- **Type**: event (chat command) or webhook (JIRA status change)
- **Source**: Engineer sends `@Jarvis change <details>` in a Google Chat space; or JIRA delivers a webhook for a tracked change issue
- **Frequency**: On demand (per change request or per JIRA status event)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Cloud Pub/Sub | Delivers the Google Chat message to the bot | `googlePubSub` |
| Jarvis Bot | Receives and parses the change command; dispatches background job | `continuumJarvisBot` |
| Jarvis Redis | Holds the enqueued RQ job | `continuumJarvisRedis` |
| Jarvis Worker | Executes the change creation job | `continuumJarvisWorker` |
| JIRA API | Creates and tracks the change ticket | `jiraApi` |
| Jarvis Postgres | Persists the change record and status | `continuumJarvisPostgres` |
| Google Chat API | Sends confirmation and status updates to the requester and approvers | `googleChatApi` |
| Jarvis Web App | Receives JIRA webhook callbacks for status updates | `continuumJarvisWebApp` |

## Steps

1. **Receives change command**: Engineer sends `@Jarvis change <details>` in Google Chat.
   - From: Google Chat user
   - To: `googlePubSub` (Google Chat delivers event to configured Pub/Sub topic)
   - Protocol: Google Chat event push to Pub/Sub

2. **Consumes Pub/Sub event**: `botPubSubSubscriber` in `continuumJarvisBot` receives the message from the Pub/Sub subscription.
   - From: `googlePubSub`
   - To: `continuumJarvisBot`
   - Protocol: Google Pub/Sub streaming pull

3. **Routes command**: `botCommandRouter` parses the chat event payload and identifies it as a change command; passes it to `botPluginHandlers`.
   - From: `botPubSubSubscriber`
   - To: `botCommandRouter` → `botPluginHandlers`
   - Protocol: In-process (Python)

4. **Enqueues change job**: `botPluginHandlers` enqueues a `create_change` RQ job with the change details.
   - From: `continuumJarvisBot`
   - To: `continuumJarvisRedis`
   - Protocol: Redis (RQ enqueue)

5. **Acknowledges receipt**: `botChatClient` sends an immediate acknowledgment message to the requester in Google Chat.
   - From: `continuumJarvisBot`
   - To: `googleChatApi`
   - Protocol: HTTPS / REST

6. **Executes change creation job**: `workerRqWorker` dequeues the job; `workerPluginJobs` calls the JIRA API to create a change ticket.
   - From: `continuumJarvisWorker`
   - To: `jiraApi`
   - Protocol: HTTPS / REST (jira library)

7. **Persists change record**: Worker writes the new change record (including JIRA issue key and status) to PostgreSQL.
   - From: `continuumJarvisWorker`
   - To: `continuumJarvisPostgres`
   - Protocol: PostgreSQL

8. **Notifies approvers**: Worker calls Google Chat API to post the change request card to the designated approver space or individuals.
   - From: `continuumJarvisWorker`
   - To: `googleChatApi`
   - Protocol: HTTPS / REST

9. **Receives JIRA status webhook**: When an approver acts on the JIRA ticket (approves or rejects), JIRA delivers a webhook POST to `continuumJarvisWebApp`.
   - From: `jiraApi`
   - To: `continuumJarvisWebApp` (`webHttpControllers`)
   - Protocol: HTTPS / webhook POST

10. **Updates change record**: `continuumJarvisWebApp` updates the change status in PostgreSQL and enqueues a notification job.
    - From: `continuumJarvisWebApp`
    - To: `continuumJarvisPostgres`, `continuumJarvisRedis`
    - Protocol: PostgreSQL; Redis (RQ enqueue)

11. **Sends final notification**: Worker executes the notification job and posts the approval or rejection result to the requester in Google Chat.
    - From: `continuumJarvisWorker`
    - To: `googleChatApi`
    - Protocol: HTTPS / REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JIRA API unreachable | RQ job fails; moves to RQ failed queue | Requester receives no JIRA ticket; operator must retry from `/django-rq/` |
| Pub/Sub message not acknowledged | Pub/Sub redelivers message up to ack deadline | Potential duplicate processing; plugin handlers should check for existing change records |
| Google Chat API error on notification | RQ job fails; moves to RQ failed queue | Requester does not receive notification; no automatic retry |
| JIRA webhook delivery failure | JIRA retries on non-2xx response from `continuumJarvisWebApp` | Status update is delayed until JIRA retry succeeds |
| PostgreSQL write failure | Django ORM raises exception; job fails to RQ failed queue | Change record is not persisted; operator must investigate and replay |

## Sequence Diagram

```
Engineer -> GoogleChat: @Jarvis change <details>
GoogleChat -> googlePubSub: Push chat event
googlePubSub -> continuumJarvisBot: Deliver message (streaming pull)
continuumJarvisBot -> continuumJarvisBot: Route command to plugin handler
continuumJarvisBot -> continuumJarvisRedis: Enqueue create_change job
continuumJarvisBot -> googleChatApi: Send acknowledgment to requester
continuumJarvisWorker -> continuumJarvisRedis: Dequeue job
continuumJarvisWorker -> jiraApi: Create change ticket
jiraApi --> continuumJarvisWorker: Return issue key
continuumJarvisWorker -> continuumJarvisPostgres: Persist change record
continuumJarvisWorker -> googleChatApi: Notify approvers
jiraApi -> continuumJarvisWebApp: Deliver status webhook (approval/rejection)
continuumJarvisWebApp -> continuumJarvisPostgres: Update change status
continuumJarvisWebApp -> continuumJarvisRedis: Enqueue notification job
continuumJarvisWorker -> continuumJarvisRedis: Dequeue notification job
continuumJarvisWorker -> googleChatApi: Send approval/rejection to requester
```

## Related

- Architecture dynamic view: `dynamic-changeApproval` (not yet defined in DSL)
- Related flows: [Incident Response Orchestration](incident-response-orchestration.md), [Background Job Scheduling](background-job-scheduling.md)
