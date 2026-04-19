---
service: "sem-blacklist-service"
title: "Google Sheets Blacklist Refresh"
generated: "2026-03-03"
type: flow
flow_name: "gdoc-blacklist-refresh"
flow_type: scheduled
trigger: "Quartz job (GDocRefreshBlacklistJob)"
participants:
  - "continuumSemBlacklistService"
  - "continuumSemBlacklistPostgres"
architecture_ref: "components-sem-blacklist-components"
---

# Google Sheets Blacklist Refresh

## Summary

The SEM Blacklist Service periodically refreshes PLA (Product Listing Ads) denylist entries by reading source data from Google Sheets. A Quartz job (`GDocRefreshBlacklistJob`) fires on a configured schedule, reads blacklist rows from the configured PLA Google Sheets workbook, and performs a full transactional replacement of the current active PLA blacklist in the database. Entries present in the sheet but not in the database are inserted; entries in the database that are no longer in the sheet are soft-deleted. This ensures the database remains synchronized with the authoritative spreadsheet source.

## Trigger

- **Type**: schedule (Quartz job)
- **Source**: Quartz scheduler (`GDocRefreshBlacklistJob`) running on a configured cron schedule
- **Frequency**: Scheduled (interval configured in Quartz/JTier YAML config)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Fires the job on schedule | `continuumSemBlacklistService` (`gdocRefreshJob`) |
| GDocRefreshBlacklistJob | Entry point — retrieves store from scheduler context, checks meta config, triggers refresh | `continuumSemBlacklistService` (`gdocRefreshJob`) |
| GDocBlacklistStore | Orchestrates meta-config loading and PLA blacklist refresh | `continuumSemBlacklistService` (`gdocBlacklistStore`) |
| GoogleDocsClient | Google Sheets API client — reads meta-sheet and blacklist sheets | `continuumSemBlacklistService` (`gdocClient`) |
| Google Sheets API | External — stores the PLA blacklist spreadsheets | `googleSheetsApi` (external stub) |
| RawBlacklistDAO | Executes transactional full refresh in PostgreSQL | `continuumSemBlacklistService` (`blacklistDao`) |
| SEM Blacklist Postgres | Stores the refreshed denylist entries | `continuumSemBlacklistPostgres` |

## Steps

1. **Quartz job fires**: `GDocRefreshBlacklistJob.execute()` is called on schedule. Retrieves `GDocBlacklistStore` from the Quartz scheduler context.
   - From: Quartz Scheduler
   - To: `gdocRefreshJob`
   - Protocol: direct (Quartz `Job.execute`)

2. **Loads meta configuration**: `GDocBlacklistStore.loadMetaConfig()` calls `GoogleDocsClient.loadMetaSheet()`, which reads the meta sheet (`Countries` tab, columns A:D) from the spreadsheet identified by `gdocMeta`. The meta sheet maps (country, program, channel) tuples to Google Sheet IDs. A `Map<String, String>` of `country_program_channel → sheetId` is returned. If the meta map is empty, the job logs `BlacklistRefreshError: Meta Google Doc is empty` and aborts.
   - From: `gdocRefreshJob` → `gdocBlacklistStore` → `gdocClient`
   - To: Google Sheets API
   - Protocol: HTTPS / Google Sheets API v4

3. **Reads PLA deal blacklist sheet**: `GDocBlacklistStore.refreshPlaBlacklists()` calls `GoogleDocsClient.loadBlacklistSheet(plaGdoc, plaUsGDocDealSheet)` which reads columns A:E from the specified sheet. Each row is converted to a `GdocBlacklistRow`. Client type is `pla-deal`.
   - From: `gdocClient`
   - To: Google Sheets API
   - Protocol: HTTPS / Google Sheets API v4

4. **Reads PLA deal option blacklist sheet**: Repeats step 3 for `plaUsGDocDealOptionSheet`. Client type is `pla-deal-option`.
   - From: `gdocClient`
   - To: Google Sheets API
   - Protocol: HTTPS / Google Sheets API v4

5. **Converts rows to BlacklistEntity objects**: `GDocBlacklistStore.convert()` maps each `GdocBlacklistRow` to a `BlacklistEntity` with `searchEngine = ALL`, `countryCode = us`, and `brandBlacklistType = NON`.
   - From: `gdocBlacklistStore`
   - To: `gdocBlacklistStore`
   - Protocol: direct

6. **Executes transactional full refresh**: `RawBlacklistDAO.refreshRawBlacklist(newEntries, client, "us", "gdocUser", eventDate)` performs within a single transaction:
   - Fetches current active entries for the client/country combination.
   - Computes set intersection (entries to keep) and set difference (entries to remove).
   - Calls `insertAll(newEntries)` to add new or reactivate returning entries.
   - Calls `deletePrevious(removed, "gdocUser", eventDate)` to soft-delete entries no longer in the sheet.
   - From: `blacklistDao`
   - To: `continuumSemBlacklistPostgres`
   - Protocol: JDBC / SQL (transactional)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Meta sheet is empty or returns null | Job logs `BlacklistRefreshError: Meta Google Doc is empty` and returns early | No refresh performed; existing DB entries unchanged |
| Google Sheets API IOException | Caught in `GDocRefreshBlacklistJob`; logged as `BlacklistRefreshError` | Refresh aborted; retried on next Quartz schedule |
| SchedulerException in job context retrieval | Logged as `BlacklistRefreshError` | Job does not run; retried on next Quartz schedule |
| Row parsing error (IndexOutOfBoundsException) | Logged by `GoogleDocsClient` as `end of blacklist doc reached`; partial results used | Rows processed up to the point of error |
| Database transaction failure | JDBI rolls back transaction; exception propagates to job | No partial state written; retried on next schedule |

## Sequence Diagram

```
QuartzScheduler -> GDocRefreshBlacklistJob: execute()
GDocRefreshBlacklistJob -> GDocBlacklistStore: loadMetaConfig()
GDocBlacklistStore -> GoogleDocsClient: loadMetaSheet()
GoogleDocsClient -> GoogleSheetsAPI: GET spreadsheet/{gdocMeta}/values/Countries!A:D
GoogleSheetsAPI --> GoogleDocsClient: meta rows
GoogleDocsClient --> GDocBlacklistStore: List<List<Object>>
GDocBlacklistStore --> GDocRefreshBlacklistJob: Map<country_program_channel, sheetId>
GDocRefreshBlacklistJob -> GDocBlacklistStore: refreshGDocBlacklists()
GDocBlacklistStore -> GoogleDocsClient: loadBlacklistSheet(plaGdoc, plaUsGDocDealSheet)
GoogleDocsClient -> GoogleSheetsAPI: GET spreadsheet/{plaGdoc}/values/{sheet}!A:E
GoogleSheetsAPI --> GoogleDocsClient: blacklist rows
GoogleDocsClient --> GDocBlacklistStore: List<GdocBlacklistRow>
GDocBlacklistStore -> GoogleDocsClient: loadBlacklistSheet(plaGdoc, plaUsGDocDealOptionSheet)
GoogleDocsClient -> GoogleSheetsAPI: GET spreadsheet/{plaGdoc}/values/{sheet}!A:E
GoogleSheetsAPI --> GoogleDocsClient: blacklist rows
GoogleDocsClient --> GDocBlacklistStore: List<GdocBlacklistRow>
GDocBlacklistStore -> RawBlacklistDAO: refreshRawBlacklist(entities, "pla-deal", "us", ...)
RawBlacklistDAO -> sem_raw_blacklist: BEGIN TRANSACTION
RawBlacklistDAO -> sem_raw_blacklist: SELECT active entries
RawBlacklistDAO -> sem_raw_blacklist: INSERT new entries (conditional)
RawBlacklistDAO -> sem_raw_blacklist: UPDATE removed entries (active=FALSE)
RawBlacklistDAO -> sem_raw_blacklist: COMMIT
```

## Related

- Architecture dynamic view: `components-sem-blacklist-components`
- Related flows: [Asana Task Processing](asana-task-processing.md), [Flows Index](index.md)
