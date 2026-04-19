# LeadGen Service API Reference

This doc summarizes the key external interactions modeled for LeadGen. Internal APIs are documented in the service repo.

## External dependencies

- `apify` — scrape lead candidates with `googlePlaces` backing data.
- `googlePlaces` — business lookup data supporting Apify scraping.
- `inferPDS` — AIDG enrichment (PDS inference).
- `merchantQuality` — AIDG merchant quality scoring.
- `salesForce` — create/update Accounts and attach Contacts.
- `bird` — preferred email/SMS outreach provider.
- `mailgun` — legacy email outreach fallback.
- `clay` — external lead-sourcing automation; depends on Encore wrappers for `inferPDS` and `merchantQuality`, calls `apify`/`googlePlaces` for scraping, uses `bird` for outreach, and syncs to `salesForce`.

## Notes

- Clay is modeled as an external integration point for automated lead sourcing. LeadGen service currently calls Apify and AIDG directly; Clay relies on Encore wrappers for AIDG, Apify/Google Places for sourcing, and Bird for outreach.
- Keep outbound request limits aligned with provider SLAs (Apify and Bird have rate limits; Salesforce API daily caps).
