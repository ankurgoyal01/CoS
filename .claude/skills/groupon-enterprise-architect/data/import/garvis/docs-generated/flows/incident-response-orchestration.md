---
service: "garvis"
title: "Incident Response Orchestration"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "incident-response-orchestration"
flow_type: event-driven
trigger: "Google Chat command (@Jarvis incident)"
participants:
  - "continuumJarvisBot"
  - "continuumJarvisWorker"
  - "continuumJarvisPostgres"
  - "continuumJarvisRedis"
  - "googlePubSub"
  - "googleChatApi"
  - "jiraApi"
architecture_ref: "dynamic-incidentResponse"
---

# Incident Response Orchestration

## Summary

The Incident Response Orchestration flow enables on-call engineers to declare and coordinate incidents directly from Google Chat. When an incident is declared, Garvis creates a JIRA incident ticket, triggers a PagerDuty alert to the relevant on-call team, opens or identifies a dedicated Google Chat war room space, and posts status updates as the incident progresses. The flow reduces the manual coordination burden during active incidents by centralizing communication and ticketing actions in a single bot command.

## Trigger

- **Type**: event (chat command)
- **Source**: On-call engineer or any engineer sends `@Jarvis incident <description>` in a Google Chat space
- **Frequency**: On demand (per incident declaration)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Google Cloud Pub/Sub | Delivers the Google Chat message to the bot | `googlePubSub` |
| Jarvis Bot | Receives, parses, and dispatches the incident command | `continuumJarvisBot` |
| Jarvis Redis | Holds the enqueued RQ incident job | `continuumJarvisRedis` |
| Jarvis Worker | Executes incident creation and coordination jobs | `continuumJarvisWorker` |
| JIRA API | Creates and tracks the incident ticket | `jiraApi` |
| Jarvis Postgres | Persists the incident record and status | `continuumJarvisPostgres` |
| Google Chat API | Creates war room space and posts incident updates | `googleChatApi` |
| PagerDuty | Receives incident trigger and escalates to on-call team | External (pdpyras) |

## Steps

1. **Receives incident command**: On-call engineer sends `@Jarvis incident <description>` in Google Chat.
   - From: Google Chat user
   - To: `googlePubSub` (Google Chat delivers event to configured Pub/Sub topic)
   - Protocol: Google Chat event push to Pub/Sub

2. **Consumes Pub/Sub event**: `botPubSubSubscriber` in `continuumJarvisBot` receives the message.
   - From: `googlePubSub`
   - To: `continuumJarvisBot`
   - Protocol: Google Pub/Sub streaming pull

3. **Routes incident command**: `botCommandRouter` identifies the incident command and passes it to `botPluginHandlers`.
   - From: `botPubSubSubscriber`
   - To: `botCommandRouter` → `botPluginHandlers`
   - Protocol: In-process (Python)

4. **Enqueues incident job**: `botPluginHandlers` enqueues a `create_incident` RQ job with incident details (description, severity, affected service).
   - From: `continuumJarvisBot`
   - To: `continuumJarvisRedis`
   - Protocol: Redis (RQ enqueue)

5. **Acknowledges incident declaration**: `botChatClient` immediately posts an acknowledgment in the originating Google Chat space.
   - From: `continuumJarvisBot`
   - To: `googleChatApi`
   - Protocol: HTTPS / REST

6. **Creates JIRA incident ticket**: `workerPluginJobs` calls the JIRA API to create an incident issue with the provided description and severity.
   - From: `continuumJarvisWorker`
   - To: `jiraApi`
   - Protocol: HTTPS / REST (jira library)

7. **Triggers PagerDuty alert**: Worker sends a PagerDuty incident trigger to alert the on-call team for the affected service.
   - From: `continuumJarvisWorker`
   - To: PagerDuty API
   - Protocol: HTTPS / REST (pdpyras)

8. **Creates Google Chat war room**: Worker calls Google Chat API to create a dedicated incident space (or post to an existing war room) and adds relevant stakeholders.
   - From: `continuumJarvisWorker`
   - To: `googleChatApi`
   - Protocol: HTTPS / REST

9. **Persists incident record**: Worker writes the incident record (JIRA key, PagerDuty incident ID, Chat space ID, status) to PostgreSQL.
   - From: `continuumJarvisWorker`
   - To: `continuumJarvisPostgres`
   - Protocol: PostgreSQL

10. **Posts incident summary**: Worker posts the incident summary card (JIRA link, PagerDuty link, war room link) to the originating Chat space.
    - From: `continuumJarvisWorker`
    - To: `googleChatApi`
    - Protocol: HTTPS / REST

11. **Handles status updates**: As the incident progresses, additional `@Jarvis` commands (e.g., `@Jarvis resolve`, `@Jarvis update`) trigger further Pub/Sub events that enqueue update jobs, which update JIRA, PagerDuty, and post Chat messages.
    - From: Google Chat user → `googlePubSub` → `continuumJarvisBot` → `continuumJarvisRedis` → `continuumJarvisWorker`
    - To: `jiraApi`, PagerDuty, `googleChatApi`, `continuumJarvisPostgres`
    - Protocol: Same as steps 1–10

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JIRA API fails during incident creation | RQ job fails; moves to RQ failed queue | Incident ticket not created; operator must retry from `/django-rq/` |
| PagerDuty API unreachable | RQ job fails; moves to RQ failed queue | On-call team not alerted via PagerDuty; requires manual escalation |
| Google Chat API fails to create war room | RQ job fails; partial execution logged | War room not created; JIRA ticket may still exist; operator must reconcile |
| Pub/Sub message redelivered | Duplicate processing risk; plugin handler should check for existing incident by description/key | Potential duplicate JIRA tickets if not deduplicated |
| PostgreSQL write failure | Job fails to RQ failed queue | Incident record not persisted; state inconsistent with JIRA and PagerDuty |

## Sequence Diagram

```
Engineer -> GoogleChat: @Jarvis incident <description>
GoogleChat -> googlePubSub: Push chat event
googlePubSub -> continuumJarvisBot: Deliver message (streaming pull)
continuumJarvisBot -> continuumJarvisBot: Route to incident plugin handler
continuumJarvisBot -> continuumJarvisRedis: Enqueue create_incident job
continuumJarvisBot -> googleChatApi: Send acknowledgment
continuumJarvisWorker -> continuumJarvisRedis: Dequeue job
continuumJarvisWorker -> jiraApi: Create incident ticket
jiraApi --> continuumJarvisWorker: Return issue key
continuumJarvisWorker -> PagerDuty: Trigger incident alert
PagerDuty --> continuumJarvisWorker: Confirm trigger
continuumJarvisWorker -> googleChatApi: Create war room space
googleChatApi --> continuumJarvisWorker: Return space details
continuumJarvisWorker -> continuumJarvisPostgres: Persist incident record
continuumJarvisWorker -> googleChatApi: Post incident summary card
```

## Related

- Architecture dynamic view: `dynamic-incidentResponse` (not yet defined in DSL)
- Related flows: [Change Approval Workflow](change-approval-workflow.md), [On-Call Lookup and Notification](on-call-lookup-notification.md), [Background Job Scheduling](background-job-scheduling.md)
