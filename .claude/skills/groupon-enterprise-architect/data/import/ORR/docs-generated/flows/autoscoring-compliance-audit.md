---
service: "ORR"
title: "Autoscoring Compliance Audit"
generated: "2026-03-03"
type: flow
flow_name: "autoscoring-compliance-audit"
flow_type: synchronous
trigger: "Operator invokes autoscore.sh with no arguments"
participants:
  - "continuumOrrAuditToolkit"
  - "servicePortal"
architecture_ref: "dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow"
---

# Autoscoring Compliance Audit

## Summary

This flow queries Service Portal to identify all registered services that have ORR autoscoring disabled. It retrieves the full list of services, then for each service checks the ORR `autoscoring_enabled` attribute. Services where autoscoring is `false` and lifecycle is `Live` are printed in a formatted table. This report helps the ORR program identify service teams that have opted out of automated readiness scoring and may need follow-up.

## Trigger

- **Type**: manual
- **Source**: Operator runs `./autoscore.sh` on a host with VPN access to `http://service-portal-vip.snc1`
- **Frequency**: On demand, as part of ORR compliance reviews

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `autoscore.sh` (part of `continuumOrrAuditToolkit`) | Script executor | `continuumOrrAuditToolkit` |
| `servicePortal` | Provides service list and per-service ORR attributes | `servicePortal` |

## Steps

1. **Check jq installed**: Verifies `jq` is available via `which jq`; exits with install instructions if missing.
   - From: `autoscore.sh`
   - To: OS
   - Protocol: shell

2. **Fetch all service names**: Issues `GET http://service-portal-vip.snc1/services.json` with the `GRPN-Client-ID: tdo-coea-automation` header and parses the JSON array to extract all service name strings.
   - From: `autoscore.sh`
   - To: `servicePortal`
   - Protocol: HTTP REST + jq

3. **Check autoscoring per service**: For each service name, issues `GET http://service-portal-vip.snc1/api/v2/services/<svc>?include_orr=true` and extracts `.data.operational_readiness_review.autoscoring_enabled` via jq.
   - From: `autoscore.sh`
   - To: `servicePortal`
   - Protocol: HTTP REST + jq

4. **Filter: autoscoring disabled**: If `autoscoring_enabled` is `false`, proceeds to check the service lifecycle.
   - From: `autoscore.sh`
   - To: in-memory comparison
   - Protocol: Bash conditional

5. **Fetch service lifecycle**: Issues `GET http://service-portal-vip.snc1/api/v1/services/<svc>/attributes/lifecycle` and extracts the `.value` field. Substitutes `MISSING` for null values; replaces spaces with underscores.
   - From: `autoscore.sh`
   - To: `servicePortal`
   - Protocol: HTTP REST + jq + sed

6. **Filter: lifecycle is Live**: Only services where lifecycle equals `Live` are printed.
   - From: `autoscore.sh`
   - To: in-memory comparison
   - Protocol: Bash conditional

7. **Print result row**: Formats and prints `<svc_name> <lifecycle> <autoscoring>` to stdout using `awk` column alignment.
   - From: `autoscore.sh`
   - To: stdout
   - Protocol: awk printf

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| jq not installed | `which jq` returns non-zero | Script exits with install instructions |
| Service Portal unreachable | `curl -sX GET` returns empty JSON | `jq -r '.[]'` produces empty array; loop does not execute; output is blank |
| Individual service API call fails | jq parses empty response | `autoscoring` variable is empty string; not equal to `"false"`, so service is skipped |

## Sequence Diagram

```
Operator -> autoscore.sh: ./autoscore.sh
autoscore.sh -> OS: which jq
autoscore.sh -> servicePortal: GET /services.json (GRPN-Client-ID: tdo-coea-automation)
servicePortal --> autoscore.sh: ["svc-a", "svc-b", ...]
loop for each service name
  autoscore.sh -> servicePortal: GET /api/v2/services/<svc>?include_orr=true
  servicePortal --> autoscore.sh: { autoscoring_enabled: false/true }
  alt autoscoring_enabled == false
    autoscore.sh -> servicePortal: GET /api/v1/services/<svc>/attributes/lifecycle
    servicePortal --> autoscore.sh: { value: "Live" / null }
    alt lifecycle == Live
      autoscore.sh -> stdout: <svc_name> Live false (formatted row)
    end
  end
end
autoscore.sh --> Operator: table of Live services with autoscoring disabled
```

## Related

- Architecture dynamic view: `dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow`
- Related flows: [Host Monitor Audit by Service](host-monitor-audit-by-service.md), [VIP Monitor Audit by Service](vip-monitor-audit-by-service.md)
