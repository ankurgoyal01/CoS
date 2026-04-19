---
service: "AIGO-ContentServices"
title: "Agent Configuration Management"
generated: "2026-03-03"
type: flow
flow_name: "agent-configuration-management"
flow_type: synchronous
trigger: "AIGO engineer creates, updates, or queries AI agent configurations via the Prompt Database Service API"
participants:
  - "continuumPromptDatabaseService"
  - "continuumPromptDatabasePostgres"
architecture_ref: "dynamic-continuumPromptDatabaseService"
---

# Agent Configuration Management

## Summary

This flow covers the creation, retrieval, updating, and deletion of AI agent configurations stored in the Prompt Database Service. Each agent record defines a versioned AI agent with a system role, prompt template, and expected response class. These configurations are consumed by the Web Scraper Service at crawl time and can be updated by AIGO engineers to tune agent behaviour without redeploying the scraper.

## Trigger

- **Type**: api-call
- **Source**: AIGO engineer calls Prompt Database Service endpoints directly (e.g., via the FastAPI `/docs` UI, curl, or an admin script); or the frontend calls read endpoints when loading agents for display
- **Frequency**: On-demand; infrequent (configuration management activity)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Agents API | Exposes CRUD and query endpoints for agent configurations | `pdAgentsApi` |
| Prompt Repository | Data access layer; executes SQLAlchemy operations | `pdPromptRepository` |
| Prompt Database PostgreSQL | Persists agent configuration records | `continuumPromptDatabasePostgres` |

## Steps

### Create Agent

1. **Submit create request**: Caller sends `POST /agents/` with `AgentConfiguration` body (agent_name, version, role, prompt, response_class).
   - From: engineer/caller
   - To: `pdAgentsApi`
   - Protocol: HTTPS/JSON

2. **Insert record**: Agents API calls `create_agent(db, agent.model_dump())`; Prompt Repository executes INSERT into `agent_configurations`.
   - From: `pdAgentsApi`
   - To: `pdPromptRepository` → `continuumPromptDatabasePostgres`
   - Protocol: In-process (Python) → PostgreSQL (SQLAlchemy)

3. **Return created agent**: API returns the created `AgentConfiguration` with assigned `id`.
   - From: `pdAgentsApi`
   - To: caller
   - Protocol: HTTPS/JSON

### Read Agents

1. **List agents**: Caller sends `GET /agents/?skip=0&limit=10`; Agents API calls `get_agents(db, skip, limit)`; Prompt Repository executes `SELECT ... LIMIT ? OFFSET ?`.
   - From: caller → `pdAgentsApi` → `pdPromptRepository` → `continuumPromptDatabasePostgres`
   - Protocol: HTTPS/JSON → In-process → PostgreSQL

2. **Get specific agent**: Caller sends `GET /agents/{agent_id}`; Agents API calls `get_agent_by_id(db, agent_id)`; returns 404 if not found.

3. **Query by name/version**: Caller sends `POST /agents/query` with list of `{agent_name, version}` objects; used by Web Scraper Service to bulk-load all required agent configs.

### Update Agent

1. **Submit update request**: Caller sends `PUT /agents/{agent_id}` with `AgentUpdate` body (partial update; only non-null fields applied).
   - From: caller
   - To: `pdAgentsApi`
   - Protocol: HTTPS/JSON

2. **Check existence**: Agents API calls `get_agent_by_id(db, agent_id)`; returns HTTP 404 if not found.

3. **Apply update**: Agents API calls `update_agent(db, agent_id, update_data)` with filtered non-null fields; Prompt Repository executes UPDATE.
   - From: `pdAgentsApi`
   - To: `pdPromptRepository` → `continuumPromptDatabasePostgres`
   - Protocol: In-process → PostgreSQL

4. **Return updated agent**: API returns updated `AgentConfiguration`.

### Delete Agent

1. **Submit delete request**: Caller sends `DELETE /agents/{agent_id}`.
2. **Check existence and delete**: Agents API calls `delete_agent(db, agent_id)`; returns 404 if not found; executes DELETE.
3. **Return deleted agent**: API returns the deleted `AgentConfiguration` for confirmation.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate (agent_name, version) on create | PostgreSQL unique constraint violation | HTTP 500 from SQLAlchemy; unique constraint error propagated |
| Agent not found by ID | `get_agent_by_id` returns `None` | HTTP 404 with `"Agent not found"` |
| Invalid body schema | Pydantic validation error | HTTP 422 Unprocessable Entity |
| Database connection failure | SQLAlchemy exception | HTTP 500 |

## Sequence Diagram

```
// Create agent
caller -> pdAgentsApi: POST /agents/ {agent_name, version, role, prompt, response_class}
pdAgentsApi -> pdPromptRepository: create_agent(db, data)
pdPromptRepository -> continuumPromptDatabasePostgres: INSERT INTO agent_configurations VALUES (...)
continuumPromptDatabasePostgres --> pdPromptRepository: inserted row
pdPromptRepository --> pdAgentsApi: AgentConfiguration
pdAgentsApi --> caller: HTTP 200 AgentConfiguration (with id)

// Query agents (bulk, used by scraper)
caller -> pdAgentsApi: POST /agents/query [{agent_name: "clean_text", version: "v0"}, ...]
pdAgentsApi -> pdPromptRepository: query_agents(db, criteria)
pdPromptRepository -> continuumPromptDatabasePostgres: SELECT * FROM agent_configurations WHERE (agent_name, version) IN (...)
continuumPromptDatabasePostgres --> pdPromptRepository: matching rows
pdAgentsApi --> caller: [AgentConfiguration, ...]
```

## Related

- Architecture dynamic view: `dynamic-continuumPromptDatabaseService`
- Related flows: [Prompt and Guideline Retrieval](prompt-and-guideline-retrieval.md), [Merchant Web Scraping](merchant-web-scraping.md)
