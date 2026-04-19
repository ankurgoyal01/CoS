---
service: "gdpr"
title: "Manual CLI Export"
generated: "2026-03-03"
type: flow
flow_name: "manual-cli-export"
flow_type: synchronous
trigger: "Operator invokes the gdpr binary with the 'manual' subcommand and required flags"
participants:
  - "Operator (shell)"
  - "continuumGdprService.manualCli"
  - "continuumGdprService.gdprOrchestrator"
  - "cs-token-service"
  - "api-lazlo"
  - "global-subscription-service"
  - "ugc-api-jtier"
  - "m3-placeread"
  - "continuumConsumerDataService"
  - "continuumGdprService.zipExporter"
architecture_ref: "dynamic-GdprManualExport"
---

# Manual CLI Export

## Summary

An operator can trigger a GDPR data export directly from the command line by invoking the `gdpr` binary with the `manual` subcommand and the required consumer and agent identification flags. The CLI mode runs the same data collection pipeline as the web mode — collecting orders, preferences, subscriptions, UGC reviews, and profile addresses — and writes a ZIP archive to the OS temporary directory. Unlike web mode, the result is not streamed over HTTP and no email is sent; the ZIP archive is left on the local filesystem at `os.TempDir()/{consumer_uuid}.zip` for the operator to retrieve.

## Trigger

- **Type**: manual
- **Source**: Operator runs `./gdpr manual -consumer_uuid=... -consumer_country=... -consumer_email=... -agent_id=... -agent_email=...` in a shell session
- **Frequency**: On demand (ad hoc, operator-driven)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator | Provides consumer and agent identity via CLI flags; retrieves the resulting ZIP from the filesystem | External actor |
| Manual CLI | Parses flags, validates all required arguments are present, creates staging directory, calls `getGdprData()` | `continuumGdprService` (manualCli component) |
| GDPR Orchestrator | `getGdprData()` — coordinates sequential data collection across all five collectors | `continuumGdprService` (gdprOrchestrator component) |
| `cs-token-service` | Issues scoped tokens for Lazlo API calls | `tokenService_9f1c2a` (stub) |
| `api-lazlo` | Provides orders and preferences data | `lazloService_c7b4e1` (stub) |
| `global-subscription-service` | Provides subscription records | `subscriptionService_a2f7c0` (stub) |
| `ugc-api-jtier` | Provides user reviews and answer metadata | `ugcService_31a0e8` (stub) |
| `m3-placeread` | Provides merchant name and city for review enrichment | `placeService_6b9d42` (stub) |
| `consumer-data-service` | Provides profile-level location addresses | `continuumConsumerDataService` |
| ZIP Exporter | Packages all CSV files into `os.TempDir()/{uuid}.zip` | `continuumGdprService` (zipExporter component) |

## Steps

1. **Parse CLI flags**: Manual CLI parses the `manual` subcommand's flags using Go's `flag.FlagSet`. Required flags: `-consumer_uuid`, `-consumer_country`, `-consumer_email`, `-agent_id`, `-agent_email`
   - From: `continuumGdprService.manualCli`
   - To: local process (flag parsing)
   - Protocol: direct

2. **Validate required flags**: If any of the five required flags is empty, `manual.PrintDefaults()` is called and the process exits with code 1
   - From: `continuumGdprService.manualCli`
   - To: `continuumGdprService.manualCli` (internal)
   - Protocol: direct

3. **Populate configuration from TOML**: The `tomlConfig` is decoded from `config/config.toml` and assigned to the `Cfg` struct along with the flag values
   - From: `continuumGdprService.manualCli`
   - To: local filesystem (`config/config.toml`)
   - Protocol: direct (file read)

4. **Create staging directory**: Creates `os.TempDir()/{consumer_uuid}/` for CSV file staging
   - From: `continuumGdprService.manualCli`
   - To: local filesystem
   - Protocol: OS filesystem call

5. **Run data collection pipeline**: Calls `getGdprData(&cfg)`, which sequentially runs all five collectors and the ZIP exporter — identical pipeline to the web flow. See [Data Collection Pipeline](data-collection-pipeline.md) for full step detail.
   - From: `continuumGdprService.gdprOrchestrator`
   - To: all downstream services (same as web flow)
   - Protocol: HTTP GET / HTTP POST

6. **ZIP archive written to temp**: After all collectors complete, `zipFile()` creates `os.TempDir()/{consumer_uuid}.zip`
   - From: `continuumGdprService.zipExporter`
   - To: local filesystem
   - Protocol: direct

7. **Process exits**: The binary exits. No automatic cleanup is performed in CLI mode — the ZIP archive remains in `os.TempDir()` for the operator to retrieve.
   - From: `continuumGdprService.manualCli`
   - To: OS process exit
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required CLI flag | `manual.PrintDefaults()` printed; process exits with code 1 | No export performed; operator sees usage output |
| `config/config.toml` not found | `log.Fatalln()` — process exits with fatal error | No export performed |
| Any downstream API call fails | Error logged; `log.Println(err)` in `getGdprData()` | Export may be partial or fully aborted depending on failure point |
| Token service returns non-200 | Error returned from `getToken()`; logged | Export aborts at the relevant collection step |

## Sequence Diagram

```
Operator -> ManualCLI: ./gdpr manual -consumer_uuid=... -consumer_country=... -consumer_email=... -agent_id=... -agent_email=...
ManualCLI -> ManualCLI: parse flags, validate all present
ManualCLI -> filesystem: decode config/config.toml
ManualCLI -> filesystem: mkdir os.TempDir()/{uuid}/
ManualCLI -> Orchestrator: getGdprData(&cfg)
Orchestrator -> [Data Collection Pipeline]: (see data-collection-pipeline.md)
Orchestrator --> ManualCLI: zip file written to os.TempDir()/{uuid}.zip
ManualCLI -> Operator: process exits (ZIP available at os.TempDir()/{uuid}.zip)
```

## Related

- Architecture dynamic view: `dynamic-GdprManualExport`
- Related flows: [Web Export Request](web-export-request.md), [Data Collection Pipeline](data-collection-pipeline.md), [Token Acquisition](token-acquisition.md)
