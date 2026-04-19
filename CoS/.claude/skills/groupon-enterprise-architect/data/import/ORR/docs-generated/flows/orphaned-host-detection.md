---
service: "ORR"
title: "Orphaned Host Detection"
generated: "2026-03-03"
type: flow
flow_name: "orphaned-host-detection"
flow_type: batch
trigger: "Operator invokes python hosts_without_service.py from the hosts_without_service_project/ directory"
participants:
  - "continuumOrrAuditToolkit"
  - "hostsWithoutServiceAudit"
  - "opsConfigRepository"
architecture_ref: "dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow"
---

# Orphaned Host Detection

## Summary

This flow scans every YAML host file in `ops-config/hosts/` and identifies hosts that have no service (`subservices`) mapping in their `ops_params` section. These "orphaned" hosts represent a hygiene gap — monitoring alerts cannot be attributed to an owning service team. The script builds a list of all offending host filenames, writes them to `/tmp/hosts_without_service.txt`, and prints a summary to stdout.

## Trigger

- **Type**: manual
- **Source**: Operator activates a Python virtual environment and runs `python hosts_without_service.py` from the `hosts_without_service_project/` directory
- **Frequency**: On demand; typically run during ORR cycles to identify hosts needing service assignment

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `hostsWithoutServiceAudit` | Python script executor — scans all host YAML files | `continuumOrrAuditToolkit` |
| `opsConfigRepository` | Source of all host YAML configuration files | `opsConfigRepository` |

## Steps

1. **Resolve ops-config hosts path**: Reads `HOME` environment variable and joins it with the hardcoded relative path `repos/ops-config/hosts` to build the absolute `HOSTS_FILE_PATH`.
   - From: `hostsWithoutServiceAudit`
   - To: OS environment (`$HOME`)
   - Protocol: Python `os.environ.get`

2. **Change working directory**: Calls `os.chdir(HOSTS_FILE_PATH)` to set the working directory to the hosts folder.
   - From: `hostsWithoutServiceAudit`
   - To: `opsConfigRepository` (filesystem)
   - Protocol: filesystem

3. **Enumerate all YAML host files**: Uses a Python generator to list all `.yml` files in the hosts directory without loading them all into memory simultaneously.
   - From: `hostsWithoutServiceAudit`
   - To: `opsConfigRepository` (filesystem)
   - Protocol: `os.listdir()`

4. **Load and parse each YAML file**: For each `.yml` file, calls `yaml.load(fd, Loader=yaml.FullLoader)` to parse the full YAML structure. Increments a `total_files_processed` counter.
   - From: `hostsWithoutServiceAudit`
   - To: `opsConfigRepository` (file content)
   - Protocol: Python PyYAML

5. **Check for subservices mapping**: Reads `ops_params.subservices` from the parsed YAML. If the key is absent (returns `'not-found'`), appends the filename to the `hosts_without_service` list.
   - From: `hostsWithoutServiceAudit`
   - To: in-memory list
   - Protocol: Python dict access

6. **Generate summary report**: After processing all files, prints the total count of files checked and the count of orphaned hosts. If orphaned hosts were found, writes their filenames to `/tmp/hosts_without_service.txt` and prints up to 10 as a sample.
   - From: `hostsWithoutServiceAudit`
   - To: stdout + `/tmp/hosts_without_service.txt`
   - Protocol: file write + print

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `hosts_dir` path does not exist | `os.chdir` raises `FileNotFoundError` | Python traceback; operator must update `hosts_dir` variable in script |
| Malformed YAML file | `yaml.load` may raise `yaml.YAMLError` | Python traceback; script aborts; operator must fix or skip the file |
| `ops_params` key missing entirely | `data.get('ops_params')` returns `None`; `.get('subservices')` raises `AttributeError` | Python traceback; operator must handle edge case |
| No orphaned hosts found | `hosts_without_service_found == 0` | Prints "Everything checks OK - All host files look good." |

## Sequence Diagram

```
Operator -> hostsWithoutServiceAudit: python hosts_without_service.py
hostsWithoutServiceAudit -> OS: os.environ.get('HOME')
OS --> hostsWithoutServiceAudit: /home/<operator>
hostsWithoutServiceAudit -> opsConfigRepository: os.chdir(~/repos/ops-config/hosts)
hostsWithoutServiceAudit -> opsConfigRepository: os.listdir() -> *.yml generator
loop for each host .yml file
  hostsWithoutServiceAudit -> opsConfigRepository: yaml.load(file)
  opsConfigRepository --> hostsWithoutServiceAudit: parsed YAML dict
  hostsWithoutServiceAudit -> hostsWithoutServiceAudit: check ops_params.subservices
  alt subservices missing
    hostsWithoutServiceAudit -> hosts_without_service[]: append filename
  end
end
hostsWithoutServiceAudit -> stdout: summary (N files checked, M orphaned)
hostsWithoutServiceAudit -> /tmp/hosts_without_service.txt: write orphaned host list
hostsWithoutServiceAudit --> Operator: summary + file path
```

## Related

- Architecture dynamic view: `dynamic-hostNotifyAuditByService-monitoring-hostsWithoutServiceAudit-flow`
- Related flows: [Fleet-Wide Monitor Audit](fleet-wide-monitor-audit.md), [Host Monitor Audit by Service](host-monitor-audit-by-service.md)
