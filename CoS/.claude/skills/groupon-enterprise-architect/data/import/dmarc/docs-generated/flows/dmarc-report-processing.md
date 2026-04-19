---
service: "dmarc"
title: "DMARC Report Processing"
generated: "2026-03-03"
type: flow
flow_name: "dmarc-report-processing"
flow_type: batch
trigger: "Gmail message with DMARC RUA XML attachment dequeued by a worker goroutine"
participants:
  - "reportProcessor"
  - "geoIpLookup"
  - "gmailClient"
  - "logWriter"
architecture_ref: "dynamic-dmarcProcessing"
---

# DMARC Report Processing

## Summary

This flow describes the per-message processing pipeline executed by each worker goroutine. A worker receives a Gmail message with cursor metadata from `QueueMessage`, fetches and decompresses the XML attachment, parses the DMARC aggregate report according to RFC 7489, enriches each `<record>` element with country code, reverse-DNS hostname, and base domain, and emits one `JsonRecord` per record element into `QueueRecords` for the Log Writer to persist.

## Trigger

- **Type**: event (in-process channel delivery)
- **Source**: `QueueMessage` channel receives a `MessageWithCursor` from the Gmail Client goroutine
- **Frequency**: Once per unread Gmail message matching the configured query, per polling cycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Report Processor | Orchestrates attachment fetch, decompression, XML parse, and record emission | `reportProcessor` |
| Gmail Client | Provides the attachment retrieval API call | `gmailClient` |
| GeoIP Lookup | Resolves source IP to country code, reverse-DNS, and base domain | `geoIpLookup` |
| Log Writer | Receives and persists each resulting JsonRecord | `logWriter` |

## Steps

1. **Dequeue message**: Worker goroutine receives `MessageWithCursor` from `QueueMessage` channel.
   - From: `QueueMessage` channel
   - To: `reportProcessor`
   - Protocol: in-process channel

2. **Retrieve attachment**: `GetAttachment(message)` calls the Gmail API `Users.Messages.Attachments.Get` with a 10-second timeout. Handles both `application/gzip` and `application/zip` MIME types, and `multipart/mixed` payloads by iterating the `Parts` array.
   - From: `reportProcessor`
   - To: Gmail API (via `gmailClient`)
   - Protocol: HTTPS / Google Gmail API

3. **Decode base64**: The attachment data returned by the API is base64url-decoded to raw bytes.
   - From: `reportProcessor`
   - To: `reportProcessor` (in-process)
   - Protocol: in-process

4. **Decompress attachment**: Based on MIME type:
   - `application/gzip`: Decompressed with `compress/gzip.NewReader`
   - `application/zip`: Opened with `archive/zip.NewReader`; first file in the archive is extracted
   - From: `reportProcessor`
   - To: `reportProcessor` (in-process)
   - Protocol: in-process

5. **Parse DMARC XML**: `ParseDataXML` unmarshals the decompressed data into the `Feedback` struct, mapping the RFC 7489 `<feedback>` XML schema to Go types (`ReportMetadata`, `PolicyPublished`, `[]Record`).
   - From: `reportProcessor`
   - To: `reportProcessor` (in-process)
   - Protocol: in-process (stdlib `encoding/xml`)

6. **Enrich each record**: For every `<record>` in `report.Records`:
   a. Calls `lookup(geoIP, source_ip)` to get the two-letter country code from `GeoIP.dat`.
   b. `reverseLookup(source_ip)` performs a PTR DNS lookup for the reverse-DNS hostname.
   c. `hostLookup(source_ip)` calls `domainutil.Domain()` on the PTR result to extract the base domain.
   - From: `reportProcessor`
   - To: `geoIpLookup`
   - Protocol: in-process (GeoIP.dat file + DNS)

7. **Construct JsonRecord**: Assembles `JsonRecord` with `Metadata`, `Policy`, `Row` (including computed `alignment.dkim`, `alignment.spf`, `alignment.dmarc` flags derived from policy evaluation results), `Identifiers`, `AuthResults`, `CountryCode`, `MessageID`, `AttachmentID`, and `CursorValue`.
   - From: `reportProcessor`
   - To: `reportProcessor` (in-process)
   - Protocol: in-process

8. **Enqueue JsonRecord**: Each constructed `JsonRecord` is sent to `QueueRecords`.
   - From: `reportProcessor`
   - To: `logWriter` (via `QueueRecords` channel)
   - Protocol: in-process channel

9. **Serialise and write**: Log Writer marshals the `JsonRecord` to JSON and appends it as a single line to `/app/logs/dmarc_log.log` via lumberjack.
   - From: `logWriter`
   - To: filesystem
   - Protocol: file I/O

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Attachment retrieval API error | Logged (`"Unable to retrieve attachment"`); returns error | Worker skips message, logs `"No Attachment, continuing...."` |
| Unsupported MIME type | Falls through switch; returns `errors.New("no attachment found")` | Worker skips message |
| Gzip decompression error | Logged (`"Error Parsing Gzip"`); returns error | Worker skips message |
| Zip open error | Logged (`"Error Creating Zip"`); returns error | Worker skips message |
| XML unmarshal error | Logged; `ParseDataXML` returns `nil` | No records emitted for this email |
| GeoIP database nil | `lookup()` returns empty string | `country_code: ""` in output; processing continues |
| Reverse-DNS failure | `reverseLookup` / `hostLookup` return empty string | `reverse_dns` and `base_domain` fields empty; processing continues |

## Sequence Diagram

```
Worker -> QueueMessage: receive MessageWithCursor
Worker -> GmailAPI: Users.Messages.Attachments.Get(user, msgId, attachId) [10s timeout]
GmailAPI --> Worker: attachment data (base64url)
Worker -> Worker: base64url decode
Worker -> Worker: decompress (gzip or zip)
Worker -> Worker: xml.Unmarshal -> Feedback{}
loop for each <record>
  Worker -> GeoIP.dat: lookup(source_ip)
  GeoIP.dat --> Worker: country_code
  Worker -> DNS: LookupAddr(source_ip)
  DNS --> Worker: PTR record
  Worker -> Worker: construct JsonRecord
  Worker -> QueueRecords: send JsonRecord
end
LogWriter <- QueueRecords: receive JsonRecord
LogWriter -> LogFile: json.Marshal + Println
```

## Related

- Architecture dynamic view: `dynamic-dmarcProcessing`
- Related flows: [Production Polling Cycle](production-polling-cycle.md), [Staging Single-Message Run](staging-single-message-run.md)
