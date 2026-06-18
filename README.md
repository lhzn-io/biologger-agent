# Biologger Agent Gateway (biologger-agent)

`biologger-agent` is the gateway and runtime orchestrator for the Marine Predators Group (MPG) biologging reasoning agent stack. It leverages the ZeroClaw agent framework to manage tool-use execution, run sandbox environments, maintain multi-session conversation histories, and coordinate completions with Vision-Language Models (VLM).

---

## Architecture Overview

```text
               +--------------------------------------+
               |          biologger-portal            |
               |         (Frontend Web UI)            |
               +------------------+-------------------+
                                  |
                                  | Proxies Chat to Port 42617
                                  v
        +-------------------------+---------------------------+
        | biologger-agent (ZeroClaw Agent Gateway Container)  |
        |                                                     |
        |  - Orchestrator Engine                              |
        |  - SQLite Session Persistence (sessions.db)          |
        |  - Sandbox Tool Execution                           |
        +-------------------------+---------------------------+
                                  |
                                  | Routes VLM Queries to Port 8080
                                  v
               +------------------+-------------------+
               |           mlx-vlm Server             |
               |        (VLM Inference Host)          |
               +--------------------------------------+
```

---

## Deployment & Setup

This repository provides a containerized setup using Docker Compose to launch the ZeroClaw orchestrator gateway and its helper services.

### 1. Prerequisites
*   Docker and Docker Compose installed.
*   An active, OpenAI-compatible Vision-Language Model server (e.g. `mlx-vlm` or `vllm` running on the host system or on a remote compute node).

### 2. Environment Configuration
Create a `.env` file from the template:
```bash
cp .env.template .env
```

Define the variables:
*   `BIOLOGGER_WORKSPACE_DIR`: Local path to the agent's work directory (default: `./workspace`).
*   `BIOLOGGER_DATASETS_DIR`: Local path to the raw marine telemetry datasets.
*   `DEFAULT_PROVIDER`: The model provider configuration (default: `vllm`).
*   `DEFAULT_MODEL`: The target model name (default: `google/gemma-4-26b-a4b-it`).

### 3. Service Configuration (`config.toml`)
The agent configuration is defined inside `config/.zeroclaw/config.toml`. Key options include:
*   `providers.models.vllm.base_url`: Points to the VLM inference server API. By default, it uses `http://host.docker.internal:8080/v1` to communicate with the host's inference server.
*   `gateway.port`: Binds the gateway orchestrator on port `42617`.

### 4. Running the Stack
Launch the gateway and browser-node containers:
```bash
docker compose up -d
```

Verify that both containers are running:
```bash
docker compose ps
```

---

## Interface Proxy Configuration
To route assistant conversations through the gateway orchestrator, configure the frontend web application (e.g., `biologger-portal`) proxy middleware to forward chat requests:
*   **Chat Target:** `http://localhost:42617/webhook`
*   **Method:** `POST`
*   **Payload Format:** `{"message": "user query here"}`
