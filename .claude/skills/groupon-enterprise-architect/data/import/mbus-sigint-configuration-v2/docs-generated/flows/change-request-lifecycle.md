---
service: "mbus-sigint-configuration-v2"
title: "Change Request Lifecycle"
generated: "2026-03-03"
type: flow
flow_name: "change-request-lifecycle"
flow_type: synchronous
trigger: "API call to POST /change-request"
participants:
  - "continuumMbusSigintConfigurationService"
  - "continuumMbusSigintConfigurationDatabase"
  - "Jira API"
  - "ProdCat API"
  - "Ansible Automation Runtime"
architecture_ref: "components-continuum-mbus-sigint-configuration-service"
---

# Change Request Lifecycle

## Summary

A change request represents a governed MBus topology change — adding destinations (queues/topics), diversions, credentials, or redelivery settings to a cluster. Once submitted, the request passes through a defined state machine (`NEW` -> `DEPLOY_TEST` -> `DEPLOYING_TEST` -> `DEPLOYED_TEST` -> `DEPLOY_PROD` -> `DEPLOYING_PROD` -> `DEPLOYED_PROD`) with optional `FAILED_*`, `CANCELLED`, or `REJECTED` terminal states. Jira tickets are created and transitioned automatically at each major state. Production promotion requires ProdCat approval.

## Trigger

- **Type**: api-call
- **Source**: MBus operator or `mbusible` tooling calling `POST /change-request`
- **Frequency**: On demand (per configuration change request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives and validates the change request payload | `mbsc_apiResources` |
| Domain Services | Orchestrates state transitions and business rules | `mbsc_domainServices` |
| Persistence Adapters | Persists request and config-entry state | `mbsc_persistenceAdapters` |
| MBus Sigint Configuration Database | Stores all request lifecycle data | `continuumMbusSigintConfigurationDatabase` |
| Scheduler Jobs (JiraCreateJob) | Asynchronously creates Jira ticket for the request | `mbsc_schedulerJobs` |
| Integration Clients | Calls Jira, ProdCat, and Ansible | `mbsc_integrationClients` |
| Jira API | Ticket creation, linking, and status transitions | External |
| ProdCat API | Production approval signal | External |
| Ansible Automation Runtime | Executes Artemis config deployment via SSH | External |

## Steps

1. **Receive change request**: Operator sends `POST /change-request` with cluster ID, service name, destinations, diverts, credentials, and redelivery settings.
   - From: `mbusible` / operator
   - To: `mbsc_apiResources`
   - Protocol: REST/HTTP

2. **Validate and persist**: Domain services validate the request and persistence adapters write the request record (status `NEW`), config entries, destinations, diverts, credentials, and access permissions to PostgreSQL.
   - From: `mbsc_apiResources`
   - To: `mbsc_domainServices` -> `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: Direct / JDBC

3. **Trigger Jira ticket creation**: `JiraCreateJob` is fired asynchronously to create a Jira task for the new change request and stores the ticket ID back on the request record.
   - From: `mbsc_schedulerJobs` (JiraCreateJob)
   - To: Jira API
   - Protocol: HTTPS/REST

4. **Link to GPROD**: `JiraLinkingJob` links the MBC task to the corresponding GPROD Jira ticket for the cluster.
   - From: `mbsc_schedulerJobs` (JiraLinkingJob)
   - To: Jira API
   - Protocol: HTTPS/REST

5. **Approve for test deployment**: An admin calls `PUT /change-request/{requestId}/approve` with `true`. Domain services transition status to `DEPLOY_TEST`.
   - From: Admin user
   - To: `mbsc_apiResources` -> `mbsc_domainServices`
   - Protocol: REST/HTTP

6. **Deploy to TEST environment**: `DeployConfigJob` picks up the request (status `DEPLOY_TEST`), calls the config rendering task, sets status to `DEPLOYING_TEST`, and invokes the Ansible SSH command with `#ENVIRONMENT#=TEST`.
   - From: `mbsc_schedulerJobs` (DeployConfigJob)
   - To: `mbsc_configRenderingTask` -> `mbsc_integrationClients` -> Ansible Automation Runtime
   - Protocol: SSH

7. **Record TEST deployment result**: Ansible exits; domain services update status to `DEPLOYED_TEST` (success) or `FAILED_TEST` (failure).
   - From: `mbsc_integrationClients`
   - To: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: JDBC

8. **Transition Jira status to deployed-test**: `ChangeRequestJiraTransitionJob` transitions the Jira task to reflect the test deployment outcome.
   - From: `mbsc_schedulerJobs`
   - To: Jira API
   - Protocol: HTTPS/REST

9. **Submit ProdCat approval**: For production promotion, domain services or `RequestPromoterJob` submits an approval request to ProdCat for the cluster's gprod change metadata.
   - From: `mbsc_domainServices` / `mbsc_schedulerJobs`
   - To: `mbsc_integrationClients` -> ProdCat API
   - Protocol: HTTPS/REST

10. **Promote to DEPLOY_PROD**: `RequestPromoterJob` (scheduled or on ProdCat approval) transitions the request to `DEPLOY_PROD`.
    - From: `mbsc_schedulerJobs` (RequestPromoterJob)
    - To: `mbsc_domainServices` -> `mbsc_persistenceAdapters`
    - Protocol: Direct / JDBC

11. **Deploy to PROD environment**: `DeployConfigJob` triggers with `#ENVIRONMENT#=PROD`, rendering and deploying Artemis production configuration via Ansible SSH.
    - From: `mbsc_schedulerJobs` (DeployConfigJob)
    - To: `mbsc_configRenderingTask` -> Ansible Automation Runtime
    - Protocol: SSH

12. **Finalize request**: Status is set to `DEPLOYED_PROD`; `GprodJiraTransitionJob` transitions the GPROD Jira ticket to closed/done state.
    - From: `mbsc_schedulerJobs` (GprodJiraTransitionJob)
    - To: Jira API + `continuumMbusSigintConfigurationDatabase`
    - Protocol: HTTPS/REST + JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Ansible SSH command fails | `DeployConfigJob` catches exception | Status set to `FAILED_TEST` or `FAILED_PROD`; manual retry via `POST /admin/deploy/{clusterId}/{env}` |
| Jira API unavailable | `JiraCreateJob` / transition job fails | Request continues without Jira linkage; `jiraTicket` field remains empty; job can be retried |
| ProdCat API unavailable | `RequestPromoterJob` cannot get approval | Production promotion blocked; operator must retry when ProdCat recovers |
| Request rejected | Admin calls approve with `false` | Status set to `REJECTED`; terminal state; new request must be created |
| Request cancelled | Admin or operator cancels | Status set to `CANCELLED`; terminal state |

## Sequence Diagram

```
Operator           -> mbsc_apiResources    : POST /change-request
mbsc_apiResources  -> mbsc_domainServices  : create request
mbsc_domainServices -> mbsc_persistenceAdapters : persist request (NEW)
mbsc_schedulerJobs -> Jira API             : JiraCreateJob (create ticket)
mbsc_schedulerJobs -> Jira API             : JiraLinkingJob (link to GPROD)
Admin              -> mbsc_apiResources    : PUT /change-request/{id}/approve (true)
mbsc_domainServices -> mbsc_persistenceAdapters : set status DEPLOY_TEST
mbsc_schedulerJobs -> mbsc_configRenderingTask : DeployConfigJob (TEST)
mbsc_configRenderingTask -> AnsibleRuntime : SSH artemis_config_deploy.sh CLUSTER TEST
AnsibleRuntime     --> mbsc_integrationClients : exit code
mbsc_domainServices -> mbsc_persistenceAdapters : set status DEPLOYED_TEST
mbsc_schedulerJobs -> ProdCat API          : RequestPromoterJob (request approval)
mbsc_schedulerJobs -> mbsc_persistenceAdapters : set status DEPLOY_PROD
mbsc_schedulerJobs -> AnsibleRuntime       : DeployConfigJob (PROD)
AnsibleRuntime     --> mbsc_integrationClients : exit code
mbsc_domainServices -> mbsc_persistenceAdapters : set status DEPLOYED_PROD
mbsc_schedulerJobs -> Jira API             : GprodJiraTransitionJob (close ticket)
```

## Related

- Architecture dynamic view: `components-continuum-mbus-sigint-configuration-service`
- Related flows: [Scheduled Configuration Deployment](scheduled-config-deployment.md), [Jira Ticket Automation](jira-ticket-automation.md)
