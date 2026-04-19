---
service: "cs-api"
title: "Case Memo Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "case-memo-management"
flow_type: synchronous
trigger: "Agent creates, edits, or deletes a case memo in Cyclops"
participants:
  - "customerSupportAgent"
  - "continuumCsApiService"
  - "csApi_apiResources"
  - "authModule"
  - "csApi_repositories"
  - "csApiMysql"
  - "csApiRoMysql"
architecture_ref: "dynamic-cs-api"
---

# Case Memo Management

## Summary

This flow covers the full lifecycle of case memos: creation, retrieval, update, and deletion. Memos are agent-authored notes attached to a customer or case. CS API persists memos in its own MySQL database via the `csApi_repositories` component using the JDBI data access layer. Read operations are routed to the read replica (`csApiRoMysql`) for scalability; write operations go to the primary (`csApiMysql`).

## Trigger

- **Type**: user-action
- **Source**: Cyclops CS agent web application (`/memos` endpoints)
- **Frequency**: On-demand; each time an agent writes or manages a case note

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops CS Agent App | Initiates memo CRUD operation | `customerSupportAgent` |
| CS API Service | Handles and routes memo operations | `continuumCsApiService` |
| API Resources | Validates request; routes to repositories | `csApi_apiResources` |
| Auth/JWT Module | Verifies agent identity | `authModule` |
| Repositories | JDBI data access for memo reads/writes | `csApi_repositories` |
| CS API MySQL (primary) | Persists memo create/update/delete operations | `csApiMysql` |
| CS API MySQL (read replica) | Serves memo list and lookup reads | `csApiRoMysql` |

## Steps

1. **Receive memo request**: Cyclops sends a POST/GET/PUT/DELETE to `/memos`.
   - From: `customerSupportAgent`
   - To: `csApi_apiResources`
   - Protocol: REST / HTTPS

2. **Authenticate agent**: `authModule` validates the JWT in the request header.
   - From: `csApi_apiResources`
   - To: `authModule`
   - Protocol: Internal

3. **Route to repository**: `csApi_apiResources` delegates the operation to `csApi_repositories`.
   - From: `csApi_apiResources`
   - To: `csApi_repositories`
   - Protocol: Internal

4. **Execute read (GET /memos)**: `csApi_repositories` queries `csApiRoMysql` (read replica) for memo list or detail.
   - From: `csApi_repositories`
   - To: `csApiRoMysql`
   - Protocol: JDBC / MySQL

5. **Execute write (POST/PUT/DELETE)**: `csApi_repositories` executes INSERT/UPDATE/DELETE on `csApiMysql` (primary).
   - From: `csApi_repositories`
   - To: `csApiMysql`
   - Protocol: JDBC / MySQL

6. **Return result**: `csApi_apiResources` returns the memo record(s) or operation confirmation.
   - From: `csApi_apiResources`
   - To: `customerSupportAgent`
   - Protocol: REST / HTTPS / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL primary unavailable | Write operation fails | 503 returned; memo not saved |
| MySQL read replica lagging | Stale reads possible | Agent may see slightly outdated memo list |
| Unauthorized agent | `authModule` rejects JWT | 401 returned; operation blocked |
| Memo not found (PUT/DELETE) | Repository returns 0 rows affected | 404 returned to Cyclops |

## Sequence Diagram

```
CyclopsUI      -> csApi_apiResources  : POST /memos { caseId, content }
csApi_apiResources -> authModule      : Validate JWT
authModule --> csApi_apiResources     : Agent identity confirmed
csApi_apiResources -> csApi_repositories : Create memo
csApi_repositories -> csApiMysql      : INSERT memo (JDBC)
csApiMysql --> csApi_repositories     : Memo ID
csApi_repositories --> csApi_apiResources : Memo created
csApi_apiResources --> CyclopsUI      : 201 { memoId }

CyclopsUI      -> csApi_apiResources  : GET /memos?caseId=X
csApi_apiResources -> csApi_repositories : List memos
csApi_repositories -> csApiRoMysql    : SELECT memos (JDBC)
csApiRoMysql --> csApi_repositories   : Memo list
csApi_apiResources --> CyclopsUI      : 200 { memos: [...] }
```

## Related

- Architecture dynamic view: `dynamic-cs-api` (not yet defined in DSL)
- Related flows: [Agent Ability Check](agent-ability-check.md), [Agent Session Creation](agent-session-creation.md)
