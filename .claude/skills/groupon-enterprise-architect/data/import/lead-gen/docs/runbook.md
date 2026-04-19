# LeadGen Service Runbook

## Operational checks

- Verify `leadGenService` health/metrics (scrape queue depth, enrichment latency, outreach success rate).
- Confirm `leadGenWorkflows` (n8n) schedules are running and can persist to `leadGenDb`.
- Validate external dependencies:
  - `apify` job execution and Google Places input availability.
  - `salesForce` API limits and auth tokens.
  - `inferPDS` / `merchantQuality` availability (via Encore wrappers if routed through Clay).
  - `bird` delivery metrics; fall back to `mailgun` if needed.
  - `clay` workspace status if automation is enabled.

## Incident playbook (quick)

1) Scrape failures: check Apify run logs; retry with smaller batch; confirm Google Places inputs.  
2) Enrichment failures: confirm AIDG endpoints healthy; if using Clay, verify Encore wrapper responses.  
3) Outreach failures: check Bird status and rate limits; shift flows to Mailgun temporarily.  
4) CRM sync issues: inspect Salesforce API quota/errors; pause syncs and backfill when limits reset.  
5) Workflow backlog: scale n8n workers, clear stuck jobs, and confirm DB connectivity.
