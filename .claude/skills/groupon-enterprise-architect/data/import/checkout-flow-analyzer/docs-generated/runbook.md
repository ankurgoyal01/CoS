---
service: "checkout-flow-analyzer"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/api/debug-store` | http GET | Manual | — |
| `/api/csv-time-windows` | http GET | Manual | — |

> No automated health check or liveness probe is configured in the codebase. The `/api/debug-store` endpoint returns the selected time window ID and available time windows, which can be used to verify the application and filesystem are functioning correctly.

## Monitoring

### Metrics

> No evidence found in codebase. No Prometheus, Datadog, or CloudWatch metric instrumentation is present. The application uses `console.log` and `console.error` for structured-ish server-side logging prefixed with the handler name (e.g., `[CSV-DATA API]`, `[CONVERSION-RATE API]`).

### Dashboards

> No evidence found in codebase.

### Alerts

> No evidence found in codebase.

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. For local/manual deployment, restart using `pnpm start` (production) or `pnpm dev` (development).

### Scale Up / Down

> Not applicable. This is an internal tool with no auto-scaling configuration.

### Add or Update Log Data Files

1. Obtain CSV/ZIP log exports from the appropriate source (e.g., Kibana).
2. Ensure the filename matches the required pattern: `{type}(_logs)?_us_YYYYMMDD_HHMMSS_YYYYMMDD_HHMMSS.csv[.zip]`
   - Valid types: `pwa`, `orders`, `proxy`, `lazlo`, `bcookie_summary`
   - Example: `pwa_logs_us_20250510_080000_20250511_080000.csv.zip`
3. Place the file in `src/assets/data-files/`.
4. The File Storage Adapter auto-discovers files on the next request — no restart required.
5. A time window is considered complete when all four main types (`pwa`, `orders`, `proxy`, `lazlo`) are present for the same date range.

## Troubleshooting

### No Time Windows Appear in the UI
- **Symptoms**: The time window selector shows no options; `/api/csv-time-windows` returns an empty array.
- **Cause**: No CSV/ZIP files are present in `src/assets/data-files/`, or the files do not match the expected filename pattern.
- **Resolution**: Verify files exist in the directory. Check that filenames conform to the pattern using the `FileStorage.parseFileName` regex: `^(pwa|orders|proxy|lazlo|bcookie_summary)(_logs)?_us_(\d{8})_(\d{6})_(\d{8})_(\d{6})\.csv(\.zip)?$`.

### Session Data Fails to Load (500 error on `/api/csv-data`)
- **Symptoms**: Session list shows an error; server logs contain `[CSV-DATA API] Unhandled error`.
- **Cause**: The selected CSV/ZIP file is corrupt, uses an unsupported compression format, or the file was deleted after discovery.
- **Resolution**: Check server logs for the specific decompression error. Replace or re-export the affected file. The File Storage Adapter tries adm-zip, then gunzip, then zlib unzip, then plain text — if all fail, it throws.

### Authentication Loop (Redirect to `/login` on Every Request)
- **Symptoms**: Users are redirected to `/login` immediately after signing in.
- **Cause**: `NEXTAUTH_SECRET` or `NEXTAUTH_URL` environment variable is missing or incorrect; Okta credentials (`OKTA_CLIENT_ID`, `OKTA_CLIENT_SECRET`, `OKTA_ISSUER`) are invalid.
- **Resolution**: Verify all five required environment variables are set. In development, set `NEXT_PUBLIC_AUTH_DEV_MODE=true` to bypass Okta.

### Conversion Rate Returns Unexpected Values
- **Symptoms**: `viewToAttemptRate` or `viewToSuccessRate` are 0 or 100%.
- **Cause**: The PWA log file for the selected time window is missing, or the event names in the log do not contain the expected substrings (`CHECKOUT-VIEW`, `CHECKOUT-ATTEMPT`, `CHECKOUT-FINISHED`).
- **Resolution**: Verify the PWA file exists for the time window (`/api/csv-files`). Inspect a few raw rows from the file to confirm event name column values.

### Large Files Cause High Memory Usage or Timeout
- **Symptoms**: API requests for busy time windows are slow or result in gateway timeouts.
- **Cause**: Raw PWA log files for high-traffic windows are large; in-memory filtering and parsing of the full file is CPU and memory intensive.
- **Resolution**: Prefer the `bcookie_summary` pre-aggregated file when available (the `/api/csv-data` route does this automatically unless `useRawData=true` is passed). If summary files are not available, generate them externally and place them in the data-files directory.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Application completely inaccessible (auth broken, crashes on startup) | Immediate | Checkout Engineering on-call |
| P2 | Key feature degraded (time windows not loading, session data errors) | 30 min | Checkout Engineering |
| P3 | Minor UI issue, single time window corrupt | Next business day | Checkout Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Okta Identity Cloud | Sign-in attempt: if Okta is unreachable, sign-in page displays an auth error | None — unauthenticated access is blocked |
| `src/assets/data-files/` filesystem | `GET /api/csv-time-windows` returns empty array if directory is unreadable | None — application cannot function without data files |
