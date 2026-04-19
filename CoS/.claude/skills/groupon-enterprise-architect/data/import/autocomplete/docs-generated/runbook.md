---
service: "autocomplete"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /healthcheck/client/databreakers` | http | No evidence found in codebase | No evidence found in codebase |

## Monitoring

### Metrics

> No evidence found in codebase. The service uses Darwin 170.3.0 for instrumentation. Specific metric names and alert thresholds are not defined in the architecture model.

### Dashboards

> No evidence found in codebase. Dashboard links are managed externally.

### Alerts

> No evidence found in codebase. Alert configuration is managed externally by the Continuum platform operations team.

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. Standard JTier/Dropwizard restart procedures apply.

### Scale Up / Down

Operational procedures to be defined by service owner. Scaling is controlled externally by the Continuum platform deployment toolchain.

### Database Operations

The autocomplete service does not own an external database. Term file updates require rebuilding and redeploying the service artifact.

## Troubleshooting

### Autocomplete endpoint returns no recommendation cards
- **Symptoms**: `GET /suggestions/v1/autocomplete` responses contain suggestion terms but no deal/category recommendation cards
- **Cause**: DataBreakers dependency is unavailable or Hystrix circuit breaker has opened
- **Resolution**: Check `GET /healthcheck/client/databreakers`; verify DataBreakers service health; allow Hystrix circuit to close once DataBreakers recovers

### Autocomplete endpoint returns no suggestion terms from SuggestApp
- **Symptoms**: Suggestion cards are missing or sparse; only local term-based suggestions appear
- **Cause**: SuggestApp service is unavailable or Hystrix circuit breaker has opened on the `SuggestAppServiceClient`
- **Resolution**: Verify SuggestApp service health; check Hystrix dashboard for circuit state; local term fallback remains active via `LocalQueryExecutor`

### Experiment treatments not applying
- **Symptoms**: A/B test treatments or feature flag behavior is not reflected in responses
- **Cause**: Finch/Birdcage (`CardsFinchClient` or `V2FinchClient`) is unreachable
- **Resolution**: Verify Finch/Birdcage service health; service falls back to default treatment on failure

### Term files not loading
- **Symptoms**: `LocalQueryExecutor` returns empty results; service startup errors
- **Cause**: Embedded term files in `continuumAutocompleteTermFiles` are missing or malformed in the deployed artifact
- **Resolution**: Verify the deployed JAR contains the expected term file resources; redeploy if necessary

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — autocomplete entirely unavailable | Immediate | Search and Relevance Team |
| P2 | Degraded — recommendation cards missing or suggestions incomplete | 30 min | Search and Relevance Team |
| P3 | Minor impact — experiment treatments defaulting | Next business day | Search and Relevance Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| DataBreakers | `GET /healthcheck/client/databreakers` | Hystrix circuit opens; recommendation cards omitted from response |
| SuggestApp | No dedicated endpoint; inferred from Hystrix metrics | Hystrix circuit opens; SuggestApp terms omitted; local terms serve as fallback |
| Finch/Birdcage | No evidence found in codebase | Default experiment treatment applied |
| gConfigService | Archaius polling | Last-known-good configuration used |
