---
service: "akamai"
title: "WAF and Bot Management Security Enforcement"
generated: "2026-03-03"
type: flow
flow_name: "waf-bot-management-enforcement"
flow_type: synchronous
trigger: "Inbound HTTP/HTTPS request to Groupon consumer or merchant platform URL"
participants:
  - "akamai"
  - "continuumAkamaiServiceMetadata"
architecture_ref: "components-continuum-akamai-service-metadata"
---

# WAF and Bot Management Security Enforcement

## Summary

Every inbound HTTP/HTTPS request to Groupon's consumer or merchant platforms passes through the Akamai edge network, where WAF rules and bot management policies are evaluated before the request is forwarded to Groupon's origin infrastructure. The Akamai edge enforces security controls defined by Groupon's Cyber Security team via the Akamai Security Center, blocking or challenging requests that match threat signatures, malicious bot patterns, or WAF policy violations. The outcome of each request — pass, block, or challenge — is recorded in Akamai's security analytics, accessible via the dashboards referenced in `akamaiSecurityDashboards`.

## Trigger

- **Type**: api-call (inbound HTTP/HTTPS)
- **Source**: End-user browser, mobile app, or automated client attempting to access a Groupon consumer or merchant platform URL
- **Frequency**: Per-request (continuous, real-time)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Akamai Edge Network | Intercepts all inbound traffic; evaluates WAF and bot management policies; forwards approved traffic to origin | `akamai` |
| Akamai Security Center (control plane) | Provides the WAF rule set and bot management policy configuration managed by the Cyber Security team | `akamai` |
| Groupon Origin Infrastructure | Receives forwarded requests that pass Akamai security checks | Continuum platform (not directly modeled in this service) |
| Akamai Service Metadata (`continuumAkamaiServiceMetadata`) | Holds Groupon's ownership, contact, and dashboard configuration for managing the Akamai security platform | `continuumAkamaiServiceMetadata` |

## Steps

1. **Receives inbound request**: End-user or automated client sends an HTTP/HTTPS request targeting a Groupon consumer or merchant URL.
   - From: `end-user / client`
   - To: `akamai` (Akamai edge node, closest PoP)
   - Protocol: HTTPS

2. **Evaluates WAF rules**: Akamai edge applies Web Application Firewall rules (config selector `85902`) to the request — checking for SQL injection, XSS, and other OWASP-class threats.
   - From: `akamai` (edge)
   - To: `akamai` (WAF rule engine, internal)
   - Protocol: internal

3. **Evaluates bot management policy**: Akamai edge classifies the request's user-agent and traffic pattern against bot management policy to distinguish legitimate browsers and crawlers from malicious bots.
   - From: `akamai` (edge)
   - To: `akamai` (bot management engine, internal)
   - Protocol: internal

4. **Enforces security decision**: Based on WAF and bot management evaluation, Akamai either blocks the request (returns 403), issues a CAPTCHA challenge, or forwards the request to the Groupon origin.
   - From: `akamai` (edge)
   - To: Groupon origin (pass) or end-user (block/challenge)
   - Protocol: HTTPS

5. **Records analytics event**: Akamai logs the request outcome (allowed, blocked, challenged) to security analytics, visible in the Akamai Security Center dashboards monitored by the Cyber Security team.
   - From: `akamai` (edge)
   - To: `akamai` (Security Center analytics)
   - Protocol: internal

6. **Cyber Security team reviews dashboards**: The Cyber Security team accesses `akamaiSecurityDashboards` (three Security Center dashboard URLs) to monitor WAF and bot management activity, tune rules, and investigate incidents.
   - From: Cyber Security team (`c_anemeth`, `c_jdiaz`, `c_wkura`, `c_pnowicki`, `sbhatt`)
   - To: `akamai` (Security Center at `https://control.akamai.com`)
   - Protocol: HTTPS (browser)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Legitimate traffic matched by WAF rule (false positive) | Cyber Security team reviews Security Center analytics and adds an exception rule or tunes rule sensitivity | Affected traffic is unblocked; WAF rule adjusted to reduce false-positive rate |
| Legitimate bot (SEO crawler, partner) flagged as malicious | Cyber Security team whitelists user-agent or IP in bot management policy | Bot is reclassified as known-good and allowed through |
| Akamai edge node unavailable | Akamai PoP failover to next-nearest edge node (managed by Akamai) | Request is handled transparently by another PoP; no Groupon intervention required |
| Akamai control plane (`control.akamai.com`) unavailable | Existing edge policies remain enforced from cache; no new policy changes can be applied | Security posture unchanged until control plane recovers; Cyber Security team notified via `infosec@groupon.com` |

## Sequence Diagram

```
Client -> Akamai Edge: HTTPS request (consumer or merchant URL)
Akamai Edge -> WAF Engine: Evaluate request against WAF rules (config 85902)
WAF Engine --> Akamai Edge: WAF decision (pass / block)
Akamai Edge -> Bot Management Engine: Classify traffic (bot vs. human)
Bot Management Engine --> Akamai Edge: Classification decision (allow / challenge / block)
Akamai Edge -> Groupon Origin: Forward approved request (HTTPS)
Akamai Edge -> Akamai Security Analytics: Log request outcome
Akamai Edge --> Client: Response (from origin, or 403/CAPTCHA if blocked)
Cyber Security Team -> Akamai Security Center: Review dashboards (akamaiSecurityDashboards)
```

## Related

- Architecture component view: `components-continuum-akamai-service-metadata`
- Related flows: [Akamai CDN Operations Flow](../../akamai-cdn/docs-generated/flows/cdn-operations.md) — CDN delivery configuration managed by the `akamai-cdn` service uses the same Akamai platform
- Owners Manual: `https://groupondev.atlassian.net/wiki/spaces/SECURITY/pages/80750706765/Akamai+Owners+Manual`
