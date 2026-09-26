# Cozforge 2.0 — Deploy to Cloud Run

This repo holds the shared CI/CD pipeline. You don't need any GCP access — everything runs through this one reusable workflow, keyed off your GitHub push. Build/deploy logs show up in **your own repo's Actions tab**.

## What you need to do (once)

1. **Add a `Dockerfile`** to your repo root. Pick the closest match from [`templates/`](./templates) and adjust the entrypoint/build paths for your app:
   - `Dockerfile.python-django` — Django + Gunicorn
   - `Dockerfile.python-fastapi` — FastAPI/ASGI
   - `Dockerfile.angular` — Angular (needs `templates/nginx.conf` alongside it)
   - `Dockerfile.react` — React/Vite (needs `templates/nginx.conf` alongside it)
   - `Dockerfile.dotnet` — ASP.NET Core

   Your app **must listen on `$PORT`** (Cloud Run sets this, default `8080`) — the templates already do this.

2. **Add this file** to your repo at `.github/workflows/deploy.yml`, using **your** service name from the table below:

   ```yaml
   name: Deploy

   on:
     push:
       branches: [main]
     workflow_dispatch: {}

   jobs:
     deploy:
       uses: Cozentus-Technologies/hackathon-deploy/.github/workflows/deploy-cloud-run.yml@main
       with:
         service_name: <YOUR SERVICE NAME FROM THE TABLE BELOW>
   ```

3. **Push to `main`.** That's it — no secrets to configure, no GCP login. The Actions tab in your repo shows the build/deploy logs.

## Your service name and URL

| Repo | `service_name` | URL after first deploy |
|---|---|---|
| eternal_host_ui | `eternal-host-ui` | https://eternalhost.cozentus.com |
| eternal_host_be | `eternal-host-be` | https://eternalhostapi.cozentus.com |
| codesmash-frontend | `codesmash-frontend` | https://codesmash.cozentus.com |
| codesmash-api | `codesmash-api` | https://codesmashapi.cozentus.com |
| hack-ims-frontend | `hack-ims-frontend` | https://dotnetcommando.cozentus.com |
| hack-ims-backend | `hack-ims-backend` | https://dotnetcommandoapi.cozentus.com |
| bitstorm-ui | `bitstorm-ui` | https://bitstorm.cozentus.com |
| bitstorm-api | `bitstorm-api` | https://bitstormapi.cozentus.com |
| kinetix-api-service | `kinetix-api-service` | https://kinetixapi.cozentus.com |
| kinetix-ui-service | `kinetix-ui-service` | https://kinetix.cozentus.com |
| ai-mavericks-ui | `ai-mavericks-ui` | https://aimavericks.cozentus.com |
| ai-mavericks-api | `ai-mavericks-api` | https://aimavericksapi.cozentus.com |
| patronus-global-help-desk | `patronus-global-help-desk` | https://patronus.cozentus.com |
| patronus-ai-support-investigator | `patronus-ai-support-investigator` | https://patronusapi.cozentus.com |
| patronus-target-application | `patronus-target-application` | https://patronus-target.cozentus.com |
| team-tesseract-backend | `team-tesseract-backend` | https://teamtesseractapi.cozentus.com |
| team-tesseract-ui | `team-tesseract-ui` | https://teamtesseract.cozentus.com |
| colorsweep-BE | `colorsweep-be` | https://colorsweepapi.cozentus.com |
| colorsweep-UI | `colorsweep-ui` | https://colorsweep.cozentus.com |

Until GoDaddy DNS is configured (DevOps handles this), your app is still reachable at the direct `*.run.app` URL shown in your deploy's Action log.

## Secrets (API keys, DB credentials, etc.)

You don't have GCP access, so you can't create these yourself. Tell DevOps what you need (env var name + value, sent privately, not in a group chat) and we'll create it in Secret Manager and wire it into your service. It shows up as a normal environment variable in your app — nothing to change in your code.

Once created, secrets and plain (non-secret) env vars are wired in via your caller workflow:

```yaml
jobs:
  deploy:
    uses: Cozentus-Technologies/hackathon-deploy/.github/workflows/deploy-cloud-run.yml@main
    with:
      service_name: your-service-name
      secrets_mapping: "DB_URL=your-service-db-url:latest,DB_PASSWORD=your-service-db-password:latest"
      env_vars: "SOME_CONFIG=some-value"
```

## Database on a private network? (jump host / SSH tunnel)

If your team's DB isn't directly reachable from the internet (common if it's hosted on internal infra rather than Cloud SQL), we've set up a shared pattern rather than solving this per-team: your container opens an SSH tunnel to a jump host at startup, forwards the DB port to `127.0.0.1` inside the container, and your app connects to that local address like normal.

1. Tell DevOps your DB's private host/port (as reached from the jump host) and your credentials.
2. We create your `*-db-url` / `*-db-user` / `*-db-password` secrets (`DB_URL` should point at `127.0.0.1:<local-port>`, not the real private host).
3. Add [`templates/db-tunnel-entrypoint.sh`](./templates/db-tunnel-entrypoint.sh) to your repo, install `openssh-client` + `netcat` in your final image stage, and set it as your `ENTRYPOINT` (see the script's header comment for the required env vars, and `kinetix-api-service`'s PR for a worked example).
4. Add `/secrets/db_tunnel_key=db-jump-host-ssh-key:latest` to your `secrets_mapping` (the shared jump-host key -- ask DevOps, don't generate your own).

Note: this currently runs the container as root (simplest way to reliably read the mounted SSH key) -- fine for now, worth hardening later.

## eternal-host-worker (Celery background worker)

This is already provisioned as a dedicated **always-on** Cloud Run service (`eternal-host-worker`) — it does not scale to zero and is not reachable from the internet, it just keeps running your Celery worker process. To deploy it:

1. Add a second Dockerfile to `eternal_host_be`, e.g. `Dockerfile.worker`, with `CMD` running `celery -A myproject worker` instead of gunicorn (no `$PORT`/web server needed here).
2. Add a second caller workflow, e.g. `.github/workflows/deploy-worker.yml`:
   ```yaml
   name: Deploy Worker
   on:
     push:
       branches: [main]
     workflow_dispatch: {}
   jobs:
     deploy:
       uses: Cozentus-Technologies/hackathon-deploy/.github/workflows/deploy-cloud-run.yml@main
       with:
         service_name: eternal-host-worker
         dockerfile: Dockerfile.worker
   ```

## Notes

- Cold starts happen after idle periods (web services scale to zero) — the first request after a quiet spell takes a couple seconds longer.
- Database connectivity: DevOps is handling this separately — ping us once your app needs specific ports opened.
