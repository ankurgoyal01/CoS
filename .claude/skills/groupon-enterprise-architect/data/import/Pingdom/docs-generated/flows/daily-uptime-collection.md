---
service: "pingdom"
title: "Daily Uptime Data Collection"
generated: "2026-03-03"
type: flow
flow_name: "daily-uptime-collection"
flow_type: scheduled
trigger: "Daily cron task or manual management command invocation"
participants:
  - "pingdomServicePortal"
  - "pingdomSaaSUnknown_59f16522"
  - "ein_project (ProdCAT portal)"
architecture_ref: "dynamic-pingdom-daily-uptime"
---

# Daily Uptime Data Collection

## Summary

The Daily Uptime Data Collection flow fetches uptime metrics from the Pingdom SaaS API for all Groupon service checks grouped under configured tags and persists the results to the `pingdom_logs` database table. It is triggered by the `ein_project` `add_pingdom_uptimes` task (callable via the `collect_pingdom_data` Django management command). The flow uses bulk database operations and rate-limiting delays to efficiently process potentially large numbers of check-day combinations without exceeding Pingdom API limits.

## Trigger

- **Type**: schedule / manual
- **Source**: Daily cron scheduler within `ein_project`, or manual invocation via `python manage.py collect_pingdom_data [--days N] [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD]`
- **Frequency**: Daily (default: yesterday's data); supports backfill over arbitrary date ranges

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `ein_project` (ProdCAT portal) | Orchestrates data collection; reads tags from settings; calls Pingdom API; writes to database | Internal to `ein_project` |
| Pingdom SaaS API | Source of uptime check results and tag-to-check-ID mappings | `pingdomSaaSUnknown_59f16522` |
| `pingdom_logs` database table | Persistence store for collected uptime records | Owned by `ein_project` |

## Steps

1. **Resolve date range**: Determines the start and end dates from command arguments or defaults to yesterday.
   - From: `collect_pingdom_data` management command
   - To: `add_pingdom_uptimes` task
   - Protocol: Direct Python function call

2. **Fetch tag-to-check-ID mapping**: Calls `PD.get_tag_to_id_mapping()` to retrieve all Pingdom check IDs grouped by tag from the Pingdom API.
   - From: `add_pingdom_uptimes`
   - To: Pingdom SaaS API (`https://api.pingdom.com/api/2.1/checks`)
   - Protocol: HTTPS REST

3. **Load configured tags**: Reads the `pingdom_tags` Setting from the database to determine which tags to process.
   - From: `add_pingdom_uptimes`
   - To: `ein_project` database (Settings table)
   - Protocol: Django ORM

4. **Pre-filter existing records**: Issues a single bulk query against `pingdom_logs` to identify check-date combinations already stored, avoiding redundant API calls.
   - From: `add_pingdom_uptimes`
   - To: `pingdom_logs` database table
   - Protocol: Django ORM (bulk query)

5. **Fetch uptime per check per day**: For each check-day combination not already stored, calls `PD.get_unconfirmed_uptime_and_average_response_time(check_id, start, end)` to retrieve `uptime_percentage`, `no_latency_uptime_percentage`, and `avg_response_time`.
   - From: `add_pingdom_uptimes`
   - To: Pingdom SaaS API (`https://api.pingdom.com/api/2.1/summary.average/<check_id>`)
   - Protocol: HTTPS REST

6. **Validate and clamp values**: Validates returned values as floats and clamps to `[0.0, 100.0]` for uptime percentages and `[0.0, ∞)` for response times.
   - From: `add_pingdom_uptimes`
   - To: in-memory validation
   - Protocol: Direct

7. **Bulk insert records**: Accumulates validated records into batches of 50 and writes via `PingdomUptime.objects.bulk_create(records, ignore_conflicts=True)`. Falls back to individual saves if bulk create fails.
   - From: `add_pingdom_uptimes`
   - To: `pingdom_logs` database table
   - Protocol: Django ORM (bulk_create)

8. **Apply rate-limit delay**: Inserts a 0.1-second sleep between each batch of 50 records to respect Pingdom API rate limits.
   - From: `add_pingdom_uptimes`
   - To: (wait)
   - Protocol: Direct

9. **Return execution metrics**: Reports counts of checks processed, succeeded, skipped, and failed, plus total API calls and execution time.
   - From: `add_pingdom_uptimes`
   - To: `collect_pingdom_data` management command (stdout)
   - Protocol: Direct Python return value

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pingdom API returns `None` for a check | Logs warning; increments `checks_failed` counter; continues loop | Check skipped for that day; gap in `pingdom_logs` |
| Pingdom API raises exception (timeout, connection error) | Logs error with traceback; increments `checks_failed`; continues | Check skipped for that day |
| Bulk create fails | Falls back to individual `record.save()` calls; tracks successes, skips (IntegrityError), and failures | Partial inserts possible; integrity-error duplicates counted as skipped |
| `pingdom_tags` Setting not found | Raises `ObjectDoesNotExist`; returns `status: "error"` | No data collected; error logged |
| Invalid date range (`start > end`) | Logs warning; sets `end = start` | Single day collected |

## Sequence Diagram

```
collect_pingdom_data -> add_pingdom_uptimes: invoke(start, end)
add_pingdom_uptimes -> PingdomSaaSAPI: GET /checks (tag-to-ID mapping)
PingdomSaaSAPI --> add_pingdom_uptimes: {tag: [check_ids]}
add_pingdom_uptimes -> SettingsDB: SELECT value WHERE name='pingdom_tags'
SettingsDB --> add_pingdom_uptimes: comma-separated tag list
add_pingdom_uptimes -> pingdom_logs: SELECT check_id, date WHERE date IN [start..end]
pingdom_logs --> add_pingdom_uptimes: set of existing (check_id, date) pairs
loop for each check-day not in existing set
  add_pingdom_uptimes -> PingdomSaaSAPI: GET /summary.average/<check_id>?from=&to=
  PingdomSaaSAPI --> add_pingdom_uptimes: {uptime, no_latency_uptime, avg_response_time}
  add_pingdom_uptimes -> add_pingdom_uptimes: validate and clamp values
  add_pingdom_uptimes -> pingdom_logs: bulk_create(batch of 50, ignore_conflicts=True)
end
add_pingdom_uptimes --> collect_pingdom_data: {status, checks_processed, checks_succeeded, ...}
```

## Related

- Architecture dynamic view: `dynamic-pingdom-daily-uptime`
- Related flows: [Uptime Alert Evaluation](uptime-alert-evaluation.md)
