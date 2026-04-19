---
service: "argus"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

Argus is a batch CLI job with no persistent process. Health is assessed by the success or failure of Jenkins pipeline stages.

| Mechanism | Type | Check |
|-----------|------|-------|
| Jenkins stage status | CI pipeline | Each `UPDATE-ALERTS-*` stage passes if Gradle exits 0 and all Wavefront API calls succeed |
| `SHOW-ALERT-SUMMARY` stage | Scheduled CI job | Timer-triggered stage prints top-firing alerts; failure indicates Wavefront API connectivity issues |
| `./gradlew build` | CI build check | Validates non-alert Groovy code compiles correctly |

## Monitoring

### Metrics

Argus does not emit metrics of its own. It manages the metrics and alerts for other services. The Wavefront alerts it provisions monitor the following metric types for covered services:

| Metric Type | Wavefront Metric | Alert Tag Pattern |
|-------------|-----------------|------------------|
| HTTP 5XX error percentage | `http.in.total-time.count` (filtered by `http.in.status="5*"`) | `argus.prod.<colo>.sma.*` |
| HTTP 4XX RPS | `http.in.total-time.count` (filtered by `http.in.status="4*"`) | `argus.prod.<colo>.*` |
| HTTP response time (p99) | `http.in.total-time.p99`, `http.in.app-time.p99` | `argus.prod.<colo>.*` |
| JVM exceptions | `vertx.error.value.sum` | `argus.prod.dub1.sma.api_lazlo` |
| Rate limiting (HTTP 420) | `http.in.total-time.count` (filtered by `http.in.status="420"`) | `argus.prod.dub1.api_proxy` |
| Host-level error percentage | `http.in.total-time.count` (per-host source filter) | `argus.prod.dub1.sma.api_lazlo_host` |
| Envoy upstream errors (HB) | `envoy.cluster.api-lazlo--<colo>.*` | `argus.prod.dub1.api_lazlo` |
| Database connection count | `http.in.*` (Telegraf-sourced) | `argus.prod.dub1.clientId` |
| Message bus counter | Wavefront SMA counter | `argus.prod.dub1.regconsentlog` |

### Dashboards

| Dashboard | Tool | Description |
|-----------|------|-------------|
| Wavefront dashboards (managed by Argus) | Wavefront (`https://groupon.wavefront.com`) | Service-level performance dashboards for Lazlo, Proxy, and other Continuum services |

### Alerts

Representative examples of the alerts managed by Argus (DUB1 production):

| Alert Name | Condition | Severity | `minutesToFire` |
|------------|-----------|----------|-----------------|
| `DUB1 SMA Lazlo /deals GET response 5XX error percentage` | 5XX % > 1 | WARN | 5 |
| `DUB1 SMA Lazlo /oauth./authMechanism POST response 5XX error percentage` | 5XX % > 1 | WARN | 7 |
| `DUB1 SMA API Proxy 420 rate limit` | HTTP 420 rate > 80 req/min | WARN | 5 |
| `DUB1 SMA Deckard GET Inventory Units response 5XX error percentage` | 5XX % > 1 | WARN | 5 |
| `DUB1 SMA API Lazlo java.lang.OutOfMemoryError count` | OOM error count > 1 | WARN | 5 |
| `DUB1 Lazlo HB 5xx RPS` | Envoy upstream 5XX RPS > 20 | WARN | 5 |
| `DUB1 Lazlo HB upstream-cx-connect-fail` | Connection failures > 1 | WARN | 5 |
| `DUB1 Telegraf ClientId /v2/search.json GET Response Time` | p99 > 100 ms | WARN | 5 |
| `DUB1 regconsentlog /consents POST Response Time SMA` | p99 > 300 ms | WARN | 5 |

All alerts notify via Wavefront webhooks: `webhook:UXcN0ynhr2fq7OYm`, `webhook:PjVwtl0OAgSeoSiI`, `webhook:a7cVoRyUAU5cnZyh` (or `webhook:S7zLxLD0GIq18MrB`, `webhook:v7TpmpUgS978KtZU`, `webhook:91O9gQ6tKpeKdkkx` for host-level alerts).

## Common Operations

### Add a new alert

1. Create or edit a YAML file under the appropriate `src/main/resources/alerts/<env>/` directory.
2. Add a new entry to the `alerts:` list in the file, specifying `name`, `metric`, `httpMethod` (if applicable), `minutesToFire`, `severity`, `method`, and `threshold`.
3. Commit and merge to `master`. The Jenkins `UPDATE-ALERTS-*` stage for the changed environment runs automatically.

### Update an existing alert threshold

1. Edit the relevant YAML file under `src/main/resources/alerts/<env>/`.
2. Change the `threshold` or other fields on the alert entry.
3. Commit and merge to `master`. Argus detects the difference and issues a `PUT /api/v2/alert/:id` to update the alert.

### Run alert sync manually

From a local machine with Java 1.8 and the project checked out:

```bash
# Sync a specific environment
./gradlew updateAlertsDUBProduction

# Sync all environments
./gradlew updateAll

# Show alert summary (print alerts firing > 5 times in last week)
./gradlew showAlertSummary
```

Via the Docker CI container:
```bash
docker build -f .ci/Dockerfile -t jtier-docs-ci .
docker run --entrypoint "" jtier-docs-ci ./gradlew updateAlertsDUBProduction
```

### Scale Up / Down

> Not applicable. Argus is a batch CI job. Throughput is limited only by Wavefront API rate limits.

### Database Operations

> Not applicable. Argus owns no database.

## Troubleshooting

### Alert sync fails with HTTP 4xx/5xx from Wavefront

- **Symptoms**: Jenkins stage fails; log shows `Failure: create failed <status>` or `Failure: update failed <status>`
- **Cause**: Wavefront API unavailable, authentication token expired/invalid, or malformed alert payload
- **Resolution**: Check Wavefront status page; verify auth tokens in `MainScript.groovy` are still valid; inspect the request body logged alongside the error for payload issues

### More than one alert found for a name

- **Symptoms**: `Exception: Found more than one alert with name: <name>` in CI log
- **Cause**: Duplicate alert names exist in Wavefront (possibly created manually or via a previous misrun)
- **Resolution**: Manually delete the duplicate alert in the Wavefront UI, then re-run the sync task

### Alert not being updated despite YAML changes

- **Symptoms**: `SUCCESS: Updated alert...` is not logged; no diff detected
- **Cause**: The fields that changed in YAML may not be tracked by `areAlertsDifferent()`. The method compares: `name`, `condition`, `minutes`, `target`, `severity`, `tags`, `displayExpression`, `resolveAfterMinutes`.
- **Resolution**: Verify the changed field is in the comparison list; if not, add it to `MainScript.groovy::areAlertsDifferent`

### YAML file cannot be parsed

- **Symptoms**: SnakeYAML throws a parse exception during `templateDir.eachFileRecurse`
- **Cause**: Invalid YAML syntax in an alert definition file
- **Resolution**: Validate YAML syntax locally using a YAML linter before committing

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Wavefront alerts not syncing; production monitoring blind spots | Immediate | Platform Engineering on-call |
| P2 | Subset of environments failing sync | 30 min | Platform Engineering on-call |
| P3 | Alert summary report failing (timer-triggered) | Next business day | Platform Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Wavefront API (`https://groupon.wavefront.com`) | Check Wavefront status page; attempt `curl https://groupon.wavefront.com/api/v2/alert` with Bearer token | Previous alert configuration in Wavefront remains active until next successful sync |
| Jenkins CI | Check Jenkins dashboard for agent availability | Run Gradle tasks manually from local machine |
