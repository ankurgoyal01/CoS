---
service: "authoring2"
title: "Snapshot Deploy to Live"
generated: "2026-03-03"
type: flow
flow_name: "snapshot-deploy-live"
flow_type: synchronous
trigger: "User certifies a staging-verified snapshot and activates it to live TaxonomyV2"
participants:
  - "authoring2RestApi"
  - "continuumAuthoring2Postgres"
  - "continuumTaxonomyService"
architecture_ref: "components-continuum-authoring2-authoring2TaxonomyService"
---

# Snapshot Deploy to Live

## Summary

After a full taxonomy snapshot has been created, it goes through a multi-stage promotion process before it is activated in the live TaxonomyV2 serving tier. First it is deployed to a test/staging environment, then certified by a content author, and finally activated live. The live activation sends an HTTP PUT to `continuumTaxonomyService` with the snapshot UUID — TaxonomyV2 then loads the snapshot content into its serving database (RaaS). This flow spans `continuumAuthoring2Service` and `continuumTaxonomyService`.

## Trigger

- **Type**: api-call (user-action via browser)
- **Source**: Ember.js authoring UI — content author initiates deployment after verifying snapshot content
- **Frequency**: Approximately every three weeks for production taxonomy content deployment cycles

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Ember.js UI | Initiates each promotion step | — |
| REST Facades (`SnapshotRESTFacade`) | Enforces state machine transitions; calls TaxonomyV2 | `authoring2RestApi` |
| Authoring2 PostgreSQL | Stores and updates snapshot deploy status | `continuumAuthoring2Postgres` |
| TaxonomyV2 Service | Receives activation request and loads snapshot into serving layer | `continuumTaxonomyService` |

## Steps

### Stage 1 — Deploy to Test

1. **User initiates test deploy**: Ember.js UI sends `POST /snapshots/deploy_test/{guid}`.
   - From: Ember.js UI
   - To: `SnapshotRESTFacade`
   - Protocol: REST / HTTP POST

2. **Checks current status**: For full snapshots, verifies current `deployStatus = 'new'`. Partial snapshots skip to `test_live` directly.
   - From: `SnapshotRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

3. **Updates deploy status to `test_live`**: Sets snapshot `deployStatus = 'test_live'` in PostgreSQL.
   - From: `SnapshotRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

4. **Returns success**: HTTP 200 with snapshot GUID confirmation.
   - From: `SnapshotRESTFacade`
   - To: Ember.js UI
   - Protocol: REST / HTTP 200

### Stage 2 — Certify on Staging

5. **User certifies snapshot**: Ember.js UI sends `POST /snapshots/test_certify/{guid}` from the production authoring instance after verifying the staging deployment.
   - From: Ember.js UI
   - To: `SnapshotRESTFacade`
   - Protocol: REST / HTTP POST

6. **Validates state**: Verifies `deployStatus = 'test_live'`. Rejects if not in that state.
   - From: `SnapshotRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

7. **Updates status to `test_verified`**: Sets `deployStatus = 'test_verified'` in PostgreSQL.
   - From: `SnapshotRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

### Stage 3 — Activate Live

8. **User activates live**: Ember.js UI sends `POST /snapshots/deploy_live/{guid}`.
   - From: Ember.js UI
   - To: `SnapshotRESTFacade`
   - Protocol: REST / HTTP POST

9. **Validates state**: Verifies `deployStatus = 'test_verified'`. Rejects with HTTP 403 if not verified.
   - From: `SnapshotRESTFacade`
   - To: `continuumAuthoring2Postgres`
   - Protocol: JPA/JDBC

10. **Checks snapshot type**: Determines whether this is a full snapshot or partial snapshot (via `getFullSnapshotFromSnapshot`) to select the correct activation endpoint.
    - From: `SnapshotRESTFacade`
    - To: `continuumAuthoring2Postgres`
    - Protocol: JPA/JDBC

11. **Sends activation PUT to TaxonomyV2**: Calls `deploy.live.activation_ep` (`http://taxonomyv2.production.service/snapshots/activate`) or `pt_deploy.live.activation_ep` with JSON body `{"uuid": "<snapshotGuid>"}`.
    - From: `SnapshotRESTFacade`
    - To: `continuumTaxonomyService`
    - Protocol: HTTP PUT (Apache HttpComponents)

12. **Returns activation result**: If TaxonomyV2 returns HTTP 200, Authoring2 responds with success message. If non-200, returns HTTP 500.
    - From: `SnapshotRESTFacade`
    - To: Ember.js UI
    - Protocol: REST / HTTP 200 or 500

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Snapshot not in `new` state (deploy to test) | HTTP 403 "Snapshot is in X state, operation not permitted" | Deploy blocked |
| Snapshot not in `test_live` state (certify) | HTTP 403 with explanation | Certification blocked |
| Snapshot not in `test_verified` state (deploy live) | HTTP 403 with explanation | Live activation blocked |
| TaxonomyV2 activation returns non-200 | HTTP 500 returned to user | Snapshot deploy status not updated; manual retry required |
| TaxonomyV2 service unreachable | IOException propagated; HTTP 500 | Snapshot status unchanged; retry manually |

## Sequence Diagram

```
Ember.js UI -> SnapshotRESTFacade: POST /snapshots/deploy_test/{guid}
SnapshotRESTFacade -> PostgreSQL: SELECT deploy_status WHERE guid = ?
PostgreSQL --> SnapshotRESTFacade: status = 'new'
SnapshotRESTFacade -> PostgreSQL: UPDATE snapshots SET deploy_status = 'test_live'
SnapshotRESTFacade --> Ember.js UI: HTTP 200 (guid + success)

Ember.js UI -> SnapshotRESTFacade: POST /snapshots/test_certify/{guid}
SnapshotRESTFacade -> PostgreSQL: verify status = 'test_live'
SnapshotRESTFacade -> PostgreSQL: UPDATE snapshots SET deploy_status = 'test_verified'
SnapshotRESTFacade --> Ember.js UI: HTTP 200 (guid)

Ember.js UI -> SnapshotRESTFacade: POST /snapshots/deploy_live/{guid}
SnapshotRESTFacade -> PostgreSQL: verify status = 'test_verified'
SnapshotRESTFacade -> PostgreSQL: SELECT is_full_snapshot WHERE guid = ?
SnapshotRESTFacade -> TaxonomyV2Service: PUT /snapshots/activate {"uuid": "<guid>"}
TaxonomyV2Service --> SnapshotRESTFacade: HTTP 200
SnapshotRESTFacade --> Ember.js UI: HTTP 200 (guid + success message)
```

## Related

- Architecture dynamic view: `components-continuum-authoring2-authoring2TaxonomyService`
- Related flows: [Snapshot Creation](snapshot-creation.md), [Partial Snapshot Creation](partial-snapshot-creation.md)
