---
service: "dmarc"
title: "Staging Single-Message Run"
generated: "2026-03-03"
type: flow
flow_name: "staging-single-message-run"
flow_type: event-driven
trigger: "Process startup with DEPLOY_ENV=staging"
participants:
  - "gmailPoller"
  - "gmailClient"
  - "reportProcessor"
  - "geoIpLookup"
  - "logWriter"
architecture_ref: "dynamic-dmarcProcessing"
---

# Staging Single-Message Run

## Summary

When `DEPLOY_ENV` is set to `staging`, the DMARC service runs a one-shot processing path instead of the continuous polling loop. It fetches exactly one unread DMARC report email (`MaxResults(1)`), processes it through the full attachment extraction and XML parsing pipeline, writes the resulting JSON records to the log file, and then blocks indefinitely on an empty `select{}` to keep the Kubernetes pod alive for health checking. This mode is used to validate the end-to-end processing pipeline in the staging environment without consuming the full unread message backlog.

## Trigger

- **Type**: event (environment variable at process startup)
- **Source**: `DEPLOY_ENV=staging` environment variable read by `main()`
- **Frequency**: Once per container start in staging environment

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Gmail Poller | Detects staging mode; orchestrates one-shot execution | `gmailPoller` |
| Gmail Client | Fetches a single Gmail message and its attachment | `gmailClient` |
| Report Processor | Parses DMARC XML for the single message | `reportProcessor` |
| GeoIP Lookup | Enriches source IPs with country codes | `geoIpLookup` |
| Log Writer | Writes JSON records using `WriteSingleJsonRecord` | `logWriter` |

## Steps

1. **Detect staging mode**: `main()` reads `DEPLOY_ENV` from the environment. When `"staging"`, the staging code path is taken instead of `newPoller()`.
   - From: OS environment
   - To: `main()`
   - Protocol: in-process

2. **Start heartbeat**: `go heartbeat()` launches the HTTP server goroutine on port `8080` before any Gmail operations.
   - From: `main()`
   - To: `heartbeat.go` HTTP server
   - Protocol: in-process goroutine

3. **Build app config**: `appConfig()` loads `config.toml`, opens `GeoIP.dat`, creates the lumberjack-backed logger.
   - From: `main()`
   - To: filesystem
   - Protocol: file I/O

4. **Create Gmail client**: `NewGmailClient(config)` authenticates with Gmail API using the OAuth2 token and creates the three in-process channels.
   - From: `main()`
   - To: Gmail API
   - Protocol: HTTPS / OAuth2

5. **Fetch single message**: `client.FetchMessage()` (note: singular, not plural) issues `Users.Messages.List(...).MaxResults(1)`, fetches the full message payload for the first result, and sends it to `QueueMessage` with an empty cursor. Then closes `QueueMessage` and signals `Wg.Done()`.
   - From: `gmailClient`
   - To: Gmail API
   - Protocol: HTTPS / Google Gmail API

6. **Launch WriteSingleJsonRecord goroutine**: `WriteSingleJsonRecord(client)` starts concurrently, reading from `QueueRecords` until it is closed.
   - From: `main()`
   - To: `logWriter`
   - Protocol: in-process goroutine

7. **Create worker pool**: `createWorkerPool(client)` spawns `workers` goroutines (default 3). Each worker processes the single message from `QueueMessage`, producing `JsonRecord` values.
   - From: `main()`
   - To: `reportProcessor`
   - Protocol: in-process

8. **Process message**: Each worker follows the same attachment extraction, XML parsing, and GeoIP enrichment steps as the production flow. See [DMARC Report Processing](dmarc-report-processing.md) for detail.
   - From: `reportProcessor`
   - To: `geoIpLookup`, Gmail API
   - Protocol: in-process / HTTPS

9. **Write records**: `WriteSingleJsonRecord` marshals each `JsonRecord` to JSON and appends it to the log file.
   - From: `logWriter`
   - To: filesystem
   - Protocol: file I/O

10. **Wait and block**: `client.Config.Wg.Wait()` blocks until both the `FetchMessage` goroutine and `WriteSingleJsonRecord` have completed. Then `select{}` blocks forever, keeping the pod alive.
    - From: `main()`
    - To: Kubernetes (pod stays Running; health endpoint remains reachable)
    - Protocol: HTTP (heartbeat on `:8080`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Gmail API error on message list | Logged; no messages fetched | `QueueMessage` closed immediately; worker pool exits cleanly |
| Message has no attachment | Logged and skipped | No records written; pod continues to block |
| XML parse failure | Logged; `ParseDataXML` returns `nil` | No records written for this email |
| OAuth2 token invalid | `log.Println("Error, creating client")` | Client creation fails; no processing occurs; pod blocks at `select{}` |

## Sequence Diagram

```
Startup -> main: DEPLOY_ENV=staging
main -> heartbeat: go heartbeat() [goroutine, port 8080]
main -> GmailAPI: NewGmailClient(config)
GmailAPI --> main: GmailBackend{}
main -> GmailClient: go FetchMessage() [goroutine]
GmailClient -> GmailAPI: Users.Messages.List(MaxResults=1)
GmailAPI --> GmailClient: [message]
GmailClient -> QueueMessage: send MessageWithCursor{cursor: ""}
GmailClient -> QueueMessage: close
main -> LogWriter: go WriteSingleJsonRecord() [goroutine]
main -> Workers: createWorkerPool() [×3 workers]
Workers <- QueueMessage: receive message
Workers -> GmailAPI: GetAttachment()
GmailAPI --> Workers: attachment
Workers -> GeoIP: lookup(source_ip)
Workers -> QueueRecords: send JsonRecord (×N records)
LogWriter <- QueueRecords: receive JsonRecord
LogWriter -> LogFile: append JSON line
Workers -> WaitGroup: Done()
LogWriter -> WaitGroup: Done()
main -> select{}: block forever (heartbeat stays alive)
```

## Related

- Architecture dynamic view: `dynamic-dmarcProcessing`
- Related flows: [Production Polling Cycle](production-polling-cycle.md), [DMARC Report Processing](dmarc-report-processing.md)
