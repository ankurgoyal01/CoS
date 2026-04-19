---
service: "cs-api"
title: "Agent Ability Check"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "agent-ability-check"
flow_type: synchronous
trigger: "Cyclops UI requests agent capability context on load or action"
participants:
  - "customerSupportAgent"
  - "continuumCsApiService"
  - "csApi_apiResources"
  - "authModule"
  - "csApi_repositories"
  - "csApiRoMysql"
architecture_ref: "dynamic-cs-api"
---

# Agent Ability Check

## Summary

This flow resolves the set of abilities and roles available to an authenticated CS agent. When Cyclops loads or when the agent performs an action that requires capability gating, CS API reads the agent's role assignments from MySQL and returns the associated ability set. This controls which actions (e.g., convert-to-cash, bulk operations) the agent is permitted to perform within the UI.

## Trigger

- **Type**: api-call
- **Source**: Cyclops CS agent web application (GET `/abilities`, GET `/agent-info`, GET `/agent-roles`)
- **Frequency**: On-demand; typically on Cyclops UI initialization or per-action gating check

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops CS Agent App | Requests agent capability context | `customerSupportAgent` |
| CS API Service | Resolves agent abilities | `continuumCsApiService` |
| API Resources | Handles request; assembles abilities response | `csApi_apiResources` |
| Auth/JWT Module | Extracts agent identity from JWT | `authModule` |
| Repositories | Reads agent roles from MySQL | `csApi_repositories` |
| CS API MySQL (read replica) | Serves role and ability data | `csApiRoMysql` |

## Steps

1. **Receive abilities request**: Cyclops sends GET `/abilities` or GET `/agent-info`.
   - From: `customerSupportAgent`
   - To: `csApi_apiResources`
   - Protocol: REST / HTTPS

2. **Extract agent identity**: `authModule` decodes the JWT and extracts the agent's identity (agent ID, role claims).
   - From: `csApi_apiResources`
   - To: `authModule`
   - Protocol: Internal

3. **Read agent roles from database**: `csApi_repositories` queries `csApiRoMysql` for the agent's assigned roles.
   - From: `csApi_repositories`
   - To: `csApiRoMysql`
   - Protocol: JDBC / MySQL

4. **Resolve ability set**: `csApi_apiResources` maps roles to the corresponding ability list.
   - From: `csApi_apiResources`
   - To: `csApi_apiResources`
   - Protocol: Internal

5. **Return abilities**: Resolved ability set returned to Cyclops.
   - From: `csApi_apiResources`
   - To: `customerSupportAgent`
   - Protocol: REST / HTTPS / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or expired JWT | `authModule` rejects token | 401 returned; Cyclops redirects to login |
| Read replica unavailable | Repository query fails | 503 returned; agent abilities unavailable |
| Agent has no roles assigned | Empty role set returned | Agent sees minimal/no abilities in Cyclops UI |

## Sequence Diagram

```
CyclopsUI      -> csApi_apiResources  : GET /abilities
csApi_apiResources -> authModule      : Extract agent identity from JWT
authModule --> csApi_apiResources     : agentId, roleClaims
csApi_apiResources -> csApi_repositories : Fetch agent roles
csApi_repositories -> csApiRoMysql    : SELECT roles WHERE agentId=X (JDBC)
csApiRoMysql --> csApi_repositories   : Role list
csApi_repositories --> csApi_apiResources : Roles
csApi_apiResources --> CyclopsUI      : 200 { abilities: [...] }
```

## Related

- Architecture dynamic view: `dynamic-cs-api` (not yet defined in DSL)
- Related flows: [Agent Session Creation](agent-session-creation.md), [Case Memo Management](case-memo-management.md)
