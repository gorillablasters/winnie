# Winnie Deployment

This folder is the customer-facing deployment bundle.

## Files to Deliver

- `docker-compose.yml`
- `.env.example`

The customer copies `.env.example` to `.env`, fills in passwords, then starts the stack.

For a single Docker Hub repository named `gorillablasters/winnie`, use image tags
like:

```env
WINNIE_API_IMAGE=gorillablasters/winnie:api-1.0.0
WINNIE_DASHBOARD_IMAGE=gorillablasters/winnie:dashboard-1.0.0
```

## Customer Install

```bash
docker login ghcr.io
cp .env.example .env
docker compose --env-file .env up -d
```

The dashboard is available at `http://localhost:3000` unless `WINNIE_DASHBOARD_PORT`
is changed.

## Demo Data

For a demo install only:

```env
DEMO_DATA=true
RESET_APP_DATA=false
```

`DEMO_DATA=true` resets app tables and seeds:

- Email: `demo@example.com`
- Password: `password123`

Keep `DEMO_DATA=false` for production installs.

## Upgrade

```bash
docker compose --env-file .env pull
docker compose --env-file .env up -d
```

Migrations run automatically before the API starts.

## CPA Assistant

The conversational assistant uses local Ollama by default. Start the updated stack, then download the configured model once:

```bash
docker compose --env-file .env up -d ollama
docker compose --env-file .env exec ollama ollama pull llama3.2:1b
docker compose --env-file .env up -d api dashboard
```

Choose another local model with `OLLAMA_MODEL`. Ollama answers do not include live IRS retrieval, so the UI labels them as unsourced local explanations.

To use OpenAI with live web search restricted to IRS and USA.gov instead, set:

```env
ADVISOR_PROVIDER=openai
OPENAI_API_KEY=your-project-api-key
OPENAI_MODEL=gpt-5.5
```

The key is provided only to the API container. The dashboard never receives it. Both providers receive aggregate record totals rather than raw statements or transaction descriptions. OpenAI mode disables response storage and limits tax-source search to IRS and USA.gov pages.
