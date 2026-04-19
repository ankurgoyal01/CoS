---
service: "optimize-suite"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [runtime-js-config-object, browser-cookies, npm-package-json]
---

# Configuration

## Overview

Optimize Suite is configured entirely at runtime in the browser via a JavaScript configuration object passed to `window.OptimizeSuite.init(config)`. There are no server-side environment variables or config files — the library is a browser bundle. Default values are derived from browser cookies by `default-config.js`, then deep-merged with the host-application-provided config. Optimize I-Tier Bindings (a separate server-side module) is responsible for assembling and injecting this config into the page before optimize-suite initializes.

## Environment Variables

> Not applicable. Optimize Suite is a browser-side JavaScript library and does not use server-side environment variables at runtime. Build-time tooling (Jenkins pipeline) uses the following credentials:

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GH_TOKEN` | NLM GitHub token for automated release commits | yes | None | Jenkins credential `NLM_GH_TOKEN` |
| `NPM_EMAIL` | npm registry authentication email | yes | None | Jenkins credential `NLM_NPM_EMAIL` |
| `NPM_USERNAME` | npm registry authentication username | yes | None | Jenkins credential `NLM_NPM_USERNAME` |
| `NPM_PASSWORD_BASE64` | npm registry authentication password (base64) | yes | None | Jenkins credential `NLM_NPM_PASSWORD_BASE64` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `config.trackingHub` | Enables TrackingHub initialization | `true` (set in default config) | per-page |
| `config.errorCatcher` | Enables ErrorCatcher uncaught error capture | `true` (set in default config) | per-page |
| `config.sanityCheck` | Enables SanityCheck runtime invariant monitoring | `true` (set in default config) | per-page |
| `config.devMode` | Activates inspector overlay; errors are thrown instead of suppressed | `false`; forced `true` if `optimize-inspectors` cookie is present | per-session |
| `config.suppressErrors` | Suppresses thrown errors from sub-libraries | `!devMode` (auto-computed) | per-session |
| `config.finch` | Enables Finch experiment initialization when truthy | `{}` (falsy check on presence) | per-page |
| `config.advancedAnalytics.enabled` | Enables ClickTale session recording | `false` | per-page |
| `config.unthrottleGoogleAnalytics` | Loads Google Analytics snippet on window load instead of GTM integration path | `false` | per-page |
| `optimize-inspectors` cookie | Presence forces `devMode = true` on any page | Not set | per-session (cookie) |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `package.json` | JSON | npm package manifest; defines version, dependencies, scripts, engines, browserslist, c8 coverage, mocha config |
| `.npmrc` | INI | npm registry configuration (points to internal Groupon npm registry `https://npm.groupondev.com`) |
| `.nvmrc` | Text | Node.js version pin for local development |
| `webpack.config.js` | JavaScript | Webpack build configuration; defines three entry points (`optimize-suite`, `optimize-suite-standalone`, `inspector`) and build output to `build/` |
| `.eslintrc.json` | JSON | ESLint rules using `eslint-config-groupon` base |
| `.prettierrc.js` | JavaScript | Prettier formatting configuration |
| `.editorconfig` | INI | Editor formatting settings |
| `.service.yml` | YAML | Service portal metadata: team, SRE contacts, colo/environment base URLs, PagerDuty, Slack, dashboard links |
| `Jenkinsfile` | Groovy | CI/CD pipeline definition (test on node14+node16, publish on main via `nlm`) |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `NLM_GH_TOKEN` | Automated GitHub release commits via `nlm` | Jenkins credential store |
| `NLM_NPM_EMAIL` | npm publish authentication | Jenkins credential store |
| `NLM_NPM_USERNAME` | npm publish authentication | Jenkins credential store |
| `NLM_NPM_PASSWORD_BASE64` | npm publish authentication | Jenkins credential store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The runtime config object is assembled by Optimize I-Tier Bindings on the server and differs by environment:

| Config Key | Staging | UAT | Production |
|------------|---------|-----|------------|
| Birdcage base URL (internal) | `http://birdcage-staging.snc1.` | `http://birdcage-uat.snc1.` | `http://birdcage.snc1.` / `http://birdcage.dub1.` |
| `config.finch.debug` | Typically `true` | `false` | `false` |
| `googleAnalyticsTrackingId` | Staging GA property | UAT GA property | Production GA property |
| `config.advancedAnalytics.enabled` | `false` | `false` | `true` (on enabled pages) |

The optimize-suite npm package itself is environment-agnostic; all environment-specific values are injected by the host application at `init()` time.
