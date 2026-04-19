---
service: "AIGO-CheckoutBot"
title: "Deal Simulation Replay"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-simulation-replay"
flow_type: batch
trigger: "Admin operator triggers a simulation run from the Admin Frontend to validate conversation flow behavior"
participants:
  - "continuumAigoAdminFrontend"
  - "continuumAigoCheckoutBackend"
  - "continuumAigoPostgresDb"
architecture_ref: "dynamic-aigoCheckoutBackendComponents"
---

# Deal Simulation Replay

## Summary

The Deal Simulation Replay flow allows AIGO Team operators to validate changes to conversation decision trees before deploying them to live checkout users. An operator configures a simulation run with a predefined set of inputs (deal context, user utterances, expected outcomes) and triggers it from the Admin Frontend. The `backendSimulationAndAnalytics` component replays the conversation through the decision tree logic — reading from `ng_design` and writing results to `ng_simulation` in PostgreSQL — and reports back to the operator whether the flow behaved as expected.

## Trigger

- **Type**: user-action (operator-initiated batch job)
- **Source**: Admin operator submits a simulation run in the `continuumAigoAdminFrontend`
- **Frequency**: On demand (before deploying tree changes to production)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AIGO Admin Frontend | Provides simulation configuration UI and displays results | `continuumAigoAdminFrontend` |
| AIGO Checkout Backend | Executes the simulation replay through the decision tree | `continuumAigoCheckoutBackend` |
| AIGO PostgreSQL | Source of design tree state (`ng_design`) and target for simulation results (`ng_simulation`) | `continuumAigoPostgresDb` |

## Steps

1. **Operator configures simulation run**: The operator selects a project, supplies replay input data (deal scenario, user messages, expected routing), and submits the simulation request in the Admin Frontend.
   - From: Operator (browser)
   - To: `adminUiShell` / `adminStateAndContexts`
   - Protocol: user interaction (browser)

2. **Submits simulation request to backend**: `adminApiClients` calls the backend to create and trigger the simulation run.
   - From: `continuumAigoAdminFrontend` (`adminApiClients`)
   - To: `continuumAigoCheckoutBackend` (`POST /api/simulations`)
   - Protocol: REST/HTTPS (JWT)

3. **Validates and routes request**: `backendApiLayer` validates the JWT and routes the simulation request to `backendSimulationAndAnalytics`.
   - From: `backendApiLayer`
   - To: `backendSimulationAndAnalytics`
   - Protocol: direct (in-process)

4. **Creates simulation run record**: `backendDataAccess` writes a new simulation run entry to the `ng_simulation` schema with status `pending`.
   - From: `backendSimulationAndAnalytics` via `backendDataAccess`
   - To: `continuumAigoPostgresDb` (ng_simulation schema)
   - Protocol: PostgreSQL

5. **Reads decision tree from design schema**: `backendDataAccess` fetches the full decision tree definition for the target project from `ng_design`, including all nodes, conditions, prompts, and actions.
   - From: `backendSimulationAndAnalytics` via `backendDataAccess`
   - To: `continuumAigoPostgresDb` (ng_design schema)
   - Protocol: PostgreSQL

6. **Replays conversation through decision tree**: `backendSimulationAndAnalytics` steps through each input message in the replay payload, evaluating decision tree conditions and determining the expected routing outcome at each node. LLM calls are not made during simulation; responses use predefined or mocked outputs.
   - From: `backendSimulationAndAnalytics`
   - To: `backendConversationEngine` (internal replay mode)
   - Protocol: direct (in-process)

7. **Records step-level results**: At each replay step, `backendDataAccess` appends the actual vs. expected routing result to the simulation run record in `ng_simulation`.
   - From: `backendSimulationAndAnalytics` via `backendDataAccess`
   - To: `continuumAigoPostgresDb` (ng_simulation schema)
   - Protocol: PostgreSQL

8. **Marks simulation run complete**: After all replay steps are processed, `backendSimulationAndAnalytics` updates the simulation run status to `completed` or `failed` in `ng_simulation`, with a summary result.
   - From: `backendSimulationAndAnalytics` via `backendDataAccess`
   - To: `continuumAigoPostgresDb` (ng_simulation schema)
   - Protocol: PostgreSQL

9. **Returns simulation run reference**: The backend returns the simulation run ID to the Admin Frontend.
   - From: `continuumAigoCheckoutBackend`
   - To: `continuumAigoAdminFrontend`
   - Protocol: REST/HTTPS (JSON response)

10. **Operator polls or retrieves simulation results**: The Admin Frontend calls `GET /api/simulations/:id` to retrieve the final results and step-level report.
    - From: `continuumAigoAdminFrontend` (`adminApiClients`)
    - To: `continuumAigoCheckoutBackend` (`GET /api/simulations/:id`)
    - Protocol: REST/HTTPS (JWT)

11. **Displays simulation results**: The Admin Frontend renders the pass/fail summary and per-step routing comparison for the operator to review.
    - From: `adminApiClients`
    - To: `adminUiShell`
    - Protocol: in-process (React Query)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid simulation input payload | Backend returns 400 | Operator sees validation error; run not created |
| Decision tree node missing or malformed | Run marked `failed` with step-level error | Operator sees which node caused the failure |
| PostgreSQL read/write failure | Run marked `failed`; error logged | Operator retries the simulation |
| Simulation run times out | Run marked `failed` after timeout threshold | Operator reviews the partial results and investigates |

## Sequence Diagram

```
Operator -> adminUiShell: Configure and submit simulation run
adminApiClients -> continuumAigoCheckoutBackend: POST /api/simulations (JWT)
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Create run record (ng_simulation, status=pending)
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Read decision tree (ng_design)
continuumAigoPostgresDb --> continuumAigoCheckoutBackend: Tree definition
continuumAigoCheckoutBackend -> continuumAigoCheckoutBackend: Replay inputs through tree (no LLM calls)
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Write step results (ng_simulation)
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Update run status (completed/failed)
continuumAigoCheckoutBackend --> continuumAigoAdminFrontend: 201 Created + run ID
adminApiClients -> continuumAigoCheckoutBackend: GET /api/simulations/:id (JWT)
continuumAigoCheckoutBackend --> continuumAigoAdminFrontend: Simulation results
adminUiShell -> Operator: Display pass/fail report
```

## Related

- Architecture dynamic view: `dynamic-aigoCheckoutBackendComponents`
- Related flows: [Design Tree Update](design-tree-update.md), [User Message to Response](user-message-to-response.md)
