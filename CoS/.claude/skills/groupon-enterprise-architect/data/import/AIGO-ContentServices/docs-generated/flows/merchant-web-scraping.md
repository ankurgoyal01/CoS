---
service: "AIGO-ContentServices"
title: "Merchant Web Scraping"
generated: "2026-03-03"
type: flow
flow_name: "merchant-web-scraping"
flow_type: synchronous
trigger: "User provides a merchant URL and triggers scrape in the frontend UI"
participants:
  - "continuumFrontendContentGenerator"
  - "continuumWebScraperService"
  - "continuumPromptDatabaseService"
  - "openAi"
  - "merchantWebsites"
architecture_ref: "dynamic-continuumWebScraperService"
---

# Merchant Web Scraping

## Summary

This flow crawls a merchant's website to extract the top 10 unique selling points (USPs) which are then used as enrichment context for deal copy generation. The Web Scraper Service uses headless Chromium to navigate merchant pages, applies a sequence of AI agents (loaded from the Prompt Database Service) to filter links, clean text, assess content quality, extract USPs, and deduplicate across pages. The crawl is bounded by `max_pages` and terminates early once 10 USPs are collected.

## Trigger

- **Type**: user-action
- **Source**: User enters a merchant URL and optionally configures `max_pages` and agent versions in the `fgUi` WebScraper component; the API Client Layer (`fgApiClient`) POSTs to the Web Scraper Service
- **Frequency**: On-demand per deal preparation session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Generation UI (WebScraper component) | User inputs merchant URL and starts crawl | `fgUi` |
| API Client Layer | Sends `POST /crawl` to Web Scraper Service | `fgApiClient` |
| Scraper API | Receives crawl request; delegates to Scraper Orchestrator in a thread executor | `wsScraperApi` |
| Scraper Orchestrator | Controls crawl loop, applies AI agents, aggregates USPs | `wsScraperOrchestrator` |
| Crawler Engine | Fetches pages and extracts raw HTML content and links using Selenium + BeautifulSoup | `wsCrawlerEngine` |
| Agents API | Provides agent configurations (prompts, roles, response classes) for AI agents | `pdAgentsApi` |
| OpenAI API | Executes AI agent prompts for link filtering, text cleaning, quality gating, USP extraction, deduplication | `openAi` |
| Merchant Websites | Target web pages crawled for commercial content | `merchantWebsites` |

## Steps

1. **Submit crawl request**: API Client Layer sends `POST /crawl` with body containing `start_url`, `max_pages`, `file` flag, and `agent_versions` map (`clean_text`, `extract_usps`, `filter_links`, `manage_duplicates`, `quality_content` version strings; defaults: `v0` for most, `v3.1` for `extract_usps`).
   - From: `fgApiClient`
   - To: `wsScraperApi`
   - Protocol: HTTPS/JSON

2. **Load AI agent configurations**: Scraper Orchestrator calls `/agents/query` on Prompt Database Service with a list of `{agent_name, version}` criteria to fetch all five agent configurations in a single call.
   - From: `wsScraperOrchestrator`
   - To: `pdAgentsApi`
   - Protocol: HTTPS/JSON (POST `http://aigo-contentservices--promptdb.staging.service/agents/query`)

3. **Instantiate AI agents**: Scraper Orchestrator creates five `LLMClient` instances (`clean_text`, `extract_usps`, `filter_links`, `manage_duplicates`, `quality_content`) from the returned agent configs.

4. **Setup Chromium driver**: Scraper Orchestrator calls `setup_chromium_driver()` to initialise a headless Selenium WebDriver.
   - From: `wsScraperOrchestrator`
   - To: `wsCrawlerEngine`
   - Protocol: In-process

5. **Iterate over links**: Starting from `start_url`, for each URL in `links_to_follow` (up to `max_pages`):

   a. **Fetch page**: Crawler Engine loads the URL via Selenium, extracts page text content and all links using BeautifulSoup.
      - From: `wsCrawlerEngine`
      - To: `merchantWebsites`
      - Protocol: HTTPS (headless Chromium)

   b. **Filter links** (if `len(links_to_follow) < max_pages * 1.5`): AI agent `filter_links` sends discovered links to OpenAI to rank and filter by commercial relevance. Filtered links appended to crawl queue.
      - From: `wsScraperOrchestrator`
      - To: `openAi`
      - Protocol: HTTPS (OpenAI SDK)

   c. **Clean text**: AI agent `clean_text` sends raw page content to OpenAI to remove boilerplate and normalise text.
      - From: `wsScraperOrchestrator`
      - To: `openAi`
      - Protocol: HTTPS (OpenAI SDK)

   d. **Quality gate**: AI agent `quality_content` sends cleaned text to OpenAI; if response is `false`, page is skipped.
      - From: `wsScraperOrchestrator`
      - To: `openAi`
      - Protocol: HTTPS (OpenAI SDK)

   e. **Extract USPs**: AI agent `extract_usps` sends cleaned text to OpenAI to extract unique selling points as a list.
      - From: `wsScraperOrchestrator`
      - To: `openAi`
      - Protocol: HTTPS (OpenAI SDK)

   f. **Deduplicate USPs** (for page 2+): AI agent `manage_duplicates` sends combined USPs from all pages to OpenAI to merge duplicates and re-rank.
      - From: `wsScraperOrchestrator`
      - To: `openAi`
      - Protocol: HTTPS (OpenAI SDK)

6. **Terminate crawl**: Loop stops when `domain_usps >= 10` or `page_counter >= max_pages`.

7. **Return results**: Scraper API returns `{"scraper_results": [...], "top10_usps": [...], "global_cost": <float>}`.
   - From: `wsScraperApi`
   - To: `fgApiClient`
   - Protocol: HTTPS/JSON

8. **Display USPs**: Frontend displays extracted USPs for user review and pre-populates scraper context for subsequent content generation.
   - From: `fgApiClient`
   - To: `fgUi`
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Page load failure (Selenium) | `scrape_content_and_links` returns `None`; warning logged; page skipped | Crawl continues to next URL |
| Prompt Database Service unreachable | `query_agents` returns `[]`; `LLMClient.from_agent_config_dict` may fail | HTTP 500 returned to frontend |
| OpenAI API error during agent call | Exception caught and re-raised; logged | HTTP 500 returned to frontend |
| Chromium driver setup failure | Exception raised in `setup_chromium_driver()` | HTTP 500 returned to frontend |
| Unicode/surrogate pair in scraped content | `clean_nan()` strips surrogate pairs and re-encodes as UTF-8 | Data sanitised transparently |

## Sequence Diagram

```
fgApiClient -> wsScraperApi: POST /crawl {start_url, max_pages, agent_versions}
wsScraperApi -> wsScraperOrchestrator: run_scraper() [thread executor]
wsScraperOrchestrator -> pdAgentsApi: POST /agents/query [{agent_name, version}, ...]
pdAgentsApi --> wsScraperOrchestrator: [AgentConfiguration, ...]
wsScraperOrchestrator -> wsCrawlerEngine: setup_chromium_driver()
loop for each URL in links_to_follow (up to max_pages):
  wsCrawlerEngine -> merchantWebsites: GET <url> (Selenium/Chromium)
  merchantWebsites --> wsCrawlerEngine: HTML page
  wsCrawlerEngine --> wsScraperOrchestrator: {content, links}
  wsScraperOrchestrator -> openAi: filter_links agent prompt
  openAi --> wsScraperOrchestrator: filtered_links
  wsScraperOrchestrator -> openAi: clean_text agent prompt
  openAi --> wsScraperOrchestrator: cleaned_text
  wsScraperOrchestrator -> openAi: quality_content agent prompt
  openAi --> wsScraperOrchestrator: is_good_content (bool)
  opt is_good_content == true:
    wsScraperOrchestrator -> openAi: extract_usps agent prompt
    openAi --> wsScraperOrchestrator: page_usps
    opt page > 1:
      wsScraperOrchestrator -> openAi: manage_duplicates agent prompt
      openAi --> wsScraperOrchestrator: combined_usps
    end
  end
end
wsScraperOrchestrator --> wsScraperApi: {scraper_results, top10_usps, global_cost}
wsScraperApi --> fgApiClient: HTTP 200 JSON response
```

## Related

- Architecture dynamic view: `dynamic-continuumWebScraperService`
- Related flows: [Multi-Step Content Generation](multi-step-content-generation.md), [Prompt and Guideline Retrieval](prompt-and-guideline-retrieval.md)
