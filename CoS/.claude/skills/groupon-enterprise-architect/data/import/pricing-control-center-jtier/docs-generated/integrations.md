---
service: "pricing-control-center-jtier"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 4
---

# Integrations

## Overview

The service has four internal Groupon service dependencies (Pricing Service, Voucher Inventory Service, Users Service, and Gdoop/HDFS) and three external platform dependencies (Hive Warehouse, GCS, and SMTP relay). All HTTP calls use JTier Retrofit clients with `clientId` parameter or `x-api-key` header authentication. Hive queries use JDBC with a service account. GCS access uses a GCP service account with a private key. Retry logic (`resilience4j-retry`) is applied to Hive query operations; Retrofit clients inherit JTier connection pool and timeout defaults.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Hive Warehouse (on-prem) | Hive JDBC | Reads flux model schedule, model location, and superset data | yes | `hiveWarehouse` |
| Hive GCP Gateway | Hive JDBC (SSL) | Reads GCP-backed Hive datasets for Custom ILS deal options | yes | `hiveWarehouse` |
| Dynamic Pricing GCS Bucket | GCP SDK (google-cloud-storage) | Downloads RPO extract files | no (RPO channel only) | `gcpDynamicPricingBucket` |
| SMTP Relay | SMTP | Sends job failure and go-live notification emails | no | `messagingSaaS` |

### Hive Warehouse (on-prem) Detail

- **Protocol**: Hive JDBC (`jdbc:hive2://`)
- **Base URL / SDK**: `jdbc:hive2://cerebro-hive-server3.snc1:10000` (dev/staging)
- **Auth**: Service account username (`dynamic_pricing`)
- **Purpose**: Reads `ils_flux_model_schedule_view` and `ils_flx_model_location` tables for Custom ILS flux model sync; reads superset deal eligibility tables for `SupersetFetchJob`
- **Failure mode**: Job fails with retry; up to 7 attempts at 5-minute intervals. Transient read timeout exceptions cause retry; persistent failures send email alert.
- **Circuit breaker**: No circuit breaker — resilience4j-retry only

### Hive GCP Gateway Detail

- **Protocol**: Hive JDBC over SSL with HTTP transport (`transportMode=http;httpPath=gateway/adhoc-query/hive`)
- **Base URL / SDK**: `jdbc:hive2://datalake-connect.data-comp.prod.gcp.groupondev.com:8443/grp_gdoop_local_ds_db`
- **Auth**: Service account (`svc_gcp_price`), password-secured, SSL trust store at `/var/groupon/jtier/certs/gateway-client.jks`
- **Purpose**: Reads GCP-backed Hive datasets for Custom ILS deal option fetching (`CustomILSFetchDealOptionsJob`)
- **Failure mode**: Job fails with retry; error triggers email notification to Custom ILS stakeholders
- **Circuit breaker**: No circuit breaker

### Dynamic Pricing GCS Bucket Detail

- **Protocol**: GCP SDK (`google-cloud-storage` 1.25.0)
- **Base URL / SDK**: Bucket configured via `gcpConfiguration.gcpBucket`; project `gcpConfiguration.projectId`
- **Auth**: GCP service account (`grpn-sa-dyn-pricing-gcs-ro@...`) with private key; configured via `gcpConfiguration` block
- **Purpose**: Downloads date-stamped RPO model extract files (`extract-{date}.out`) for `RetailPriceOptimizationJob`
- **Failure mode**: Job version record status set to error; job skips processing
- **Circuit breaker**: No circuit breaker

### SMTP Relay Detail

- **Protocol**: SMTP (`simple-java-mail` 5.1.4)
- **Base URL / SDK**: `smtp.snc1`, port 25 (dev/staging)
- **Auth**: None (internal relay, no credentials)
- **Purpose**: Sends operational failure alerts and Custom ILS go-live notifications
- **Failure mode**: Email send failure is logged; does not block job completion
- **Circuit breaker**: No circuit breaker

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Pricing Service | HTTP/REST (Retrofit) | Creates and deletes pricing programs in bulk; fetches price history | `continuumPricingService` |
| Voucher Inventory Service (VIS) | HTTP/REST (Retrofit) | Retrieves min-per-pledge and inventory constraints for local products | `continuumVoucherInventoryService` |
| Users Service | HTTP/REST (Retrofit) | Validates user identity and resolves role information during authentication | `continuumUsersService` |
| Gdoop (HDFS) | HTTP (WebHDFS / Gdoop API) | Lists and downloads Sellout flux output files from HDFS | `hdfsStorage` |

### Pricing Service Detail

- **Protocol**: HTTP/REST (Retrofit via `jtier-retrofit`)
- **Base URL**: `http://pricing-app-staging-vip.snc1` (staging); production URL environment-specific
- **Auth**: `clientId` query parameter (`1e6f3ff0-0750-49d6-adb6-fa9a5a1bf9f9` in dev/staging)
- **Purpose**: Bulk create pricing programs (`ILSSchedulingSubJob`), bulk delete programs (`ILSUnschedulingJob`), fetch price history (`PriceHistoryResource`)
- **Failure mode**: Products set to `SCHEDULING_FAILED` with exclusion reason; email alert sent on job failure
- **Circuit breaker**: No explicit circuit breaker

### Voucher Inventory Service (VIS) Detail

- **Protocol**: HTTP/REST (Retrofit)
- **Base URL**: `http://voucher-inventory-staging.snc1` (staging)
- **Auth**: `clientId` query parameter
- **Purpose**: Fetches min-per-pledge values for local-channel products before building pricing payloads
- **Failure mode**: Sub-job fails for affected products; exclusion reason recorded
- **Circuit breaker**: No explicit circuit breaker

### Users Service Detail

- **Protocol**: HTTP/REST (Retrofit)
- **Base URL**: `https://users-service-app-staging-vip.snc1` (staging)
- **Auth**: `x-api-key` header (configured per environment via secrets)
- **Purpose**: Validates Doorman `authn-token` and resolves user identity/roles during `AuthenticationFilter` processing
- **Failure mode**: Request returns `401 Unauthorized`
- **Circuit breaker**: No explicit circuit breaker

### Gdoop Detail

- **Protocol**: HTTP (Gdoop WebHDFS API)
- **Base URL**: `http://gdoop-namenode-vip.snc1:50070` (dev/staging)
- **Auth**: None specified in config (internal network)
- **Purpose**: Lists available Sellout flux output files and downloads the latest unprocessed file for `SelloutProgramCreatorJob`
- **Failure mode**: Job skips processing; version record not created
- **Circuit breaker**: No explicit circuit breaker

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Control Center UI | HTTP/REST | End-user web interface for sales management; calls all public endpoints |
| Data Science team clients | HTTP/REST | Programmatic access to `/sales/get-sales-in-timerange` using configured `supportedClientIds` |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

- Hive queries use resilience4j-retry with up to 7 attempts at 5-minute intervals (`retryPolicy.hive.maxAttemptCount: 7`, `waitTime: 300000`).
- Retrofit clients use JTier default connection pool and timeout settings.
- No service mesh (Istio/Envoy), no circuit breakers, no adaptive load shedding are configured.
- GCS and SMTP failures are isolated to their respective jobs and do not affect the main scheduling path.
