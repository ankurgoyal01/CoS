# Coffee To Go Technical Documentation

## Introduction

Coffee To Go is a full-stack web application designed for Groupon employees to track live deals and opportunities in specific areas. It provides a seamless experience for finding, filtering, and exploring deals, opportunities and accounts.

This document provides a high-level overview of the technical architecture and components of the Coffee To Go system.

### System Overview

The system is composed of three main parts:

*   **Frontend**: A React single-page application (`coffee-react`) that provides the user interface.
*   **Backend**: A Node.js/Express API (`coffee-api`) that serves the frontend and provides REST endpoints for data.
*   **Data Ingestion & Orchestration**: A set of n8n workflows that handle data ingestion and processing from various sources.

### Data Flow

1.  n8n workflows periodically ingest and update business, opportunity, and deal data in a PostgreSQL database. Materialized views are used to keep UI queries fast.
2.  The `coffee-api` backend reads from the PostgreSQL database and exposes REST endpoints.
3.  The `coffee-react` frontend calls these endpoints to render maps, lists, and details for users.
4.  Authentication is handled via Google OAuth for users and API keys for service-to-service communication.

## n8n Workflows

The data powering the Coffee To Go application is prepared and ingested by a series of n8n workflows. These workflows are responsible for fetching data from various sources like Salesforce and MDS Deals API, transforming it, and loading it into the PostgreSQL database.

### [Coffee] Update Accounts Job Creator

[1J15nmXbfvB7MAVA](https://n8n.groupondev.com/workflow/1J15nmXbfvB7MAVA)

#### Description
This workflow initiates a Salesforce Bulk Query job to fetch account data that has been updated since the last run. It records a new job entry in the `job_metadata` table with a "running" status and then triggers the "Update Accounts Processor" workflow to handle the results.

#### Error handling and recovery
If any step in the workflow fails, an Error Trigger node catches the error and sends a notification to a centralized monitoring webhook with details about the failure. The workflow itself does not have a recovery mechanism, but it's designed to be re-runnable.

### [Coffee] Update Accounts Processor

[CDQD9a2BeQUIkkyO](https://n8n.groupondev.com/workflow/CDQD9a2BeQUIkkyO)

#### Description
This workflow processes the data from the Salesforce job created by the "Update Accounts Job Creator". It polls the Salesforce job status until it's complete. Once completed, it fetches the results in pages, transforms the data (including calculating account importance and address validation), and upserts the account records into the PostgreSQL database in batches. It continues this process until all pages are fetched.

#### Error handling and recovery
Failures are reported to a monitoring webhook. The workflow has a recovery mechanism: a scheduled trigger runs periodically to check if a job has been in the "running" state for too long (e.g., more than 10 minutes without an update). If a stalled job is detected, the workflow is re-triggered to resume processing. Individual steps that communicate with external services like Salesforce have built-in retries.

### [Coffee] Update Opportunities Job Creator

[BsFIgYPdUOEQ2Xwe](https://n8n.groupondev.com/workflow/BsFIgYPdUOEQ2Xwe)

#### Description
Similar to the accounts job creator, this workflow starts a Salesforce Bulk Query job for opportunities, focusing on those with a Deal UUID that have been updated since the last successful run. It creates a job record in the database and then starts the "Update Opportunities Processor" workflow.

#### Error handling and recovery
Errors are caught and reported to a central monitoring webhook. This workflow is idempotent and can be re-run if it fails.

### [Coffee] Update Opportunities Processor

[KVNMZUJ9hMiHwLHg](https://n8n.groupondev.com/workflow/KVNMZUJ9hMiHwLHg)

#### Description
This workflow processes the opportunity data from the Salesforce job. It polls the job, fetches results in pages, maps the fields to the application's data model, and batch-upserts the opportunity data into the PostgreSQL database. It continues until all data is processed and then marks the job as "finished".

#### Error handling and recovery
Like the accounts processor, this workflow reports errors to a monitoring webhook. It also includes a recovery mechanism that re-runs the workflow if a job appears to be stalled. API calls to Salesforce are configured to retry on failure.

### [Coffee] Account Reviews Job Creator

[tp3tJCJDd6SdkLIS](https://n8n.groupondev.com/workflow/tp3tJCJDd6SdkLIS)

#### Description
This workflow initiates a Salesforce job to download account review data that has been updated since the last run. It logs the job creation in the metadata table and triggers the associated processor workflow.

#### Error handling and recovery
Errors during the job creation process are caught and sent to a monitoring webhook, providing details about the failure.

### [Coffee] Account Reviews Processor

[62g2ZLHN5JMnsrJn](https://n8n.groupondev.com/workflow/62g2ZLHN5JMnsrJn)

#### Description
This workflow polls the Salesforce job for account reviews. Once the job is complete, it fetches the results, parses the CSV data, maps the review information, and saves it to the `reviews` table in the PostgreSQL database. After all reviews are saved, it aggregates the new review data into the `account_reviews` table.

#### Error handling and recovery
The workflow includes an error trigger that reports failures to a monitoring webhook. It also has a recovery mechanism that checks for stalled jobs and re-runs the workflow if necessary.

### [Coffee] Deleted Accounts And Opportunities

[zfDGPwytIWwPUQAI](https://n8n.groupondev.com/workflow/zfDGPwytIWwPUQAI)

#### Description
This maintenance workflow is responsible for data cleanup. It runs for a specified date range, fetches the IDs of accounts and opportunities that have been deleted in Salesforce, and then removes the corresponding records from the application's PostgreSQL database to ensure data consistency.

#### Error handling and recovery
Any errors encountered during the process are reported to a centralized monitoring webhook.

### [Coffee] MDS Deal Details V2

[uMttzqAXmyS3i5rd](https://n8n.groupondev.com/workflow/uMttzqAXmyS3i5rd)

#### Description
This workflow fetches detailed deal information from the MDS (Merchant Deal Service) API. It paginates through the API's results, extracts deal details and unique redemption locations, and upserts this data into the `deal_details` and `redemption_locations` tables in the database.

#### Error handling and recovery
The workflow has error handling that reports failures to a monitoring service. It also has a recovery mechanism that checks for stalled jobs and can restart the process. The HTTP requests to the MDS API are set up to retry on failure.

### [Coffee] Deep Scout

[vRVetc2tRZYwbbTe](https://n8n.groupondev.com/workflow/vRVetc2tRZYwbbTe)

#### Description
This workflow integrates with the Deep Scout third-party service. It downloads a JSON file containing deal data from an S3 bucket, parses the file, transforms the data into the `prospects` table schema, and upserts the records into the database. It also cleans up old prospect data that hasn't been updated recently.

#### Error handling and recovery
Failures in this workflow are caught and reported via a webhook to a monitoring system.

### [Coffee] Refresh View

[Tscicfofs8s0LlkU](https://n8n.groupondev.com/workflow/Tscicfofs8s0LlkU)

#### Description
To ensure the application's queries are fast and responsive, this workflow triggers a refresh of a materialized view in the PostgreSQL database named `deals_cache`. This is typically scheduled to run after all data ingestion workflows have completed.

#### Error handling and recovery
Errors during the materialized view refresh are reported to a monitoring webhook.

### [Coffee] Load PDS TG mapping

[KKJZupgW7sXZwvcU](https://n8n.groupondev.com/workflow/KKJZupgW7sXZwvcU)

#### Description
This is an on-demand workflow used to load or update the mapping between Primary Deal Services (PDS) and Taxonomy Groups (TG). It reads data from a Google Sheet and upserts it into the `pds_tg_map` table in the database. This data changes infrequently.

#### Error handling and recovery
This workflow does not have explicit error handling beyond the default n8n error reporting. It is designed for manual execution.

## coffee-api

The `coffee-api` is the backend service for the Coffee To Go application. It's a Node.js application built with Express and TypeScript.

### Tech Stack

*   **Framework**: Express 5
*   **Language**: TypeScript
*   **Database**: PostgreSQL with Kysely for type-safe queries
*   **Authentication**: `better-auth` for Google OAuth and API key management
*   **Logging**: Pino for structured logging
*   **API Documentation**: Swagger (OpenAPI)
*   **Error Reporting**: Sentry

### Functionality

The primary role of the `coffee-api` is to provide a RESTful API for the `coffee-react` frontend. It serves data related to deals, accounts, and opportunities. It also handles user authentication and serves the frontend application's static files in a production environment. Key functionalities include:

*   Endpoints for fetching deals data for the map and list views.
*   User authentication and session management.
*   Serving feature flags to the client.
*   Providing API documentation via Swagger UI.

System-level functions like health checks or metrics are available but are not the main focus of the application's business logic. The main function is to provide data for the frontend.

## coffee-react

The `coffee-react` application is the frontend for Coffee To Go, providing a rich, interactive user interface for exploring deal data.

### Tech Stack

*   **Framework**: React 19
*   **UI Components**: Material-UI v7
*   **Routing**: TanStack Router for type-safe routing
*   **Data Fetching/State Management**: TanStack Query for server state and Zustand for local client state
*   **Mapping**: Google Maps API
*   **Build Tool**: Vite

### Functionality

The application allows users to:

*   View deals, opportunities and accounts on an interactive map.
*   Search for locations and see relevant data points in that area.
*   Filter data based on various criteria.
*   View detailed information about each data point.
*   Authenticate with their Google account.