---
service: "AIGO-CheckoutBot"
title: "Design Tree Update"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "design-tree-update"
flow_type: synchronous
trigger: "Admin operator saves a change to a decision tree node in the Admin Frontend"
participants:
  - "continuumAigoAdminFrontend"
  - "continuumAigoCheckoutBackend"
  - "continuumAigoPostgresDb"
architecture_ref: "dynamic-aigoAdminFrontendComponents"
---

# Design Tree Update

## Summary

This flow covers how a Groupon checkout operator modifies a conversation decision tree node using the AIGO Admin Frontend. The operator edits a node's content, conditions, or actions in the tree editor UI, and the change is validated and persisted to the `ng_design` schema in PostgreSQL. The updated tree becomes active for subsequent conversation turns immediately after the write is committed.

## Trigger

- **Type**: user-action
- **Source**: Admin operator submits a node edit or save action in the `continuumAigoAdminFrontend`
- **Frequency**: On demand (whenever an operator configures or updates a conversation flow)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AIGO Admin Frontend | Provides the tree editor UI and submits changes to the backend | `continuumAigoAdminFrontend` |
| AIGO Checkout Backend | Validates the change, applies business rules, and persists the update | `continuumAigoCheckoutBackend` |
| AIGO PostgreSQL | Durable store for design entities in the `ng_design` schema | `continuumAigoPostgresDb` |

## Steps

1. **Operator edits a tree node**: The operator modifies node content (prompt text, conditions, or actions) in the tree editor component of `adminUiShell`.
   - From: Operator (browser)
   - To: `adminUiShell` / `adminStateAndContexts`
   - Protocol: user interaction (browser)

2. **Updates local editor state**: `adminStateAndContexts` (React context/hooks) tracks the in-progress edit and manages dirty state until the operator saves.
   - From: `adminUiShell`
   - To: `adminStateAndContexts`
   - Protocol: in-process (React state)

3. **Submits save request to backend**: `adminApiClients` calls the backend REST endpoint to persist the node update.
   - From: `continuumAigoAdminFrontend` (`adminApiClients`)
   - To: `continuumAigoCheckoutBackend` (`PUT /api/nodes/:id`)
   - Protocol: REST/HTTPS (JWT)

4. **Validates and routes request**: `backendApiLayer` validates the JWT, deserializes the node payload, and routes to `backendDesignAndConfig`.
   - From: `backendApiLayer`
   - To: `backendDesignAndConfig`
   - Protocol: direct (in-process)

5. **Applies design validation**: `backendDesignAndConfig` validates the node structure (required fields, valid condition expressions, action references) and resolves references within the project tree.
   - From: `backendDesignAndConfig`
   - To: `backendDataAccess` (read existing node for conflict detection)
   - Protocol: direct (in-process)

6. **Reads existing node for conflict detection**: `backendDataAccess` fetches the current node version from `ng_design` to detect concurrent modifications.
   - From: `backendDataAccess`
   - To: `continuumAigoPostgresDb` (ng_design schema)
   - Protocol: PostgreSQL

7. **Persists updated node**: `backendDataAccess` writes the updated node definition to the `ng_design` schema in PostgreSQL.
   - From: `backendDesignAndConfig` via `backendDataAccess`
   - To: `continuumAigoPostgresDb` (ng_design schema)
   - Protocol: PostgreSQL

8. **Returns success response**: The backend returns the updated node record to the Admin Frontend.
   - From: `continuumAigoCheckoutBackend`
   - To: `continuumAigoAdminFrontend`
   - Protocol: REST/HTTPS (JSON response)

9. **Updates editor state on success**: `adminStateAndContexts` clears dirty state and refreshes the tree view with the confirmed saved node.
   - From: `adminApiClients`
   - To: `adminStateAndContexts` / `adminUiShell`
   - Protocol: in-process (React Query cache update)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure (invalid node structure) | Backend returns 400 with error details | Operator sees inline validation error in the tree editor; node not persisted |
| JWT invalid or expired | Backend returns 401 | Operator redirected to re-authenticate |
| Concurrent modification conflict | Backend returns 409 or latest version | Operator prompted to review the latest version before saving |
| PostgreSQL write failure | Backend returns 500 | Operator sees a save error; node not updated; can retry |

## Sequence Diagram

```
Operator -> adminUiShell: Edit node content / conditions / actions
adminUiShell -> adminStateAndContexts: Track edit in local state
adminStateAndContexts -> adminApiClients: Trigger save action
adminApiClients -> continuumAigoCheckoutBackend: PUT /api/nodes/:id (JWT)
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Read existing node (ng_design)
continuumAigoPostgresDb --> continuumAigoCheckoutBackend: Current node version
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Write updated node (ng_design)
continuumAigoPostgresDb --> continuumAigoCheckoutBackend: Write confirmed
continuumAigoCheckoutBackend --> continuumAigoAdminFrontend: 200 OK + updated node
adminStateAndContexts -> adminUiShell: Refresh tree view with saved state
```

## Related

- Architecture dynamic view: `dynamic-aigoAdminFrontendComponents`
- Related flows: [User Message to Response](user-message-to-response.md), [Deal Simulation Replay](deal-simulation-replay.md)
