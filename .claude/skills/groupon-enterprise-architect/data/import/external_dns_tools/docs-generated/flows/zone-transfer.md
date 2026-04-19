---
service: "external_dns_tools"
title: "Zone Transfer to Akamai"
generated: "2026-03-03"
type: flow
flow_name: "zone-transfer"
flow_type: event-driven
trigger: "SOA serial increment detected by Akamai Zone Transfer Agent"
participants:
  - "externalDnsMasters"
  - "akamaiEdgeDns_unk_0b6c"
architecture_ref: "dynamic-externalDnsTools"
---

# Zone Transfer to Akamai

## Summary

After the BIND master servers are reloaded with updated zone files (following a successful DNS deploy), Akamai EdgeDNS Zone Transfer Agents (ZTAs) detect that the SOA serial number for one or more zones has incremented. The ZTAs then initiate a zone transfer (AXFR for full transfer or IXFR for incremental) over TCP port 53 to pull the updated zone data from the BIND masters. Once synchronized, Akamai serves the updated DNS records to all external DNS consumers worldwide. This flow is the mechanism by which zone changes actually propagate to end users.

## Trigger

- **Type**: event (SOA serial change)
- **Source**: Akamai ZTAs periodically poll the BIND masters and detect an incremented SOA serial number following a BIND reload
- **Frequency**: On-demand — triggered whenever a deploy updates the SOA serial; Akamai ZTAs continuously monitor

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| External DNS Masters (BIND) | Authoritative source — serves zone data to ZTAs on request | `externalDnsMasters` |
| Akamai EdgeDNS Zone Transfer Agents | Detects SOA serial change; initiates and receives zone transfer | `akamaiEdgeDns_unk_0b6c` |
| Akamai EdgeDNS serving layer | Distributes received zone data globally; serves public DNS queries | `akamaiEdgeDns_unk_0b6c` |

## Steps

1. **BIND reload with updated zone files**: Following a successful deploy, the BIND master servers reload and serve zone files with an incremented SOA serial number.
   - From: `externalDnsDeployTool` (deploy trigger)
   - To: `externalDnsMasters`
   - Protocol: exec (Ansible SSH `/var/tmp/roll`)

2. **ZTA detects SOA serial change**: Akamai Zone Transfer Agents query the BIND masters for the SOA record of each configured zone; they detect that the serial number has incremented since their last successful zone transfer.
   - From: `akamaiEdgeDns_unk_0b6c` (ZTA)
   - To: `externalDnsMasters`
   - Protocol: DNS SOA query (UDP/TCP 53)

3. **ZTA initiates zone transfer**: The ZTA sends an AXFR (full) or IXFR (incremental) request to the BIND master over TCP port 53.
   - From: `akamaiEdgeDns_unk_0b6c` (ZTA)
   - To: `externalDnsMasters`
   - Protocol: DNS zone transfer (AXFR/IXFR, TCP 53)

4. **BIND master serves zone data**: The BIND master responds with the complete zone file (AXFR) or incremental changes (IXFR) for each requested zone.
   - From: `externalDnsMasters`
   - To: `akamaiEdgeDns_unk_0b6c` (ZTA)
   - Protocol: DNS zone transfer (TCP 53)

5. **Akamai distributes updated zone data**: The ZTA delivers the received zone data to the Akamai EdgeDNS serving infrastructure globally.
   - From: Akamai ZTA
   - To: Akamai EdgeDNS serving nodes
   - Protocol: Akamai internal

6. **End users receive updated DNS records**: All subsequent DNS queries for Groupon's public domains return the updated records from Akamai EdgeDNS.
   - From: `akamaiEdgeDns_unk_0b6c`
   - To: End users / DNS resolvers
   - Protocol: DNS (UDP/TCP 53)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| BIND master unreachable | ZTA retries; alert `syseng_fastdns_expired_zone` fires after SOA expiry period | Akamai continues serving previous DNS records; change does not propagate |
| All ZTAs fail zone transfer | Alert `syseng_fastdns_failed_zonetransfer` fires (critical, ~6-9 min delay) | Akamai serves stale records; operator must restore BIND master connectivity |
| ZTA detects SOA serial regression | Alert `syseng_fastdns_soa_ahead` fires; ZTA refuses to transfer the zone | DNS changes blocked; operator must increment SOA serial and redeploy |
| Firewall blocks ZTA IPs | BIND master receives no zone transfer requests; `syseng_fastdns_expired_zone` fires | Same as BIND unreachable; operator must update firewall ACL on EC2 |

## Sequence Diagram

```
BIND master -> BIND master: Reload with updated named.conf and zone files (SOA serial incremented)
Akamai ZTA -> BIND master: DNS SOA query for <zone> (e.g., groupon.com)
BIND master --> Akamai ZTA: SOA response with new serial number
Akamai ZTA -> BIND master: AXFR/IXFR request (TCP 53) for <zone>
BIND master --> Akamai ZTA: Zone data (all records)
Akamai ZTA -> Akamai serving nodes: Distribute updated zone data
Akamai serving nodes --> End users: Serve updated DNS records
```

## Related

- Architecture dynamic view: `dynamic-externalDnsTools`
- Related flows: [DNS Zone Deploy](dns-deploy.md)
- Alert monitoring: see [Runbook](../runbook.md) for Akamai alert details
