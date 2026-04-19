---
service: "jira"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-files", "env-vars"]
---

# Configuration

## Overview

Jira is configured through a set of XML and properties files placed in the Jira home directory and the Tomcat `bin/` directory. There are no external config stores (Consul, Vault, or Helm values) visible in the source evidence. JVM arguments and memory limits are set in `sys_config/setenv.sh`. Application behavior is governed by `sys_config/jira-config.properties`. Database connectivity is defined in `sys_config/dbconfig.xml`. Authentication flow is controlled by `sys_config/seraph-config.xml`. Logging behavior is defined in `sys_config/log4j.properties`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JIRA_HOME` | Overrides the Jira home directory path | no | None (must be set in `setenv.sh` or externally) | env / `setenv.sh` |
| `CATALINA_HOME` | Tomcat installation directory | yes (Tomcat) | None | env |
| `CATALINA_BASE` | Tomcat base directory; used to locate PID file and logs | no | Falls back to `CATALINA_HOME` | env |
| `CATALINA_PID` | Path to the Tomcat PID file | no | `$CATALINA_BASE/work/catalina.pid` | env / `setenv.sh` |
| `JVM_MINIMUM_MEMORY` | JVM `-Xms` heap floor | yes | `8192m` | `sys_config/setenv.sh` |
| `JVM_MAXIMUM_MEMORY` | JVM `-Xmx` heap ceiling | yes | `10240m` | `sys_config/setenv.sh` |
| `JVM_SUPPORT_RECOMMENDED_ARGS` | Optional extra JVM args recommended by Atlassian Support | no | `""` | `sys_config/setenv.sh` |
| `DISABLE_NOTIFICATIONS` | When uncommented, disables outgoing and incoming mail | no | Not set | `sys_config/setenv.sh` |
| `JAVA_OPTS` | Assembled JVM options passed to Tomcat | yes | Assembled from above vars | `sys_config/setenv.sh` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `jira.websudo.is.disabled` | Disables WebSudo (admin re-authentication prompt) | `true` | global |
| `jira.option.user.crowd.allow.rename` | Allows Crowd users to be renamed | `true` | global |
| `jira.search.views.default.max` | Maximum results returned by default search views | `3000` | global |
| `jira.search.views.max.limit` | Hard cap on search result size | `3000` | global |
| `jira.index.lock.waittime` | Lucene index lock wait time in ms | `90000` | global |
| `jira.index.max.reindexes` | Maximum number of pending reindex tasks | `0` | global |
| `ops.bar.group.size.opsbar-transitions` | Number of visible workflow transitions in the Operations Bar | `4` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `sys_config/dbconfig.xml` | XML | JDBC datasource configuration (URL, driver, pool settings) |
| `sys_config/jira-config.properties` | Java properties | Application tuning (search limits, index settings, UI options) |
| `sys_config/jpm.xml` | XML | Jira property manager definitions (full application property manifest) |
| `sys_config/log4j.properties` | Log4j 1.x properties | Logging levels and appender configuration for all log categories |
| `sys_config/seraph-config.xml` | XML | Seraph security framework configuration (login URLs, authenticator class, session handling) |
| `sys_config/setenv.sh` | Shell script | JVM memory and argument configuration for Tomcat startup |
| `/var/groupon/jira/legacy_usernames.txt` | CSV (comma-separated) | Maps current SSO usernames to legacy Jira usernames; loaded at runtime by `GwallAuthenticator` |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `jirauser` DB password | MySQL authentication for `jiranewdb` | Stored externally; blank value in `sys_config/dbconfig.xml` |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Only `production` in `snc1` is declared in `.service.yml`. No staging or development environment configuration is present in the source evidence. Environment-specific overrides (database host, credentials, memory sizes) are applied by the Systems Engineering team during host provisioning.
