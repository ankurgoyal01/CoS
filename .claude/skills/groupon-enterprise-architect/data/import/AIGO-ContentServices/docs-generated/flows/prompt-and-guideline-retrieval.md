---
service: "AIGO-ContentServices"
title: "Prompt and Guideline Retrieval"
generated: "2026-03-03"
type: flow
flow_name: "prompt-and-guideline-retrieval"
flow_type: synchronous
trigger: "Frontend loads guidelines for generation setup, or scraper loads agent configs at crawl start"
participants:
  - "continuumFrontendContentGenerator"
  - "continuumWebScraperService"
  - "continuumPromptDatabaseService"
  - "continuumPromptDatabasePostgres"
architecture_ref: "dynamic-continuumPromptDatabaseService"
---

# Prompt and Guideline Retrieval

## Summary

This flow loads editorial guidelines and AI agent configurations from the Prompt Database Service before content generation or web scraping begins. The frontend fetches L1, L2, and TG guidelines to display in the Generation Settings panel and to include in the generation request payload. The Web Scraper Service fetches agent configurations (with version-specific prompts) to initialise its five AI agents before crawling.

## Trigger

- **Type**: user-action / api-call
- **Source**: Frontend loads the Generation Settings panel (guidelines load); user selects a deal category or PDS code (L2/TG guidelines load); web scraper starts a crawl (agent configs load)
- **Frequency**: On-demand per session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Generation UI | Displays guidelines in GenerationSettings component | `fgUi` |
| API Client Layer | Calls guidelines endpoints | `fgApiClient` |
| Scraper Orchestrator | Calls `/agents/query` at crawl initiation | `wsScraperOrchestrator` |
| Agents API | CRUD and query endpoints for agent configurations | `pdAgentsApi` |
| Guidelines API | Endpoints for L1, L2, and TG guideline retrieval | `pdGuidelinesApi` |
| Prompt Repository | Data access layer over PostgreSQL | `pdPromptRepository` |
| Prompt Database PostgreSQL | Persistent store of agents and guidelines | `continuumPromptDatabasePostgres` |

## Steps

### Guidelines retrieval (Frontend path)

1. **Request L1 guidelines**: Frontend calls `GET /guidelines/l1/` to retrieve all deal-level and section-level L1 guidelines.
   - From: `fgApiClient`
   - To: `pdGuidelinesApi`
   - Protocol: HTTPS/JSON

2. **Query guidelines from DB**: Guidelines API calls Prompt Repository which queries `l1_guidelines` table via SQLAlchemy.
   - From: `pdGuidelinesApi`
   - To: `pdPromptRepository`
   - Protocol: In-process (Python)

3. **Read from PostgreSQL**: Prompt Repository executes SELECT on `l1_guidelines`.
   - From: `pdPromptRepository`
   - To: `continuumPromptDatabasePostgres`
   - Protocol: PostgreSQL (SQLAlchemy)

4. **Return L1 guidelines**: Guidelines API returns `L1Guidelines` response (containing `deal_guidelines` and `section_guidelines` for all valid sections).
   - From: `pdGuidelinesApi`
   - To: `fgApiClient`
   - Protocol: HTTPS/JSON

5. **Request L2 guidelines** (optional, by PDS code): Frontend calls `GET /guidelines/l2/pds/{pds}` with the deal's PDS code. Guidelines API looks up the corresponding category in `data/pds_conversion.csv`, then calls `get_l2_guidelines_by_category()`.
   - From: `fgApiClient`
   - To: `pdGuidelinesApi`
   - Protocol: HTTPS/JSON

6. **Request TG guidelines** (optional, by PDS code): Frontend calls `GET /guidelines/tg/pds/{pds}`. Guidelines API looks up the taxonomy group in `data/pds_conversion.csv`, then calls `get_tg_guidelines_by_taxonomy_group()`.
   - From: `fgApiClient`
   - To: `pdGuidelinesApi`
   - Protocol: HTTPS/JSON

7. **Display guidelines**: Frontend populates the GuidelinesComponent in the generation settings panel; guidelines are included in the `guidelines` field of the subsequent `POST /generate` request.

### Agent configuration retrieval (Scraper path)

1. **Query agent configurations**: At crawl start, Scraper Orchestrator calls `POST /agents/query` with a list of `[{agent_name, version}, ...]` criteria for all five agents.
   - From: `wsScraperOrchestrator`
   - To: `pdAgentsApi`
   - Protocol: HTTPS/JSON (to `http://aigo-contentservices--promptdb.staging.service/agents/query`)

2. **Query agents from DB**: Agents API calls Prompt Repository which queries `agent_configurations` table by `(agent_name, version)` pairs.
   - From: `pdAgentsApi`
   - To: `pdPromptRepository`
   - Protocol: In-process (Python)

3. **Read from PostgreSQL**: Prompt Repository executes SELECT with WHERE clause matching the provided criteria.
   - From: `pdPromptRepository`
   - To: `continuumPromptDatabasePostgres`
   - Protocol: PostgreSQL (SQLAlchemy)

4. **Return agent configurations**: Agents API returns list of `AgentConfiguration` objects (id, agent_name, version, role, prompt, response_class).
   - From: `pdAgentsApi`
   - To: `wsScraperOrchestrator`
   - Protocol: HTTPS/JSON

5. **Instantiate LLM agents**: Scraper Orchestrator creates five `LLMClient` instances from the returned configs.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PDS code not found in `pds_conversion.csv` | HTTPException 404 with `"PDS code '{pds}' not found in conversion table"` | Frontend shows error |
| `pds_conversion.csv` file missing | HTTPException 404 with `"PDS conversion table not found"` | Frontend shows error |
| Guidelines missing for some sections | Empty strings returned for missing sections (no 500 error) | Frontend displays partial guidelines |
| Agent not found by name/version | Returns empty list from `query_agents` | Scraper agent instantiation may fail; HTTP 500 on subsequent crawl |
| Database connection failure | SQLAlchemy exception propagated as HTTP 500 | All guideline/agent endpoints return 500 |

## Sequence Diagram

```
// Frontend guidelines path
fgApiClient -> pdGuidelinesApi: GET /guidelines/l1/
pdGuidelinesApi -> pdPromptRepository: get_guidelines(db)
pdPromptRepository -> continuumPromptDatabasePostgres: SELECT * FROM l1_guidelines
continuumPromptDatabasePostgres --> pdPromptRepository: rows
pdPromptRepository --> pdGuidelinesApi: L1Guidelines object
pdGuidelinesApi --> fgApiClient: {deal_guidelines, section_guidelines}

fgApiClient -> pdGuidelinesApi: GET /guidelines/l2/pds/{pds}
pdGuidelinesApi -> filesystem: read pds_conversion.csv -> category lookup
pdGuidelinesApi -> pdPromptRepository: get_l2_guidelines_by_category(db, category)
pdPromptRepository -> continuumPromptDatabasePostgres: SELECT * FROM l2_guidelines WHERE category=...
continuumPromptDatabasePostgres --> pdPromptRepository: rows
pdGuidelinesApi --> fgApiClient: L2Guidelines

// Scraper agent config path
wsScraperOrchestrator -> pdAgentsApi: POST /agents/query [{agent_name, version}, ...]
pdAgentsApi -> pdPromptRepository: query_agents(db, criteria)
pdPromptRepository -> continuumPromptDatabasePostgres: SELECT ... FROM agent_configurations WHERE (agent_name, version) IN (...)
continuumPromptDatabasePostgres --> pdPromptRepository: rows
pdAgentsApi --> wsScraperOrchestrator: [AgentConfiguration, ...]
```

## Related

- Architecture dynamic view: `dynamic-continuumPromptDatabaseService`
- Related flows: [Multi-Step Content Generation](multi-step-content-generation.md), [Merchant Web Scraping](merchant-web-scraping.md), [Agent Configuration Management](agent-configuration-management.md)
