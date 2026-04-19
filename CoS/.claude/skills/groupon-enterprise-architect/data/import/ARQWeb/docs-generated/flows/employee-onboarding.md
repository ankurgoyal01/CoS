---
service: "ARQWeb"
title: "Employee Onboarding"
generated: "2026-03-03"
type: flow
flow_name: "employee-onboarding"
flow_type: synchronous
trigger: "Onboarding workflow initiated for a new employee (via UI or automated trigger)"
participants:
  - "continuumArqWebApp"
  - "continuumArqWorker"
  - "continuumArqPostgres"
  - "workday"
  - "activeDirectory"
  - "githubEnterprise"
  - "continuumJiraService"
  - "smtpRelay"
architecture_ref: "components-continuum-arq-web-app"
---

# Employee Onboarding

## Summary

When a new employee joins Groupon, ARQWeb orchestrates their standard access provisioning through a dedicated onboarding workflow. The web application (or an automated trigger) initiates an onboarding request for the new employee, looks up their profile and role in Workday, and submits a batch of standard access requests covering default Active Directory groups and GitHub team memberships appropriate for their role. The ARQ Worker then executes each provisioning job asynchronously and sends a welcome notification when all standard access has been granted.

## Trigger

- **Type**: user-action / automated trigger
- **Source**: HR administrator or automated onboarding system via the ARQWeb UI (`/onboarding`) or API
- **Frequency**: On demand (per new hire event)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| ARQWeb App | Initiates onboarding workflow, fetches employee data, submits batch access requests | `continuumArqWebApp` |
| ARQ Worker | Executes provisioning jobs for each standard access item | `continuumArqWorker` |
| ARQ PostgreSQL | Stores onboarding request batch and queued provisioning jobs | `continuumArqPostgres` |
| Workday | Provides new employee profile, role, team, and manager data | `workday` |
| Active Directory | Receives default group membership additions for the new employee | `activeDirectory` |
| GitHub Enterprise | Receives default team membership additions for the new employee | `githubEnterprise` |
| Jira | Receives onboarding workflow ticket creation | `continuumJiraService` |
| SMTP Relay | Delivers onboarding welcome email and completion notification | `smtpRelay` |

## Steps

1. **Receives onboarding request**: Onboarding form or API call provides the new employee's identifier (email or employee ID).
   - From: `arqWebRouting`
   - To: `arqWebAccessRequestDomain`
   - Protocol: direct (in-process)

2. **Fetches new employee profile from Workday**: Retrieves the employee's role, team, manager, and start date to determine applicable standard access packages.
   - From: `arqWebExternalAdapters`
   - To: `workday`
   - Protocol: HTTPS

3. **Determines standard access package**: The access request domain logic maps the employee's role/team to a predefined set of AD groups and GitHub teams.
   - From: `arqWebAccessRequestDomain`
   - To: (in-process configuration/policy lookup)
   - Protocol: direct

4. **Creates batch access request records**: Writes one access request record per standard access item to PostgreSQL with status `pending` (or `auto-approved` for onboarding defaults).
   - From: `arqWebPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

5. **Creates onboarding Jira ticket**: Creates a Jira ticket representing the onboarding workflow to track completion of all standard access items.
   - From: `arqWebExternalAdapters`
   - To: `continuumJiraService`
   - Protocol: HTTPS API

6. **Enqueues provisioning jobs**: Writes one provisioning job per access item to the PostgreSQL job queue for worker execution.
   - From: `arqWebPersistence`
   - To: `continuumArqPostgres`
   - Protocol: SQL/TCP

7. **Sends onboarding initiation email**: Sends a welcome email to the new employee's manager and/or the employee themselves confirming onboarding access provisioning has started.
   - From: `arqWebExternalAdapters`
   - To: `smtpRelay`
   - Protocol: SMTP

8. **Worker provisions AD memberships**: For each AD-related job, the worker adds the employee to default AD groups via LDAP.
   - From: `arqWorkerExternalAdapters`
   - To: `activeDirectory`
   - Protocol: LDAP/LDAPS

9. **Worker provisions GitHub access**: For each GitHub-related job, the worker adds the employee to default GitHub teams.
   - From: `arqWorkerExternalAdapters`
   - To: `githubEnterprise`
   - Protocol: HTTPS API

10. **Worker records completion and sends welcome notification**: After all jobs complete, updates Jira ticket, writes audit records, and sends a completion email to the employee and manager.
    - From: `arqWorkerExternalAdapters` + `arqWorkerPersistence`
    - To: `continuumJiraService`, `continuumArqPostgres`, `smtpRelay`
    - Protocol: HTTPS API, SQL/TCP, SMTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Workday employee not found | Onboarding request rejected with error | No batch created; initiator must retry after Workday data is available |
| Partial batch creation failure | Successfully created records are persisted; failed items logged | Partial onboarding proceeds; failed items require manual re-submission |
| AD provisioning job fails | Job retried by worker | AD access delayed until retry succeeds |
| GitHub provisioning job fails | Job retried by worker | GitHub access delayed until retry succeeds |
| All retries exhausted | Job marked `failed`; alert triggered | Requires manual intervention by admin |
| Jira ticket creation fails | Job enqueued for retry | Onboarding proceeds; Jira tracking created asynchronously |

## Sequence Diagram

```
Admin/Automation -> ARQWebApp: POST /onboarding (employee identifier)
ARQWebApp -> Workday: GET new employee profile and role
Workday --> ARQWebApp: Employee data (role, team, manager)
ARQWebApp -> ARQWebApp: Determine standard access package for role
ARQWebApp -> ARQPostgres: INSERT batch access request records (auto-approved)
ARQWebApp -> Jira: POST onboarding workflow ticket
ARQWebApp -> ARQPostgres: INSERT provisioning jobs (AD, GitHub)
ARQWebApp -> SMTPRelay: SEND onboarding initiation email
ARQWebApp --> Admin: HTTP 201 (onboarding batch created)
-- async --
ARQWorker -> ARQPostgres: SELECT runnable provisioning jobs
ARQWorker -> ActiveDirectory: LDAP add employee to default AD groups
ARQWorker -> GitHubEnterprise: PUT add employee to default teams
ARQWorker -> Jira: PUT transition ticket to completed
ARQWorker -> ARQPostgres: INSERT audit records; UPDATE jobs complete
ARQWorker -> SMTPRelay: SEND onboarding completion email to employee and manager
```

## Related

- Architecture dynamic view: `components-continuum-arq-web-app`, `components-continuum-arq-worker`
- Related flows: [Access Request Submission](access-request-submission.md), [Access Provisioning (Worker)](access-provisioning-worker.md), [Scheduled User and Service Sync](scheduled-user-service-sync.md)
