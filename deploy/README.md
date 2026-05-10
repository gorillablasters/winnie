# Winnie Closed-Source Deployment

This folder is the customer-facing deployment bundle. It pulls prebuilt Winnie images
from a private registry and does not require the source repository.

## Files to Deliver

- `docker-compose.yml`
- `.env.example`

The customer copies `.env.example` to `.env`, fills in passwords and image names,
then starts the stack.

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
