---
service: "optimize-suite"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `.service.yml` status endpoint | disabled | — | — |
| Wavefront dashboard | metrics | Continuous | — |
| Jenkins build badge | build-status | Per-commit | — |

> The `.service.yml` explicitly sets `status_endpoint.disabled: true` because Optimize Suite is a browser-side library with no HTTP server. Health is assessed via Wavefront metrics on the analytics tracking pipeline.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `uncaught-error` event volume | counter | Number of uncaught JavaScript errors captured by ErrorCatcher across instrumented pages | Spike relative to baseline |
| `finch-experiment` event volume | counter | Number of experiment variant assignments tracked per session | Significant drop may indicate Birdcage config delivery failure |
| `bloodhound` impression volume | counter | Number of widget impression events submitted to TrackingHub | Drop may indicate Bloodhound initialization failure |
| `sanity-check-failure` event volume | counter | Number of SanityCheck invariant failures | Any non-zero value warrants investigation |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Optimize Suite Primary | Wavefront | `https://groupon.wavefront.com/u/QCTzqnnz0g` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Tracking error spike | `uncaught-error` rate exceeds 3x baseline | warning | Check recent deploy of optimize-suite or host application; verify ErrorCatcher is not capturing expected framework errors |
| Experiment tracking drop | `finch-experiment` event volume drops >50% | warning | Verify Birdcage config is being served correctly by Optimize I-Tier Bindings; check Layout Service deploy |
| Jenkins build failure | Build on `main` fails | warning | Check Jenkinsfile, run `npm cit` locally, review failing test output in Cloud Jenkins |

- **Emergency contact**: optimize-alerts@groupon.com
- **PagerDuty**: `https://groupon.pagerduty.com/service-directory/P0Q2SV8`
- **Slack channel**: `CF9N1RDL6`

## Common Operations

### Release a New Version
1. Merge feature/fix branches into `main` using conventional commit format (required by `nlm`).
2. Jenkins pipeline automatically runs tests and executes `npx nlm release --commit`.
3. Verify the new version tag appears in the GitHub repository.
4. Open a pull request in Layout Service to bump `"optimize-suite": "^X.Y.Z"` in `package.json`.
5. Merge the Layout Service PR to deploy to production.

### Test a Change Locally
1. Clone the repo and run `npm install`.
2. Make changes, then run `npm run build` to produce `build/optimize-suite.js`.
3. In Layout Service, run `rm -rf $LS/node_modules/optimize-suite && ln -nsf $OS $LS/node_modules/optimize-suite`.
4. Run `npm run assets` in Layout Service to bundle the linked version.
5. Point an I-Tier app at local Layout Service using `remoteLayout.baseUrl: "http://localhost:3080/layout"`.

### Run Tests
```bash
npm run test        # lint + build + unit tests
npm run test:unit   # unit tests only (c8 + mocha)
npm run lint        # ESLint checks
npm run build       # Webpack production build
```

### Scale Up / Down

> Not applicable. Optimize Suite is a browser-side library with no server infrastructure.

### Database Operations

> Not applicable. Optimize Suite owns no server-side database.

## Troubleshooting

### Bloodhound Not Tracking Impressions
- **Symptoms**: No `optimize-bh-impression` DOM events; TrackingHub receives no `bloodhound` impression events.
- **Cause**: `initBloodhound()` not called; Bloodhound paused via `bloodhoundWait()`; page DOM elements missing `data-bhw` or `data-bhc` attributes; Bloodhound constructor threw an error silently.
- **Resolution**: Verify `window.OptimizeSuite.initBloodhound()` is called after DOM is ready. Check `window.OptimizeSuite.isBloodhoundPaused()`. Enable `devMode` (set `optimize-inspectors` cookie) to surface errors. Inspect elements for `data-bhw` attributes.

### Finch Experiments Not Running
- **Symptoms**: No `finch-experiment` events in TrackingHub; experiment variants not applied.
- **Cause**: `config.finch.config` is empty or missing (Birdcage config not delivered by Optimize I-Tier Bindings); experiment is guarded out; Finch initialization failed.
- **Resolution**: Check `window.OptimizeSuite.config.finch.config` is populated. Check Finch Portal for `guarded` entries. Verify Optimize I-Tier Bindings is running and able to reach Birdcage. Enable `finch.debug = true` in dev config.

### Duplicate Cookie Issues
- **Symptoms**: Session/browser IDs differ across requests; tracking events have inconsistent user identity.
- **Cause**: Multiple `s` or `b` cookies set at different domain scopes.
- **Resolution**: Cookie Monster (`cookieMonster()` in standalone bundle) automatically removes duplicate cookies on page load. Verify `window.Cookie` global is initialized (requires standalone bundle or Layout Service initialization order). Check `document.head.dataset.domain` is set correctly.

### Google Analytics Not Firing
- **Symptoms**: No GA hits in GA debug view; no `ga` function on `window`.
- **Cause**: `config.googleAnalyticsTrackingId` not provided; `Cookie.allows('functional')` returns false (GDPR cookie consent not given).
- **Resolution**: Verify `config.googleAnalyticsTrackingId` is set in the config passed to `init()`. Check cookie consent state — GA is only initialized when functional cookies are allowed.

### uncaught-error Spike
- **Symptoms**: High volume of `uncaught-error` events in TrackingHub; Wavefront alert fires.
- **Cause**: Recent deploy of optimize-suite or host application introduced a JavaScript error; third-party script on the page throwing errors captured by ErrorCatcher.
- **Resolution**: Check `page_url` and `page_type` fields in error events to identify affected pages. Cross-reference with recent deploys. If errors are from third-party scripts, add `doNotTrack: true` to error objects to suppress ErrorCatcher capture.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Tracking completely stopped (no events received) | Immediate | Optimize team via PagerDuty `P0Q2SV8`; optimize-alerts@groupon.com |
| P2 | Partial tracking failure (specific event type or page type) | 30 min | Optimize team Slack `CF9N1RDL6` |
| P3 | Minor impact (elevated error rate, single experiment issue) | Next business day | Create ticket via `https://jira.groupondev.com/secure/CreateIssue!default.jspa` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Layout Service (delivery) | Check Layout Service deploy status; verify `optimize-suite` version in LS `package.json` | Previous version continues to run in browsers until LS is updated |
| Birdcage (experiment config) | Check Birdcage service health at `http://birdcage.snc1.`; verify Optimize I-Tier Bindings config injection | Finch initialization skipped if `config.finch` is missing/empty; pages still load but without experiments |
| Google Analytics | GA debug extension in browser; check network requests to `www.google-analytics.com` | GA failures are silently ignored; tracking continues through TrackingHub |
| TrackingHub (npm library) | No separate health endpoint; verify `window.OptimizeSuite.TrackingHub` is initialized | Beagle buffer persists unsent events; flushes when connectivity returns |
