# LeadGen Service Troubleshooting

- **Apify runs fail or return empty results**  
  - Validate Google Places inputs and Apify task parameters; retry with smaller scopes.

- **AIDG enrichment unavailable (`inferPDS` / `merchantQuality`)**  
  - Check Encore wrapper status if Clay is fronting the calls; otherwise hit the APIs directly and fall back to cached enrichment.

- **Outreach failures (Bird/Mailgun)**  
  - Inspect provider dashboards for rate limits or blocks; switch to the alternate provider until delivery recovers.

- **CRM sync errors**  
  - Review Salesforce API limits and error payloads; pause writes and replay when limits reset.

- **n8n workflow backlog**  
  - Restart stuck executions, scale workers, and verify `leadGenDb` connectivity.
