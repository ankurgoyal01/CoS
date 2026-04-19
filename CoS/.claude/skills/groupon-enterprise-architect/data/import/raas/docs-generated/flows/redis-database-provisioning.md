---
service: "raas"
title: "Redis Database Provisioning"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "redis-database-provisioning"
flow_type: synchronous
trigger: "Operator manually invokes an Ansible playbook to create or clone a Redis database"
participants:
  - "continuumRaasAnsibleAdminService"
  - "continuumRaasRedislabsApi"
architecture_ref: "components-continuumRaasAnsibleAdminService"
---

# Redis Database Provisioning

## Summary

The Redis Database Provisioning flow handles the lifecycle creation and cloning of Redis databases within managed Redislabs clusters. An operator invokes an Ansible playbook from the RaaS Ansible Admin service. The Create DB Playbook calls the Redislabs Control Plane API to create the database or fetch existing DB specifications. The DB Spec Pruner normalizes the fetched payload into clean playbook inputs before the final database definition is applied.

## Trigger

- **Type**: manual
- **Source**: Operator directly invokes the Ansible Admin playbook (`create_db` or `fetch_db_specs`)
- **Frequency**: On-demand, per database provisioning or cloning request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Create DB Playbook | Orchestrates the create_db and fetch_db_specs Ansible plays | `continuumRaasAnsibleAdminService` |
| DB Spec Pruner | Normalizes fetched DB/alerts payloads into playbook inputs | `continuumRaasAnsibleAdminService` |
| Redislabs Control Plane API | Receives database creation requests and returns DB definitions | `continuumRaasRedislabsApi` |
| Administrator | Initiates the provisioning request and validates the result | (operator) |

## Steps

### Path A: Create New Database

1. **Invoke create_db playbook**: The operator runs the `create_db` Ansible playbook with database specification variables.
   - From: Administrator
   - To: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook`
   - Protocol: Ansible CLI invocation

2. **Submit database creation request**: The Create DB Playbook calls the Redislabs Control Plane API to create the new Redis database.
   - From: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook`
   - To: `continuumRaasRedislabsApi`
   - Protocol: REST/HTTPS

3. **Receive creation confirmation**: The Redislabs API returns the new database definition including connection endpoint details.
   - From: `continuumRaasRedislabsApi`
   - To: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook`
   - Protocol: REST/HTTPS response

### Path B: Clone Existing Database

1. **Invoke fetch_db_specs playbook**: The operator runs the `fetch_db_specs` Ansible playbook targeting an existing database to clone.
   - From: Administrator
   - To: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook`
   - Protocol: Ansible CLI invocation

2. **Fetch existing DB and alerts specs**: The Create DB Playbook retrieves the source database definition and alert configurations from the Redislabs Control Plane API.
   - From: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook`
   - To: `continuumRaasRedislabsApi`
   - Protocol: REST/HTTPS

3. **Prune and normalize DB spec payload**: The DB Spec Pruner processes the fetched DB and alerts payload, removing cluster-specific identifiers and normalizing the spec into a reusable playbook input.
   - From: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook`
   - To: `continuumRaasAnsibleAdminService_raasDbSpecPruner`
   - Protocol: In-process (Python)

4. **Submit cloned database creation**: The normalized spec is submitted to the Redislabs API as a new database creation request.
   - From: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook`
   - To: `continuumRaasRedislabsApi`
   - Protocol: REST/HTTPS

5. **Return provisioning result**: The operator receives the playbook execution summary with the new database endpoint details.
   - From: `continuumRaasAnsibleAdminService_raasCreateDbPlaybook`
   - To: Administrator
   - Protocol: Ansible playbook output

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redislabs API returns error on create | Ansible playbook task fails; execution stops with error output | Database not created; operator must review error and retry |
| DB Spec Pruner fails to normalize payload | Python script exits with error; playbook aborts | Clone operation fails; operator must inspect fetched spec for unexpected fields |
| API authentication failure | Redislabs API rejects request with 401/403 | Playbook fails; operator must verify API credentials via GitHub Secrets bootstrap |
| Network connectivity failure to Redislabs | Ansible task times out | Playbook fails; operator must verify connectivity before retrying |

## Sequence Diagram

```
Administrator -> continuumRaasAnsibleAdminService : Invoke create_db or fetch_db_specs playbook
continuumRaasAnsibleAdminService -> continuumRaasRedislabsApi   : Fetch existing DB specs (clone path)
continuumRaasRedislabsApi        --> continuumRaasAnsibleAdminService : Return DB and alerts payload
continuumRaasAnsibleAdminService -> DbSpecPruner                 : Normalize cloned DB spec
DbSpecPruner                     --> continuumRaasAnsibleAdminService : Return pruned spec
continuumRaasAnsibleAdminService -> continuumRaasRedislabsApi   : Create Redis database
continuumRaasRedislabsApi        --> continuumRaasAnsibleAdminService : Return new DB definition
continuumRaasAnsibleAdminService --> Administrator               : Playbook complete; DB provisioned
```

## Related

- Architecture dynamic view: `components-continuumRaasAnsibleAdminService`
- Related flows: [Redis Cluster Metadata Sync](redis-cluster-metadata-sync.md), [Terraform Deployment Post-Hook](terraform-deployment-post-hook.md)
