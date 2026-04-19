---
service: "dmarc"
title: "Production Polling Cycle"
generated: "2026-03-03"
type: flow
flow_name: "production-polling-cycle"
flow_type: scheduled
trigger: "1-minute time.Ticker fires when DEPLOY_ENV is not set to staging"
participants:
  - "gmailPoller"
  - "gmailClient"
  - "reportProcessor"
  - "geoIpLookup"
  - "logWriter"
architecture_ref: "dynamic-dmarcProcessing"
---

# Production Polling Cycle

## Summary

On a one-minute interval, the DMARC service polls the Gmail API for all unread messages matching the configured query (`label: rua is:unread`), dispatches each message to a pool of worker goroutines for attachment extraction and XML parsing, enriches each parsed record with GeoIP data, and writes the resulting JSON records to the rotating application log file. The cycle completes when all pages of messages have been consumed and all worker goroutines have finished.

## Trigger

- **Type**: schedule
- **Source**: `time.Ticker` with 1-minute period, initialised by `newPoller()` at startup
- **Frequency**: Every 1 minute; next cycle begins after the current cycle completes (debounced by `p.finished` flag)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Gmail Poller | Owns the ticker; coordinates the full cycle lifecycle | `gmailPoller` |
| Gmail Client | Fetches messages and attachments from the Gmail API | `gmailClient` |
| Report Processor | Parses DMARC XML and emits JsonRecord values | `reportProcessor` |
| GeoIP Lookup | Enriches source IPs with country codes | `geoIpLookup` |
| Log Writer | Serialises JsonRecords to the log file | `logWriter` |

## Steps

1. **Ticker fires**: The `time.Ticker` (1-minute period) sends a tick to the poller's select loop.
   - From: `gmailPoller` (OS timer)
   - To: `gmailPoller` select case
   - Protocol: Go channel

2. **Check cycle guard**: The poller checks `p.finished`. If `false`, the previous cycle is still running and this tick is skipped. If `true`, the cycle begins and `p.finished` is set to `false`.
   - From: `gmailPoller`
   - To: `gmailPoller` (internal state)
   - Protocol: in-process

3. **Initialise Gmail client**: Calls `NewGmailClient(config)`, which loads OAuth2 credentials from disk, creates a `gmail.Service` connection, and initialises the three in-process channels (`QueueMessage`, `QueueRecords`, `QueueDelete`).
   - From: `gmailPoller`
   - To: `gmailClient`
   - Protocol: in-process

4. **Launch FetchMessages goroutine**: `client.FetchMessages(done)` starts as a goroutine. It issues a Gmail API `Users.Messages.List` request with the configured query, iterates through all pages (up to 500 messages per page using `NextPageToken`), and sends each full `gmail.Message` (with cursor value) to `QueueMessage`.
   - From: `gmailPoller`
   - To: `gmailClient` (Gmail API via HTTPS)
   - Protocol: HTTPS / Google Gmail API

5. **Launch WriteJsonRecord goroutine**: `WriteJsonRecord(client, done)` starts as a goroutine and blocks reading from `QueueRecords`.
   - From: `gmailPoller`
   - To: `logWriter`
   - Protocol: in-process

6. **Create worker pool**: `createWorkerPool(client)` spawns `workers` (default 3) goroutines, each running `ProcessMessage(client, i, &wg)`. Workers block on `QueueMessage`.
   - From: `gmailPoller`
   - To: `reportProcessor` (× workers)
   - Protocol: in-process channel

7. **Process each message**: Each worker dequeues a `MessageWithCursor`, calls `GetAttachment` to retrieve and decompress the attachment (gzip or zip), then calls `ParseDataXML` to unmarshal the DMARC XML.
   - From: `reportProcessor`
   - To: Gmail API (attachment retrieval) via `gmailClient`
   - Protocol: HTTPS / Google Gmail API

8. **GeoIP enrichment**: For each `<record>` in the XML, `lookup()` is called with the `source_ip` to get the country code. `reverseLookup()` and `hostLookup()` are called to populate `reverse_dns` and `base_domain`.
   - From: `reportProcessor`
   - To: `geoIpLookup`
   - Protocol: in-process (GeoIP.dat file lookup)

9. **Enqueue JsonRecord**: Each enriched `JsonRecord` is sent to `QueueRecords`.
   - From: `reportProcessor`
   - To: `logWriter` (via `QueueRecords` channel)
   - Protocol: in-process channel

10. **Write JSON log line**: The Log Writer dequeues each `JsonRecord`, marshals it to JSON, and appends a single line to `/app/logs/dmarc_log.log` via lumberjack.
    - From: `logWriter`
    - To: filesystem (`/app/logs/dmarc_log.log`)
    - Protocol: file I/O

11. **Cycle completion**: When `FetchMessages` closes `QueueMessage`, workers finish and call `wg.Done()`. `createWorkerPool` returns and closes `QueueRecords`. `WriteJsonRecord` finishes and signals `done`. The poller receives on `done`, sets `p.finished = true`, and the next tick is accepted.
    - From: `gmailPoller`
    - To: `gmailPoller`
    - Protocol: Go channel

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Gmail API list returns error | `log.Fatalf` — process exits | Container restarts via Kubernetes |
| Individual message fetch error | Logged and skipped; loop continues to next message | Message is not processed; remains unread in inbox |
| Attachment missing or unparseable | Logged (`"No Attachment, continuing...."`) and skipped | Message not processed; no record written |
| XML unmarshal error | Logged; `ParseDataXML` returns `nil` | No records written for this email |
| Worker panic | Recovered via deferred `recover()` in `FetchMessages` | `QueueMessage` closed; cycle signals done |
| OAuth2 token expired | Gmail API returns 401; `NewGmailClient` fails | `log.Fatalf` — process exits, Kubernetes restarts |

## Sequence Diagram

```
Ticker -> GmailPoller: tick (every 1 min)
GmailPoller -> GmailClient: NewGmailClient(config)
GmailPoller -> GmailClient: FetchMessages() [goroutine]
GmailClient -> GmailAPI: Users.Messages.List(query)
GmailAPI --> GmailClient: message list (paginated)
GmailClient -> QueueMessage: send MessageWithCursor
GmailPoller -> LogWriter: WriteJsonRecord() [goroutine]
GmailPoller -> ReportProcessor: ProcessMessage() [×3 workers]
ReportProcessor <- QueueMessage: receive MessageWithCursor
ReportProcessor -> GmailAPI: Users.Messages.Attachments.Get()
GmailAPI --> ReportProcessor: attachment data (base64)
ReportProcessor -> GeoIPLookup: lookup(source_ip)
GeoIPLookup --> ReportProcessor: country_code
ReportProcessor -> QueueRecords: send JsonRecord
LogWriter <- QueueRecords: receive JsonRecord
LogWriter -> LogFile: append JSON line
GmailClient -> QueueMessage: close (last page done)
ReportProcessor -> QueueRecords: close (workers done)
LogWriter -> DoneChan: signal done
GmailPoller <- DoneChan: cycle complete; p.finished = true
```

## Related

- Architecture dynamic view: `dynamic-dmarcProcessing`
- Related flows: [DMARC Report Processing](dmarc-report-processing.md), [Staging Single-Message Run](staging-single-message-run.md), [Gmail OAuth2 Authentication](gmail-oauth2-authentication.md)
