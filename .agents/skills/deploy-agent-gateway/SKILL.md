---
name: deploy-agent-gateway
description: Validates, deploys, and verifies the ZeroClaw agent gateway stack using Docker Compose.
license: Apache-2.0
metadata:
  version: "1.0"
---

# deploy-agent-gateway

Bootstrap and verify the containerized ZeroClaw gateway orchestrator.

## Instructions

1.  **Configure Environment:**
    Ensure a `.env` file is generated from `.env.template` and configured with the local data directory and default model name:
    ```bash
    cp .env.template .env
    ```
2.  **Verify Configuration:**
    Inspect `config/.zeroclaw/config.toml` to ensure the VLM inference base URL points to the correct API endpoint (e.g. `http://host.docker.internal:8080/v1` for a local model host).
3.  **Boot Stack:**
    Spin up the Docker Compose services in daemon mode:
    ```bash
    docker compose up -d
    ```
4.  **Confirm Status:**
    Verify that both the `biologger-agent-gateway` and `biologger-browser-node` containers are active:
    ```bash
    docker compose ps
    ```
5.  **Run Gateway Health Check:**
    Verify connectivity to the gateway port (`42617`) and check health:
    ```bash
    curl -I http://localhost:42617/health
    ```
6.  **Verify Database Schema:**
    Query the SQLite database file to confirm the session persistence table is created successfully:
    ```bash
    sqlite3 config/.zeroclaw/sessions.db ".tables"
    ```
    Ensure the `sessions` table is printed.
