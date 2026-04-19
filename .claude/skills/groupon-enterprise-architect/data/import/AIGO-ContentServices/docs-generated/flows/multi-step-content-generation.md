---
service: "AIGO-ContentServices"
title: "Multi-Step Content Generation"
generated: "2026-03-03"
type: flow
flow_name: "multi-step-content-generation"
flow_type: synchronous
trigger: "User submits content generation request via the frontend UI"
participants:
  - "continuumFrontendContentGenerator"
  - "continuumContentGeneratorService"
  - "openAi"
architecture_ref: "dynamic-continuumContentGeneratorService"
---

# Multi-Step Content Generation

## Summary

This flow produces AI-generated deal copy for Groupon merchant listings. The frontend collects deal selection, scraper USPs, editorial guidelines, and generation settings, then sends a single `POST /generate` request. The Content Generator Service orchestrates a configurable sequence of LLM steps (create, customize, content_review, translate) where each step processes one or more deal copy sections concurrently, tracking cost per step and globally.

## Trigger

- **Type**: user-action
- **Source**: Editorial/content operations user submits a generation job via `continuumFrontendContentGenerator` — the Generation UI (`fgUi`) assembles request payload and the API Client Layer (`fgApiClient`) POSTs to the Content Generator Service
- **Frequency**: On-demand per content generation session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Generation UI | User collects deal, guidelines, scraper data, and flow config; initiates request | `fgUi` |
| API Client Layer | Sends `POST /generate` to Content Generator Service | `fgApiClient` |
| Generation API | Receives request, delegates to orchestrator | `cgGenerationApi` |
| Generation Orchestrator | Iterates over flow steps; dispatches concurrent section tasks | `cgGenerationOrchestrator` |
| LLM Client | Builds prompts incorporating guidelines, Salesforce info, and scraper USPs; calls OpenAI API | `cgLlmClient` |
| OpenAI API | Provides LLM completions for each generation step | `openAi` |

## Steps

1. **Collect request data**: User selects a Salesforce deal, optionally provides scraper USPs, selects guidelines (L1/L2/TG), configures flow steps (task, sections, applicable_fields), and triggers generation.
   - From: `fgUi`
   - To: `fgApiClient`
   - Protocol: In-process (React state)

2. **Submit generation request**: API Client Layer sends `POST /generate` with body containing `user_params`, `salesforce_information`, `scraper`, `guidelines`, and `flow` array.
   - From: `fgApiClient`
   - To: `cgGenerationApi`
   - Protocol: HTTPS/JSON

3. **Invoke generation process**: Generation API receives `GenerateRequest`, calls `generation_process()` which instantiates a `ContentGenerator` with the provided context data.
   - From: `cgGenerationApi`
   - To: `cgGenerationOrchestrator`
   - Protocol: In-process (Python)

4. **Process each flow step**: Orchestrator iterates over the `flow` list. For each step it launches concurrent tasks — one per `sections` sub-list — using `asyncio.gather`.
   - From: `cgGenerationOrchestrator`
   - To: `cgLlmClient`
   - Protocol: In-process (Python asyncio)

5. **Build and send LLM prompt**: LLM Client constructs a prompt for the step's `task` (`create`, `customize`, `content_review`, or `translate`), incorporating section guidelines, deal guidelines, Salesforce merchant info, and scraper USPs as directed by `applicable_fields`. Creates a dynamic Pydantic response model for structured output.
   - From: `cgLlmClient`
   - To: `openAi`
   - Protocol: HTTPS (OpenAI SDK — `client.beta.chat.completions.parse`)

6. **Receive structured LLM response**: OpenAI returns a parsed completion. LLM Client extracts `parsed_response`, `input_tokens`, `output_tokens`, and calculates cost (model: `gpt-4o-mini` default).
   - From: `openAi`
   - To: `cgLlmClient`
   - Protocol: HTTPS (OpenAI SDK response)

7. **Aggregate step results**: Orchestrator collects responses from all concurrent section tasks, merges content into `step_content_dict`, accumulates `step_cost` and `global_cost`. Stores result in `intermediate_steps["step_N"]`.
   - From: `cgGenerationOrchestrator`
   - To: `cgGenerationOrchestrator`
   - Protocol: In-process

8. **Repeat for subsequent steps**: Steps 4–7 repeat for each step in the flow, with previous step's content passed as `previous_content` for tasks requiring it (`customize`, `content_review`, `translate`).

9. **Return generation result**: After all steps complete, Generation API returns `GenerateResponse` containing `intermediate_steps`, `final_result` (last step output), and `global_cost`.
   - From: `cgGenerationApi`
   - To: `fgApiClient`
   - Protocol: HTTPS/JSON

10. **Display results**: Frontend renders the generated content sections for editorial review. User may accept, edit, or trigger further generation.
    - From: `fgApiClient`
    - To: `fgUi`
    - Protocol: In-process (React state)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `custom_instructions` for `customize` task | `ValueError` raised in `generate_prompt()` | HTTP 500 with error detail returned to frontend |
| Missing `language` for `translate` task | `ValueError` raised in `generate_prompt()` | HTTP 500 with error detail returned to frontend |
| Guidelines missing for requested sections | `ValueError` raised in `generate_prompt()` | HTTP 500 with error detail returned to frontend |
| OpenAI API error | `get_llm_response()` returns `None`; exception logged | HTTP 500 propagated by Generation API |
| Invalid task value | `ValueError` raised; only `create`, `customize`, `content_review`, `translate` accepted | HTTP 500 with error detail |

## Sequence Diagram

```
fgUi -> fgApiClient: Assemble GenerateRequest payload
fgApiClient -> cgGenerationApi: POST /generate (HTTPS/JSON)
cgGenerationApi -> cgGenerationOrchestrator: generation_process(user_params, salesforce_information, scraper, guidelines, flow)
loop for each step in flow:
  cgGenerationOrchestrator -> cgLlmClient: process_content_generation(task, sections, applicable_fields, previous_content) [concurrent per sections_sublist]
  cgLlmClient -> openAi: client.beta.chat.completions.parse(model, messages, response_format)
  openAi --> cgLlmClient: structured completion (parsed_response, token counts)
  cgLlmClient --> cgGenerationOrchestrator: {parsed_response, input_tokens, output_tokens, total_cost}
  cgGenerationOrchestrator -> cgGenerationOrchestrator: aggregate step results, accumulate cost
end
cgGenerationOrchestrator --> cgGenerationApi: {intermediate_steps, final_result, global_cost}
cgGenerationApi --> fgApiClient: GenerateResponse (HTTPS/JSON)
fgApiClient --> fgUi: Render generated content sections
```

## Related

- Architecture dynamic view: `dynamic-continuumContentGeneratorService`
- Related flows: [Merchant Web Scraping](merchant-web-scraping.md), [Prompt and Guideline Retrieval](prompt-and-guideline-retrieval.md), [Salesforce Deal Data Refresh](salesforce-deal-data-refresh.md)
